import SwiftUI

@main
struct DevaariApp: App {
    @StateObject private var browserManager = BrowserManager()
    
    var body: some Scene {
        WindowGroup {
            MainBrowserView()
                .environmentObject(browserManager)
                .preferredColorScheme(.dark) // Sleek dark browser theme matching Flow Automator
        }
    }
}
