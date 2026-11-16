import SwiftUI
import QuickLook

struct BookmarksSheetView: View {
    @EnvironmentObject var browserManager: BrowserManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Devaari Quick Access")) {
                    Button(action: {
                        browserManager.navigateActiveTab(to: "https://flow.google.com")
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.blue)
                            Text("Google Flow (flow.google.com)")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {
                        browserManager.navigateActiveTab(to: "https://labs.google")
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "flask.fill")
                                .foregroundColor(.purple)
                            Text("Google Labs")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Section(header: Text("Saved Bookmarks")) {
                    if browserManager.bookmarks.isEmpty {
                        Text("No bookmarks saved yet.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(browserManager.bookmarks) { bookmark in
                            Button(action: {
                                browserManager.navigateActiveTab(to: bookmark.url)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(bookmark.title)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text(bookmark.url)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                browserManager.removeBookmark(id: browserManager.bookmarks[index].id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct DownloadsSheetView: View {
    @EnvironmentObject var browserManager: BrowserManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                if browserManager.downloads.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Downloads Yet")
                            .font(.headline)
                        Text("Images and videos generated with Flow Automator will automatically show up here and save to your iPad.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
                } else {
                    ForEach(browserManager.downloads) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.isVideo ? "video.fill" : "photo.fill")
                                .font(.system(size: 22))
                                .foregroundColor(item.isVideo ? .purple : .blue)
                                .frame(width: 40, height: 40)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.filename)
                                    .font(.system(size: 15, weight: .medium))
                                    .lineLimit(1)
                                
                                HStack(spacing: 8) {
                                    Text(ByteCountFormatter.string(fromByteCount: item.fileSize, countStyle: .file))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    
                                    Text(item.downloadDate, style: .time)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Share / Export Button
                            ShareLink(item: item.fileURL) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 15))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Downloads")
            .navigationBarItems(
                leading: Button("Clear") {
                    browserManager.downloads.removeAll()
                }.disabled(browserManager.downloads.isEmpty),
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
