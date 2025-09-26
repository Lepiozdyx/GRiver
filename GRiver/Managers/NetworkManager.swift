import UIKit
import SwiftUI
import Combine
@preconcurrency import WebKit

class NetworkManager: ObservableObject {
    @Published private(set) var gameURL: URL?
    
    static let initialURL = URL(string: "https://griverclube.com/data")!
    private let storage: UserDefaults
    private var didSaveURL = false
    private let requestTimeout: TimeInterval = 10.0
    
    init(storage: UserDefaults = .standard) {
        self.storage = storage
        loadGameURL()
    }
    
    func checkURL(_ url: URL) {
        if didSaveURL {
            return
        }
        
        guard !isInvalidURL(url) else {
            return
        }
        
        storage.set(url.absoluteString, forKey: "savedurl")
        gameURL = url
        didSaveURL = true
    }
    
    private func loadGameURL() {
        if let urlString = storage.string(forKey: "savedurl") {
            if let url = URL(string: urlString) {
                gameURL = url
                didSaveURL = true
            } else {
                print("Error: \(urlString)")
            }
        }
    }
    
    private func isInvalidURL(_ url: URL) -> Bool {
        let invalidURLs = ["about:blank", "about:srcdoc"]
        
        if invalidURLs.contains(url.absoluteString) {
            return true
        }
        
        return false
    }
    
    func checkInitialURL() async throws -> Bool {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = requestTimeout
        configuration.timeoutIntervalForResource = requestTimeout
        let session = URLSession(configuration: configuration)
        
        var request = URLRequest(url: Self.initialURL)
        request.setValue(getUAgent(forWebView: false), forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = requestTimeout
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            
            if (400...599).contains(httpResponse.statusCode) {
                return false
            }
            
            return true
            
        } catch {
            throw error
        }
    }
    
    func getUAgent(forWebView: Bool = false) -> String {
        if forWebView {
            let version = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
            let agent = "Mozilla/5.0 (iPhone; CPU iPhone OS \(version) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
            return agent
        } else {
            let agent = "TestRequest/1.0 CFNetwork/1410.0.3 Darwin/22.4.0"
            return agent
        }
    }
}

struct WKWebViewManager: UIViewRepresentable {
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WKWebViewManager
        
        init(_ parent: WKWebViewManager) {
            self.parent = parent
            super.init()
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let finalURL = webView.url else {
                return
            }
            
            if finalURL != NetworkManager.initialURL {
                parent.webManager.checkURL(finalURL)
            } else {}
        }
    }
    
    let url: URL
    let webManager: NetworkManager
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.bounces = true
        webView.customUserAgent = webManager.getUAgent(forWebView: true)
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
