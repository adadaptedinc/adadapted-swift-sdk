//
//  Created by Brett Clifton on 5/22/26.
//

import Foundation

class HttpConnector {
    private static let maxRetries = 3
    private static let initialDelaySeconds: TimeInterval = 1.0
    static var session: URLSession = .shared

    private init() {}

    static func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        var lastError: Error = URLError(.unknown)
        for attempt in 0..<maxRetries {
            if attempt > 0 {
                let delay = initialDelaySeconds * pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            do {
                let (data, response) = try await session.data(for: request)
                if let httpResponse = response as? HTTPURLResponse,
                   (500...599).contains(httpResponse.statusCode) {
                    lastError = URLError(.badServerResponse)
                    continue
                }
                return (data, response)
            } catch {
                lastError = error
                continue
            }
        }
        throw lastError
    }

    static func dataTask(with request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        performWithRetry(request: request, attempt: 0, completion: completion)
    }

    private static func performWithRetry(request: URLRequest, attempt: Int, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        session.dataTask(with: request) { data, response, error in
            if error != nil, attempt < maxRetries - 1 {
                let delay = initialDelaySeconds * pow(2.0, Double(attempt))
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    performWithRetry(request: request, attempt: attempt + 1, completion: completion)
                }
                return
            }
            if let httpResponse = response as? HTTPURLResponse,
               (500...599).contains(httpResponse.statusCode),
               attempt < maxRetries - 1 {
                let delay = initialDelaySeconds * pow(2.0, Double(attempt))
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    performWithRetry(request: request, attempt: attempt + 1, completion: completion)
                }
                return
            }
            completion(data, response, error)
        }.resume()
    }
}
