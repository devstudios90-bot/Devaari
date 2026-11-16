import SwiftUI
import WebKit

struct SidePanelView: View {
    @EnvironmentObject var browserManager: BrowserManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Side Panel Header
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .bold))
                    
                    Text("Flow Automator")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Flow Connection Status Pill
                if let tab = browserManager.activeTab, tab.isFlowSite {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Ready")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12))
                    .cornerRadius(12)
                } else {
                    Button(action: {
                        browserManager.navigateActiveTab(to: "https://flow.google.com")
                    }) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                            Text("Open Flow")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(12)
                    }
                }
                
                // Refresh Button
                Button(action: {
                    browserManager.extensionBridge.sidePanelWebView?.reload()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color(UIColor.systemGray5))
                        .clipShape(Circle())
                }
                
                // Close / Collapse Button
                Button(action: {
                    browserManager.toggleSidePanel()
                }) {
                    Image(systemName: "sidebar.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color(UIColor.systemGray5))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemBackground))
            
            Divider()
            
            // SidePanel HTML Web View Container
            SidePanelWebViewRepresentable(browserManager: browserManager)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: -3, y: 0)
    }
}

struct SidePanelWebViewRepresentable: UIViewRepresentable {
    @ObservedObject var browserManager: BrowserManager
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Register Native Devaari Bridge cleanly
        config.userContentController.removeScriptMessageHandler(forName: "devaariBridge")
        config.userContentController.add(browserManager.extensionBridge, name: "devaariBridge")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        browserManager.extensionBridge.sidePanelWebView = webView
        
        loadSidePanelHTML(into: webView)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Kept alive
    }
    
    private func loadSidePanelHTML(into webView: WKWebView) {
        let bundleURL = Bundle.main.bundleURL
        let assetsDir = bundleURL.appendingPathComponent("ExtensionAssets")
        let htmlURL = assetsDir.appendingPathComponent("sidepanel.html")
        
        if FileManager.default.fileExists(atPath: htmlURL.path) {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: assetsDir)
        } else if let fallbackHTML = Bundle.main.url(forResource: "sidepanel", withExtension: "html") {
            let parentDir = fallbackHTML.deletingLastPathComponent()
            webView.loadFileURL(fallbackHTML, allowingReadAccessTo: parentDir)
        } else {
            let errorHTML = """
            <!DOCTYPE html>
            <html>
            <head><meta name="viewport" content="width=device-width, initial-scale=1"></head>
            <body style="font-family: -apple-system; padding: 24px; color: #fff; background: #121212; text-align: center;">
                <h3>TryAIToday Flow Automator</h3>
                <p>Loading extension assets...</p>
            </body>
            </html>
            """
            webView.loadHTMLString(errorHTML, baseURL: nil)
        }
    }
}
