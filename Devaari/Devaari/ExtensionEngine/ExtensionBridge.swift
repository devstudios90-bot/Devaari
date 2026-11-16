import Foundation
import WebKit
import Photos
import AuthenticationServices

class ExtensionBridge: NSObject, WKScriptMessageHandler {
    weak var browserManager: BrowserManager?
    weak var sidePanelWebView: WKWebView?
    
    private var downloadCounter = 1000
    
    init(browserManager: BrowserManager?) {
        self.browserManager = browserManager
        super.init()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "devaariBridge",
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else {
            return
        }
        
        let callId = body["callId"] as? Int
        
        switch type {
        case "TABS_QUERY":
            handleTabsQuery(callId: callId)
            
        case "EXECUTE_SCRIPT":
            if let script = body["script"] as? String {
                handleExecuteScript(script: script, callId: callId)
            } else {
                sendError(callId: callId, error: "Missing script payload")
            }
            
        case "DOWNLOAD_FILE":
            if let options = body["options"] as? [String: Any] {
                handleDownload(options: options, callId: callId)
            } else {
                sendError(callId: callId, error: "Missing download options")
            }
            
        case "STORAGE_SET":
            if let items = body["items"] as? [String: Any] {
                for (key, value) in items {
                    UserDefaults.standard.set(value, forKey: "devaari_ext_" + key)
                }
            }
            sendResult(callId: callId, result: true)
            
        case "STORAGE_REMOVE":
            if let keys = body["keys"] as? [String] {
                for key in keys {
                    UserDefaults.standard.removeObject(forKey: "devaari_ext_" + key)
                }
            }
            sendResult(callId: callId, result: true)
            
        case "LAUNCH_AUTH_FLOW":
            if let urlString = body["url"] as? String, let url = URL(string: urlString) {
                handleOAuthFlow(url: url, callId: callId)
            } else {
                sendError(callId: callId, error: "Invalid auth URL")
            }
            
        default:
            sendResult(callId: callId, result: nil)
        }
    }
    
    private func handleTabsQuery(callId: Int?) {
        guard let manager = browserManager, let activeTab = manager.activeTab else {
            let fallback: [String: Any] = [
                "id": 1,
                "url": "https://flow.google.com",
                "title": "Google Flow",
                "active": true
            ]
            sendResult(callId: callId, result: fallback)
            return
        }
        
        let tabInfo: [String: Any] = [
            "id": 1,
            "url": activeTab.url?.absoluteString ?? "https://flow.google.com",
            "title": activeTab.title,
            "active": true
        ]
        sendResult(callId: callId, result: tabInfo)
    }
    
    private func handleExecuteScript(script: String, callId: Int?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let activeTab = self.browserManager?.activeTab,
                  let webView = activeTab.webView else {
                self?.sendError(callId: callId, error: "No active browser tab found")
                return
            }
            
            webView.evaluateJavaScript(script, in: nil, in: .page) { evalResult in
                switch evalResult {
                case .success(let val):
                    self.sendResult(callId: callId, result: val)
                case .failure(let error):
                    self.sendError(callId: callId, error: error.localizedDescription)
                }
            }
        }
    }
    
    private func handleDownload(options: [String: Any], callId: Int?) {
        guard let urlString = options["url"] as? String, let url = URL(string: urlString) else {
            sendError(callId: callId, error: "Invalid download URL")
            return
        }
        
        let filename = (options["filename"] as? String) ?? "download_\(Int(Date().timeIntervalSince1970))"
        let downloadId = downloadCounter
        downloadCounter += 1
        
        // Return downloadId to caller immediately like Chrome downloads.download does
        sendResult(callId: callId, result: downloadId)
        
        // Create downloads folder in app documents
        let fileManager = FileManager.default
        guard let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let downloadsDir = docsURL.appendingPathComponent("DevaariDownloads", isDirectory: true)
        try? fileManager.createDirectory(at: downloadsDir, withIntermediateDirectories: true, attributes: nil)
        
        let sanitizedName = (filename as NSString).lastPathComponent
        let targetFileURL = downloadsDir.appendingPathComponent(sanitizedName)
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self = self, let tempURL = tempURL, error == nil else {
                print("[Devaari Download] Failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if fileManager.fileExists(atPath: targetFileURL.path) {
                    try? fileManager.removeItem(at: targetFileURL)
                }
                try fileManager.moveItem(at: tempURL, to: targetFileURL)
                
                // Add to BrowserManager download list
                DispatchQueue.main.async {
                    let isVideo = sanitizedName.lowercased().hasSuffix(".mp4") || sanitizedName.lowercased().hasSuffix(".mov")
                    let fileSize = (try? fileManager.attributesOfItem(atPath: targetFileURL.path)[.size] as? Int64) ?? 0
                    let item = DownloadedItem(
                        filename: sanitizedName,
                        fileURL: targetFileURL,
                        downloadDate: Date(),
                        fileSize: fileSize,
                        isVideo: isVideo
                    )
                    self.browserManager?.downloads.insert(item, at: 0)
                    
                    // Auto-save to iPad Photos Library
                    if isVideo {
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: targetFileURL)
                        }, completionHandler: nil)
                    } else if sanitizedName.lowercased().hasSuffix(".png") || sanitizedName.lowercased().hasSuffix(".jpg") || sanitizedName.lowercased().hasSuffix(".webp") {
                        if let image = UIImage(contentsOfFile: targetFileURL.path) {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        }
                    }
                    
                    // Send completion notification to side panel
                    self.notifyDownloadComplete(downloadId: downloadId)
                }
            } catch {
                print("[Devaari Download] File write error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
    private func notifyDownloadComplete(downloadId: Int) {
        let js = "window.__devaariHandleResponse && window.__devaariHandleResponse({ type: 'DOWNLOAD_COMPLETE', downloadId: \(downloadId) });"
        sidePanelWebView?.evaluateJavaScript(js, completionHandler: nil)
    }
    
    private func handleOAuthFlow(url: URL, callId: Int?) {
        // ASWebAuthenticationSession for Google sign-in if triggered
        DispatchQueue.main.async {
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "devaari"
            ) { [weak self] callbackURL, error in
                if let error = error {
                    self?.sendError(callId: callId, error: error.localizedDescription)
                } else if let callbackURL = callbackURL {
                    self?.sendResult(callId: callId, result: callbackURL.absoluteString)
                }
            }
            session.presentationContextProvider = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?
                .windows
                .first as? ASWebAuthenticationPresentationContextProviding
            session.start()
        }
    }
    
    private func sendResult(callId: Int?, result: Any?) {
        guard let callId = callId else { return }
        DispatchQueue.main.async { [weak self] in
            let serialized: String
            if let result = result {
                if let jsonData = try? JSONSerialization.data(withJSONObject: result, options: []),
                   let jsonStr = String(data: jsonData, encoding: .utf8) {
                    serialized = jsonStr
                } else if let str = result as? String {
                    serialized = "\"\(str.replacingOccurrences(of: "\"", with: "\\\""))\""
                } else if let num = result as? NSNumber {
                    serialized = "\(num)"
                } else if let b = result as? Bool {
                    serialized = b ? "true" : "false"
                } else {
                    serialized = "null"
                }
            } else {
                serialized = "null"
            }
            
            let js = "window.__devaariHandleResponse && window.__devaariHandleResponse({ callId: \(callId), result: \(serialized) });"
            self?.sidePanelWebView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }
    
    private func sendError(callId: Int?, error: String) {
        guard let callId = callId else { return }
        DispatchQueue.main.async { [weak self] in
            let escaped = error.replacingOccurrences(of: "'", with: "\\'").replacingOccurrences(of: "\n", with: " ")
            let js = "window.__devaariHandleResponse && window.__devaariHandleResponse({ callId: \(callId), error: '\(escaped)' });"
            self?.sidePanelWebView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}
