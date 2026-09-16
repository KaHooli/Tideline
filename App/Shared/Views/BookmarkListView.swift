import SwiftUI
import TidelineCore

struct BookmarkListView: View {
    let bookmarks: [Bookmark]
    var store: BookmarkStore

    @State private var editingTagsFor: Bookmark?

    var body: some View {
        List {
            ForEach(bookmarks) { bookmark in
                BookmarkRowView(bookmark: bookmark, status: store.deadLinkResults[bookmark.id])
                    .contextMenu {
                        Button {
                            editingTagsFor = bookmark
                        } label: {
                            Label("Edit Tags…", systemImage: "tag")
                        }
                    }
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
        .sheet(item: $editingTagsFor) { bookmark in
            TagEditorView(bookmark: bookmark, store: store)
        }
    }
}
