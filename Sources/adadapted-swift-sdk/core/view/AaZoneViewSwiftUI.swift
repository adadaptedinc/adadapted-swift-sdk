import SwiftUI
import WebKit

// MARK: - View Model

class SwiftZoneViewModel: ObservableObject, AdZonePresenterListener, AdWebViewListener {
    // MARK: - Properties
    private let adContentListener: AdContentListener
    private let zoneViewListener: ZoneViewListener
    private let presenter: AdZonePresenter
    @Published var currentAd: Ad?
    @Published var webViewLoaded = false
    @Binding var isZoneVisible: Bool
    @Binding var zoneContextId: String
    var isStopped = false

    // MARK: - Initializer
    init(zoneId: String, adContentListener: AdContentListener, zoneViewListener: ZoneViewListener, isZoneVisible: Binding<Bool>, zoneContextId: Binding<String>) {
        self.presenter = AdZonePresenter(adViewHandler: AdViewHandler(), sessionClient: SessionClient.getInstance())
        self.adContentListener = adContentListener
        self.zoneViewListener = zoneViewListener
        self._isZoneVisible = isZoneVisible
        self._zoneContextId = zoneContextId

        initializePresenter(with: zoneId)
    }
    
    // MARK: - Deinitializer
    deinit { onStop() }

    // MARK: - Initialization Helper
    private func initializePresenter(with zoneId: String) {
        presenter.inititialize(zoneId: zoneId)
        AdContentPublisher.getInstance().addListener(listener: adContentListener)
        
        if !$zoneContextId.wrappedValue.isEmpty {
            setAdZoneContextId(contextId: $zoneContextId.wrappedValue)
        }
        if $isZoneVisible.wrappedValue {
            onStart()
        }
    }

    // MARK: - Zone Visibility & Context Management
    func setAdZoneVisibility(isViewable: Bool) {
        if !webViewLoaded {
            onStart()
            webViewLoaded = true
        }
        presenter.onAdVisibilityChanged(isAdVisible: isViewable)
    }

    func setAdZoneContextId(contextId: String) {
        contextId.isEmpty ? presenter.removeZoneContext() : presenter.setZoneContext(contextId: contextId)
    }
    
    // MARK: - Start & Stop Handling
    func onStart() {
        isStopped = false
        presenter.onAttach(adZonePresenterListener: self)
    }

    func onStop() {
        isStopped = true
        AdContentPublisher.getInstance().removeListener(listener: adContentListener)
        presenter.onDetach()
    }

    // MARK: - Ad Loading & Interaction
    func onAdLoadedInWebView(ad: inout Ad) {
        presenter.onAdDisplayed(ad: &ad, isAdVisible: isZoneVisible)
    }
    
    func onAdLoadInWebViewFailed() {
        presenter.onAdDisplayFailed()
        notifyClientAdLoadFailed()
    }
    
    func onAdInWebViewClicked(ad: Ad) {
        presenter.onAdClicked(ad: ad)
    }
    func onBlankAdInWebViewLoaded() {
        presenter.onBlankDisplayed()
    }

    // MARK: - Client Notifications
    private func notifyClientZoneHasAds(hasAds: Bool) {
        zoneViewListener.onZoneHasAds(hasAds: hasAds)
    }
    private func notifyClientAdLoadFailed() {
        zoneViewListener.onAdLoadFailed()
    }

    // MARK: - AdZonePresenterListener Protocol Methods
    func onZoneAvailable(zone: Zone) {
        notifyClientZoneHasAds(hasAds: zone.hasAds())
    }
    func onAdsRefreshed(zone: Zone) {
        notifyClientZoneHasAds(hasAds: zone.hasAds())
    }
    func onAdAvailable(ad: Ad) {
        DispatchQueue.main.async { [weak self] in
            self?.currentAd = ad
        }
    }
    func onNoAdAvailable() {
        currentAd = nil
    }
    func onAdVisibilityChanged(ad: Ad) {}
    
    // MARK: - Reporting Ads
    func reportButtonTapped() {
        if let udid = DeviceInfoClient.getCachedDeviceInfo()?.udid {
            presenter.onReportAdClicked(adId: currentAd?.id ?? "", udid: udid)
        }
    }
}

// MARK: - SwiftUI View

@available(iOS 14.0, *)
public struct AaZoneViewSwiftUI: View {
    // MARK: - Properties
    @Binding var isZoneVisible: Bool
    @Binding var zoneContextId: String
    @StateObject private var viewModel: SwiftZoneViewModel

    // MARK: - Initializer
    public init(zoneId: String, zoneListener: ZoneViewListener, contentListener: AdContentListener, isZoneVisible: Binding<Bool> = .constant(true), zoneContextId: Binding<String> = .constant("")) {
        self._isZoneVisible = isZoneVisible
        self._zoneContextId = zoneContextId
        _viewModel = StateObject(wrappedValue: SwiftZoneViewModel(zoneId: zoneId, adContentListener: contentListener, zoneViewListener: zoneListener, isZoneVisible: isZoneVisible, zoneContextId: zoneContextId))
    }
    
    // MARK: - Body
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            AdWebViewRepresentable(currentAd: $viewModel.currentAd, adWebViewListener: viewModel, isStopped: $viewModel.isStopped)
            ReportButton(action: viewModel.reportButtonTapped).opacity(viewModel.currentAd != nil ? 1 : 0)
        }
        .onChange(of: isZoneVisible) {
            viewModel.setAdZoneVisibility(isViewable: $0)
        }
        .onChange(of: zoneContextId) {
            viewModel.setAdZoneContextId(contextId: $0)
        }
        .onDisappear {
            viewModel.onStop()
        }
    }
}

// MARK: - WebView Representable

struct AdWebViewRepresentable: UIViewRepresentable {
    @Binding var currentAd: Ad?
    var adWebViewListener: AdWebViewListener?
    @Binding var isStopped: Bool

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear

        // Setup tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        tapGesture.delegate = context.coordinator
        webView.addGestureRecognizer(tapGesture)
        webView.isUserInteractionEnabled = true
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let ad = currentAd, let url = URL(string: ad.url) {
            uiView.load(URLRequest(url: url))
        } else {
            uiView.loadHTMLString("<html><body></body></html>", baseURL: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, listener: adWebViewListener, isStopped: $isStopped)
    }

    class Coordinator: NSObject, WKNavigationDelegate, UIGestureRecognizerDelegate {
        var parent: AdWebViewRepresentable
        var listener: AdWebViewListener?
        @Binding var isStopped: Bool

        init(_ parent: AdWebViewRepresentable, listener: AdWebViewListener?, isStopped: Binding<Bool>) {
            self.parent = parent
            self.listener = listener
            self._isStopped = isStopped
        }

        @objc func handleTap() {
            if let ad = parent.currentAd, !ad.id.isEmpty {
                listener?.onAdInWebViewClicked(ad: ad)
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !isStopped, var ad = parent.currentAd, !ad.id.isEmpty else { return }
            listener?.onAdLoadedInWebView(ad: &ad)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            listener?.onAdLoadInWebViewFailed()
        }
    }
}

// MARK: - Report Button

struct ReportButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if let image = UIImage(named: "reportAdImage", in: Bundle.module, compatibleWith: nil) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
                    .padding(5)
                    .background(Color.clear)
                    .clipShape(Circle())
            }
        }
        .frame(width: 20, height: 20)
        .contentShape(Rectangle())
    }
}
