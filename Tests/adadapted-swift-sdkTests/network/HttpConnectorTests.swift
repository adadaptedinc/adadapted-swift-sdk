//
//  Created by Brett Clifton on 6/18/26.
//

import XCTest
@testable import adadapted_swift_sdk

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    static var requestCount = 0

    static func reset() {
        requestHandler = nil
        requestCount = 0
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        MockURLProtocol.requestCount += 1
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class HttpConnectorTests: XCTestCase {

    private static func makeMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
        HttpConnector.session = Self.makeMockSession()
    }

    override func tearDown() {
        HttpConnector.session = .shared
        super.tearDown()
    }

    // MARK: - async data(for:) tests

    func testSuccessfulRequestDoesNotRetry() async throws {
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://test.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("{\"ok\":true}".utf8))
        }

        let request = URLRequest(url: URL(string: "https://test.com")!)
        let (data, response) = try await HttpConnector.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        XCTAssertEqual(httpResponse.statusCode, 200)
        XCTAssertFalse(data.isEmpty)
        XCTAssertEqual(MockURLProtocol.requestCount, 1)
    }

    func testRetriesOnServerErrorThenSucceeds() async throws {
        var attempt = 0
        MockURLProtocol.requestHandler = { _ in
            attempt += 1
            if attempt < 3 {
                return (HTTPURLResponse(
                    url: URL(string: "https://test.com")!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: nil
                )!, Data())
            }
            return (HTTPURLResponse(
                url: URL(string: "https://test.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!, Data("{\"ok\":true}".utf8))
        }

        let request = URLRequest(url: URL(string: "https://test.com")!)
        let (_, response) = try await HttpConnector.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        XCTAssertEqual(httpResponse.statusCode, 200)
        XCTAssertEqual(attempt, 3)
    }

    func testThrowsAfterMaxRetriesOnPersistentServerError() async {
        MockURLProtocol.requestHandler = { _ in
            return (HTTPURLResponse(
                url: URL(string: "https://test.com")!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!, Data())
        }

        let request = URLRequest(url: URL(string: "https://test.com")!)

        do {
            _ = try await HttpConnector.data(for: request)
            XCTFail("Expected error after max retries")
        } catch {
            XCTAssertEqual(MockURLProtocol.requestCount, 3)
        }
    }

    func testRetriesOnNetworkErrorThenSucceeds() async throws {
        var attempt = 0
        MockURLProtocol.requestHandler = { _ in
            attempt += 1
            if attempt < 3 {
                throw URLError(.networkConnectionLost)
            }
            return (HTTPURLResponse(
                url: URL(string: "https://test.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!, Data("{\"ok\":true}".utf8))
        }

        let request = URLRequest(url: URL(string: "https://test.com")!)
        let (_, response) = try await HttpConnector.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        XCTAssertEqual(httpResponse.statusCode, 200)
        XCTAssertEqual(attempt, 3)
    }

    // MARK: - callback dataTask tests

    func testDataTaskRetriesOnServerErrorThenSucceeds() {
        var attempt = 0
        MockURLProtocol.requestHandler = { _ in
            attempt += 1
            if attempt < 3 {
                return (HTTPURLResponse(
                    url: URL(string: "https://test.com")!,
                    statusCode: 502,
                    httpVersion: nil,
                    headerFields: nil
                )!, Data())
            }
            return (HTTPURLResponse(
                url: URL(string: "https://test.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!, Data("{\"ok\":true}".utf8))
        }

        let expectation = XCTestExpectation(description: "dataTask completes")
        let request = URLRequest(url: URL(string: "https://test.com")!)

        HttpConnector.dataTask(with: request) { _, response, error in
            let httpResponse = response as? HTTPURLResponse
            XCTAssertEqual(httpResponse?.statusCode, 200)
            XCTAssertNil(error)
            XCTAssertEqual(attempt, 3)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15)
    }

    func testDataTaskCompletesAfterMaxRetriesOnPersistentError() {
        MockURLProtocol.requestHandler = { _ in
            return (HTTPURLResponse(
                url: URL(string: "https://test.com")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!, Data())
        }

        let expectation = XCTestExpectation(description: "dataTask completes")
        let request = URLRequest(url: URL(string: "https://test.com")!)

        HttpConnector.dataTask(with: request) { _, response, _ in
            let httpResponse = response as? HTTPURLResponse
            XCTAssertEqual(httpResponse?.statusCode, 500)
            XCTAssertEqual(MockURLProtocol.requestCount, 3)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 15)
    }
}
