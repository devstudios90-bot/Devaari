import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var browserManager: BrowserManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(browserManager.tabs) { tab in
                    TabItemView(tab: tab)
                }
                
                // New Tab Button
                Button(action: {
                    browserManager.createNewTab()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 34, height: 34)
                        .background(Color(UIColor.systemGray5))
                        .cornerRadius(8)
                }
                .padding(.leading, 4)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct TabItemView: View {
    @ObservedObject var tab: BrowserTab
    @EnvironmentObject var browserManager: BrowserManager
    
    var isActive: Bool {
        browserManager.activeTabId == tab.id
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon
            if tab.isFlowSite {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.blue)
            } else if tab.isLoading {
                ProgressView()
                    .scaleEffect(0.65)
                    .frame(width: 14, height: 14)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            // Title
            Text(tab.title.isEmpty ? "New Tab" : tab.title)
                .font(.system(size: 13, weight: isActive ? .medium : .regular))
                .foregroundColor(isActive ? .primary : .secondary)
                .lineLimit(1)
                .frame(maxWidth: 160, alignment: .leading)
            
            // Close Button
            Button(action: {
                browserManager.closeTab(id: tab.id)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 18, height: 18)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isActive ? Color(UIColor.systemBackground) : Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(10)
        .shadow(color: isActive ? Color.black.opacity(0.08) : Color.clear, radius: 4, x: 0, y: 1)
        .onTapGesture {
            browserManager.selectTab(id: tab.id)
        }
    }
}
