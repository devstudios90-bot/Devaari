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
        if let recapPath = Bundle.main.path(forResource: "recap-capture", ofType: "js", inDirectory: "ExtensionAssets") {
            recapCaptureScript = (try? String(contentsOfFile: recapPath, encoding: .utf8)) ?? ""
        }
        if let injectPath = Bundle.main.path(forResource: "inject", ofType: "js", inDirectory: "ExtensionAssets") {
            injectHelpersScript = (try? String(contentsOfFile: injectPath, encoding: .utf8)) ?? ""
        }
        if let wmDetectPath = Bundle.main.path(forResource: "wm-detect", ofType: "js", inDirectory: "ExtensionAssets/vendor") {
            wmDetectScript = (try? String(contentsOfFile: wmDetectPath, encoding: .utf8)) ?? ""
        }
        if let wmPath = Bundle.main.path(forResource: "wm", ofType: "js", inDirectory: "ExtensionAssets") {
            wmScript = (try? String(contentsOfFile: wmPath, encoding: .utf8)) ?? ""
        }
        if let flowInjectPath = Bundle.main.path(forResource: "flow-inject", ofType: "js", inDirectory: "ExtensionAssets") {
            flowInjectScript = (try? String(contentsOfFile: flowInjectPath, encoding: .utf8)) ?? ""
        }
        if let flowCSSPath = Bundle.main.path(forResource: "flow-inject", ofType: "css", inDirectory: "ExtensionAssets") {
            flowInjectCSS = (try? String(contentsOfFile: flowCSSPath, encoding: .utf8)) ?? ""
        }
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
