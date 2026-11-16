import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    @ObservedObject var tab: BrowserTab
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = tab.webView ?? WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        context.coordinator.setupObservers(for: webView)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Managed internally
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebViewContainer
        private var progressObservation: NSKeyValueObservation?
        private var titleObservation: NSKeyValueObservation?
        private var urlObservation: NSKeyValueObservation?
        private var backObservation: NSKeyValueObservation?
        private var forwardObservation: NSKeyValueObservation?
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }
        
        func setupObservers(for webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.parent.tab.estimatedProgress = webView.estimatedProgress
                }
            }
            
            titleObservation = webView.observe(\.title, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.parent.tab.title = webView.title ?? "New Tab"
                }
            }
            
            urlObservation = webView.observe(\.url, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.parent.tab.url = webView.url
                    let host = webView.url?.host?.lowercased() ?? ""
                    self?.parent.tab.isFlowSite = host.contains("flow.google.com") || host.contains("labs.google")
                }
            }
            
            backObservation = webView.observe(\.canGoBack, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.parent.tab.canGoBack = webView.canGoBack
                }
            }
            
            forwardObservation = webView.observe(\.canGoForward, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.parent.tab.canGoForward = webView.canGoForward
                }
            }
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.tab.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.tab.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.tab.isLoading = false
            }
        }
        
        // Handle target="_blank" links opening in new tab or current tab
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}
