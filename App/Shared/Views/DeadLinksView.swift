import SwiftUI
import TidelineCore

struct DeadLinksView: View {
    var store: BookmarkStore

    private var deadBookmarks: [Bookmark] {
        store.allBookmarks.filter { store.deadLinkResults[$0.id]?.isDead == true }
    }

    var body: some View {
        List {
            ForEach(deadBookmarks) { bookmark in
                BookmarkRowView(bookmark: bookmark, status: store.deadLinkResults[bookmark.id])
            }
            .onDelete { offsets in
                Task {
                    for index in offsets {
                        try? await store.delete(deadBookmarks[index])
                    }
                }
            }
        }
        .navigationTitle("Dead Links")
        .overlay {
            if store.deadLinkResults.isEmpty {
                ContentUnavailableView(
                    "No Checks Run Yet",
                    systemImage: "checkmark.shield",
                    description: Text("Use \"Check Links\" in the toolbar to scan for broken bookmarks.")
                )
            } else if deadBookmarks.isEmpty {
                ContentUnavailableView(
                    "All Links Are Alive",
                    systemImage: "checkmark.circle",
                    description: Text("No broken bookmarks were found in the last check.")
                )
            }
        }
    }
}
