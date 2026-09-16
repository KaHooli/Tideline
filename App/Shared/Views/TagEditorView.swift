import SwiftUI
import TidelineCore

struct TagEditorView: View {
    let bookmark: Bookmark
    var store: BookmarkStore

    @Environment(\.dismiss) private var dismiss
    @State private var tagsText: String

    init(bookmark: Bookmark, store: BookmarkStore) {
        self.bookmark = bookmark
        self.store = store
        _tagsText = State(initialValue: bookmark.tags.sorted().joined(separator: ", "))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tags for \"\(bookmark.title)\"") {
                    TextField("work, reference, recipes", text: $tagsText)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                }
                Text("Separate multiple tags with commas. Tags are stored only in Tideline — Safari has no native concept of tags.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Edit Tags")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 360, minHeight: 160)
        #endif
    }

    private func save() {
        let tags = Set(
            tagsText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        )
        try? store.setTags(tags, for: bookmark)
    }
}
