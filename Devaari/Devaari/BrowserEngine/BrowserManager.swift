import Foundation
import SwiftUI
import WebKit
import Combine

class BrowserManager: ObservableObject {
    @Published var tabs: [BrowserTab] = []
    @Published var activeTabId: UUID?
    @Published var isSidePanelOpen: Bool = true
    @Published var sidePanelWidth: CGFloat = 430
    @Published var bookmarks: [Bookmark] = []
    @Published var history: [HistoryItem] = []
    @Published var downloads: [DownloadedItem] = []
    @Published var isShowingBookmarksSheet: Bool = false
    @Published var isShowingDownloadsSheet: Bool = false
    @Published var isShowingHistorySheet: Bool = false
    
    var extensionBridge: ExtensionBridge!
    
    var activeTab: BrowserTab? {
        tabs.first(where: { $0.id == activeTabId })
    }
    
    init() {
        self.extensionBridge = ExtensionBridge(browserManager: self)
        loadSavedData()
        
        // Open initial tab to Google Flow
        createNewTab(url: URL(string: "https://flow.google.com"))
    }
    
    func createNewTab(url: URL? = URL(string: "https://flow.google.com")) {
        let tab = BrowserTab(url: url)
        
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.websiteDataStore = WKWebsiteDataStore.default()
        
        // Inject TryAIToday Flow Automator scripts into the webpage
        ScriptInjector.shared.configureUserContentController(config.userContentController)
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        tab.webView = webView
        
        tabs.append(tab)
        activeTabId = tab.id
        
        if let targetURL = url {
            webView.load(URLRequest(url: targetURL))
        }
    }
    
    func closeTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        
        tabs[index].webView.stopLoading()
        tabs.remove(at: index)
        
        if tabs.isEmpty {
            createNewTab(url: URL(string: "https://flow.google.com"))
        } else if activeTabId == id {
            let nextIndex = min(index, tabs.count - 1)
            activeTabId = tabs[nextIndex].id
        }
    }
    
    func selectTab(id: UUID) {
        activeTabId = id
    }
    
    func navigateActiveTab(to input: String) {
        guard let tab = activeTab else { return }
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let targetURL: URL
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            targetURL = URL(string: trimmed) ?? URL(string: "https://www.google.com/search?q=\(trimmed)")!
        } else if trimmed.contains(".") && !trimmed.contains(" ") {
            targetURL = URL(string: "https://\(trimmed)") ?? URL(string: "https://www.google.com/search?q=\(trimmed)")!
        } else {
            let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            targetURL = URL(string: "https://www.google.com/search?q=\(encoded)")!
        }
        
        tab.webView.load(URLRequest(url: targetURL))
        addToHistory(title: tab.title, url: targetURL.absoluteString)
    }
    
    func reloadActiveTab() {
        activeTab?.webView.reload()
    }
    
    func goBackActiveTab() {
        activeTab?.webView.goBack()
    }
    
    func goForwardActiveTab() {
        activeTab?.webView.goForward()
    }
    
    func toggleSidePanel() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isSidePanelOpen.toggle()
        }
    }
    
    func addBookmark(title: String, url: String) {
        let b = Bookmark(title: title, url: url)
        bookmarks.append(b)
        saveBookmarks()
    }
    
    func removeBookmark(id: UUID) {
        bookmarks.removeAll(where: { $0.id == id })
        saveBookmarks()
    }
    
    private func addToHistory(title: String, url: String) {
        let item = HistoryItem(title: title.isEmpty ? url : title, url: url, timestamp: Date())
        history.insert(item, at: 0)
        if history.count > 200 {
            history.removeLast()
        }
        saveHistory()
    }
    
    private func saveBookmarks() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: "devaari_bookmarks")
        }
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "devaari_history")
        }
    }
    
    private func loadSavedData() {
        if let data = UserDefaults.standard.data(forKey: "devaari_bookmarks"),
           let saved = try? JSONDecoder().decode([Bookmark].self, from: data) {
            self.bookmarks = saved
        } else {
            // Default quick bookmarks
            self.bookmarks = [
                Bookmark(title: "Google Flow", url: "https://flow.google.com"),
                Bookmark(title: "Google Labs", url: "https://labs.google"),
                Bookmark(title: "Google", url: "https://www.google.com")
            ]
        }
        
        if let data = UserDefaults.standard.data(forKey: "devaari_history"),
           let saved = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            self.history = saved
        }
    }
}
