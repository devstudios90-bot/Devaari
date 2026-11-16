import SwiftUI

struct MainBrowserView: View {
    @EnvironmentObject var browserManager: BrowserManager
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top Tab Bar
                TabBarView()
                
                // Address & Navigation Bar
                AddressBarView()
                
                // Browser Main Body (Split View for iPad)
                HStack(spacing: 0) {
                    // Active Tab Web View
                    if let activeTab = browserManager.activeTab {
                        WebViewContainer(tab: activeTab)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Color(UIColor.systemBackground)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    // Built-in Flow Automator Side Panel
                    if browserManager.isSidePanelOpen {
                        Divider()
                        
                        SidePanelView()
                            .frame(width: min(browserManager.sidePanelWidth, geometry.size.width * 0.48))
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
        }
        .onAppear {
            browserManager.setupInitialTabIfNeeded()
        }
        .sheet(isPresented: $browserManager.isShowingBookmarksSheet) {
            BookmarksSheetView()
                .environmentObject(browserManager)
        }
        .sheet(isPresented: $browserManager.isShowingDownloadsSheet) {
            DownloadsSheetView()
                .environmentObject(browserManager)
        }
    }
}
