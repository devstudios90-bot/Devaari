import Foundation
import UIKit
import WebKit

struct Bookmark: Identifiable, Codable {
    var id: UUID = UUID()
    let title: String
    let url: String
}

struct HistoryItem: Identifiable, Codable {
    var id: UUID = UUID()
    let title: String
    let url: String
    let timestamp: Date
}

struct DownloadedItem: Identifiable, Codable {
    var id: UUID = UUID()
    let filename: String
    let fileURL: URL
    let downloadDate: Date
    let fileSize: Int64
    let isVideo: Bool
}

class BrowserTab: ObservableObject, Identifiable {
    let id: UUID = UUID()
    @Published var url: URL?
    @Published var title: String = "New Tab"
    @Published var isLoading: Bool = false
    @Published var estimatedProgress: Double = 0.0
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isFlowSite: Bool = false
    
    var webView: WKWebView!
    
    init(url: URL? = URL(string: "https://flow.google.com")) {
        self.url = url
    }
}
