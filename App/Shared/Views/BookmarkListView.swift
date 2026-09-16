import SwiftUI
import TidelineCore

struct BookmarkListView: View {
    let bookmarks: [Bookmark]
    var store: BookmarkStore

    var body: some View {
        List {
            ForEach(bookmarks) { bookmark in
                BookmarkRowView(bookmark: bookmark, status: store.deadLinkResults[bookmark.id])
            }
            .onDelete { offsets in
                Task {
                    for index in offsets {
                        try? await store.delete(bookmarks[index])
                    }
                }
            }
        }
        .navigationTitle("All Bookmarks")
        .overlay {
            if bookmarks.isEmpty {
                ContentUnavailableView(
                    "No Bookmarks",
                    systemImage: "bookmark.slash",
                    description: Text("Enable the Tideline extension in Safari to sync your bookmarks.")
                )
            }
        }
    }
}
