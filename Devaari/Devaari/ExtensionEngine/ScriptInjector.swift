import Foundation
import WebKit

class ScriptInjector {
    static let shared = ScriptInjector()
    
    private var recapCaptureScript: String = ""
    private var injectHelpersScript: String = ""
    private var wmDetectScript: String = ""
    private var wmScript: String = ""
    private var flowInjectScript: String = ""
    private var flowInjectCSS: String = ""
    
    init() {
        loadBundledScripts()
    }
    
    private func loadBundledScripts() {
        let bundleURL = Bundle.main.bundleURL
        let assetsDir = bundleURL.appendingPathComponent("ExtensionAssets")
        
        func readFile(_ relPath: String) -> String {
            let fileURL = assetsDir.appendingPathComponent(relPath)
            if FileManager.default.fileExists(atPath: fileURL.path),
               let str = try? String(contentsOf: fileURL, encoding: .utf8) {
                return str
            }
            let filename = (relPath as NSString).lastPathComponent
            let nameWithoutExt = (filename as NSString).deletingPathExtension
            let ext = (filename as NSString).pathExtension
            if let fallbackPath = Bundle.main.path(forResource: nameWithoutExt, ofType: ext, inDirectory: "ExtensionAssets") {
                return (try? String(contentsOfFile: fallbackPath, encoding: .utf8)) ?? ""
            }
            if let rootPath = Bundle.main.path(forResource: nameWithoutExt, ofType: ext) {
                return (try? String(contentsOfFile: rootPath, encoding: .utf8)) ?? ""
            }
            return ""
        }
        
        recapCaptureScript = readFile("recap-capture.js")
        injectHelpersScript = readFile("inject.js")
        wmDetectScript = readFile("vendor/wm-detect.js")
        wmScript = readFile("wm.js")
        flowInjectScript = readFile("flow-inject.js")
        flowInjectCSS = readFile("flow-inject.css")
    }
    
    func configureUserContentController(_ contentController: WKUserContentController) {
        // 1. Injected at documentStart in MAIN world: recap-capture.js and inject.js
        let startScriptsCombined = """
        // Devaari Browser - Document Start Injections
        \(recapCaptureScript)
        \(injectHelpersScript)
        """
        
        let startUserScript = WKUserScript(
            source: startScriptsCombined,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false,
            in: .page
        )
        contentController.addUserScript(startUserScript)
        
        // 2. CSS Style injection at documentEnd
        let escapedCSS = flowInjectCSS
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
            
        let cssInjector = """
        (function() {
            var s = document.createElement('style');
            s.id = 'devaari-flow-inject-style';
            s.textContent = `\(escapedCSS)`;
            (document.head || document.documentElement).appendChild(s);
        })();
        """
        
        // 3. Document End scripts (wm-detect, wm, flow-inject)
        let endScriptsCombined = """
        // Devaari Browser - Document End Injections
        \(cssInjector)
        \(wmDetectScript)
        \(wmScript)
        \(flowInjectScript)
        """
        
        let endUserScript = WKUserScript(
            source: endScriptsCombined,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false,
            in: .page
        )
        contentController.addUserScript(endUserScript)
    }
}
