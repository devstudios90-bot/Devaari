import SwiftUI

struct AddressBarView: View {
    @EnvironmentObject var browserManager: BrowserManager
    @State private var urlInputText: String = ""
    @State private var isEditingURL: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // Navigation Controls (Back / Forward / Reload)
                HStack(spacing: 4) {
                    Button(action: {
                        browserManager.goBackActiveTab()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(browserManager.activeTab?.canGoBack == true ? .primary : .secondary.opacity(0.4))
                            .frame(width: 32, height: 32)
                    }
                    .disabled(browserManager.activeTab?.canGoBack != true)
                    
                    Button(action: {
                        browserManager.goForwardActiveTab()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(browserManager.activeTab?.canGoForward == true ? .primary : .secondary.opacity(0.4))
                            .frame(width: 32, height: 32)
                    }
                    .disabled(browserManager.activeTab?.canGoForward != true)
                    
                    Button(action: {
                        if browserManager.activeTab?.isLoading == true {
                            browserManager.activeTab?.webView.stopLoading()
                        } else {
                            browserManager.reloadActiveTab()
                        }
                    }) {
                        Image(systemName: browserManager.activeTab?.isLoading == true ? "xmark" : "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                    }
                }
                
                // Address Bar / Omnibox
                HStack(spacing: 8) {
                    Image(systemName: browserManager.activeTab?.url?.scheme == "https" ? "lock.fill" : "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundColor(browserManager.activeTab?.url?.scheme == "https" ? .green : .secondary)
                        .padding(.leading, 8)
                    
                    TextField("Search or enter website name", text: $urlInputText, onEditingChanged: { editing in
                        isEditingURL = editing
                        if editing, let current = browserManager.activeTab?.url?.absoluteString {
                            urlInputText = current
                        }
                    }, onCommit: {
                        browserManager.navigateActiveTab(to: urlInputText)
                        isEditingURL = false
                    })
                    .font(.system(size: 14))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    
                    if !urlInputText.isEmpty && isEditingURL {
                        Button(action: {
                            urlInputText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.trailing, 6)
                    }
                    
                    // Bookmark Quick Star
                    Button(action: {
                        if let tab = browserManager.activeTab, let url = tab.url {
                            browserManager.addBookmark(title: tab.title, url: url.absoluteString)
                        }
                    }) {
                        Image(systemName: "star")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 6)
                }
                .padding(.vertical, 7)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                
                // Action Buttons: Bookmarks, Downloads, Flow Automator
                HStack(spacing: 6) {
                    // Bookmarks
                    Button(action: {
                        browserManager.isShowingBookmarksSheet = true
                    }) {
                        Image(systemName: "book")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .frame(width: 34, height: 34)
                    }
                    
                    // Downloads
                    Button(action: {
                        browserManager.isShowingDownloadsSheet = true
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .frame(width: 34, height: 34)
                            
                            if !browserManager.downloads.isEmpty {
                                Text("\(browserManager.downloads.count)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(3)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .offset(x: -2, y: 2)
                            }
                        }
                    }
                    
                    // Flow Automator Toggle Button
                    Button(action: {
                        browserManager.toggleSidePanel()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                            Text("Automator")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            browserManager.isSidePanelOpen
                                ? AnyView(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                                : AnyView(Color(UIColor.systemGray5))
                        )
                        .foregroundColor(browserManager.isSidePanelOpen ? .white : .primary)
                        .cornerRadius(9)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(UIColor.systemBackground))
            
            // Progress Bar
            if let tab = browserManager.activeTab, tab.isLoading && tab.estimatedProgress < 1.0 {
                ProgressView(value: tab.estimatedProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 2)
            } else {
                Divider()
            }
        }
        .onReceive(browserManager.$activeTabId) { _ in
            if !isEditingURL, let tab = browserManager.activeTab, let url = tab.url {
                urlInputText = url.absoluteString
            }
        }
    }
}
