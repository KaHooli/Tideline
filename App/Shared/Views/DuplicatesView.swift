import SwiftUI
import TidelineCore

struct DuplicatesView: View {
    var store: BookmarkStore

    var body: some View {
        List {
            ForEach(store.duplicateGroups) { group in
                Section {
                    ForEach(group.bookmarks) { bookmark in
                        HStack {
                            BookmarkRowView(bookmark: bookmark, status: store.deadLinkResults[bookmark.id])
                            if bookmark.id == group.recommendedKeeper.id {
                                Text("Keep")
                                    .font(.caption.bold())
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                } header: {
                    Text(group.normalizedURL.absoluteString)
                        .font(.caption)
                } footer: {
                    Button("Merge — keep oldest, remove \(group.discardCandidates.count) duplicate(s)") {
                        merge(group)
                    }
                    .font(.caption)
                }
            }
        }
        .navigationTitle("Duplicates")
        .overlay {
            if store.duplicateGroups.isEmpty {
                ContentUnavailableView(
                    "No Duplicates Found",
                    systemImage: "checkmark.circle",
                    description: Text("Every bookmark has a unique URL.")
                )
            }
        }
    }

    private func merge(_ group: DuplicateGroup) {
        Task {
            for bookmark in group.discardCandidates {
                try? await store.delete(bookmark)
            }
        }
    }
}
