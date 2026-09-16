import SwiftUI
import TidelineCore

enum SidebarSection: Hashable {
    case allBookmarks
    case duplicates
    case deadLinks
}

struct ContentView: View {
    @State private var store = BookmarkStore()
    @State private var selectedSection: SidebarSection? = .allBookmarks
    @State private var isCheckingLinks = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSection) {
                Label("All Bookmarks", systemImage: "bookmark")
                    .tag(SidebarSection.allBookmarks)
                Label("Duplicates", systemImage: "doc.on.doc")
                    .badge(store.duplicateGroups.count)
                    .tag(SidebarSection.duplicates)
                Label("Dead Links", systemImage: "exclamationmark.triangle")
                    .badge(store.deadLinkResults.values.filter(\.isDead).count)
                    .tag(SidebarSection.deadLinks)
            }
            .navigationTitle("Tideline")
        } detail: {
            detailView
                .searchable(text: $store.searchQuery, prompt: "Search bookmarks")
                .toolbar { toolbarContent }
        }
        .task {
            await store.refreshFromSafari()
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedSection {
        case .allBookmarks, .none:
            BookmarkListView(bookmarks: store.searchQuery.isEmpty ? store.allBookmarks : store.searchResults, store: store)
        case .duplicates:
            DuplicatesView(store: store)
        case .deadLinks:
            DeadLinksView(store: store)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem {
            Menu {
                Button("By Domain") { applySort(.byDomain) }
                Button("By Date Added") { applySort(.byDateAdded(granularity: .month)) }
                Button("By Tag") { applySort(.byTag) }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
        }
        ToolbarItem {
            Button {
                Task {
                    isCheckingLinks = true
                    await store.checkAllLinks()
                    isCheckingLinks = false
                }
            } label: {
                if isCheckingLinks {
                    ProgressView()
                } else {
                    Label("Check Links", systemImage: "checkmark.shield")
                }
            }
            .disabled(isCheckingLinks)
        }
    }

    private func applySort(_ strategy: SortStrategy) {
        let sorted = store.sortAllBookmarks(by: strategy)
        Task {
            try? await store.applyFolderTree(sorted)
        }
    }
}

#Preview {
    ContentView()
}
