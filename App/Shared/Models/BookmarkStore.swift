import Foundation
import Observation
import TidelineCore

/// App-wide state: the current bookmark tree (sourced from Safari via the extension bridge),
/// plus the results of running Core services against it. Views read from this via @Observable.
@MainActor
@Observable
public final class BookmarkStore {
    public private(set) var root: BookmarkFolder
    public private(set) var duplicateGroups: [DuplicateGroup] = []
    public private(set) var deadLinkResults: [String: LinkStatus] = [:]
    public var searchQuery: String = ""

    private let bridge: any SafariBookmarksBridge
    private let deadLinkChecker: DeadLinkChecker
    private let tagStore: TagStore

    public init(
        bridge: any SafariBookmarksBridge = NativeMessagingBookmarksBridge(),
        deadLinkChecker: DeadLinkChecker = DeadLinkChecker(),
        tagStore: TagStore = TagStore()
    ) {
        self.bridge = bridge
        self.deadLinkChecker = deadLinkChecker
        self.tagStore = tagStore
        self.root = BookmarkFolder(title: "Favorites")
    }

    public var allBookmarks: [Bookmark] {
        root.allBookmarks
    }

    public var searchResults: [Bookmark] {
        SearchIndex.search(allBookmarks, query: searchQuery)
    }

    public func refreshFromSafari() async {
        do {
            let fetched = try await bridge.fetchBookmarkTree()
            let tagsByID = tagStore.loadAll()
            root = fetched.mapBookmarks { bookmark in
                var updated = bookmark
                updated.tags = tagsByID[bookmark.id] ?? []
                return updated
            }
            refreshDuplicates()
        } catch {
            // The bridge surfaces connectivity/permission issues; the UI layer decides
            // how to present them (e.g. "enable the Tideline extension in Safari").
        }
    }

    /// Tags live outside Safari entirely (see `TagStore`), so this only touches local
    /// state and the App Group — it never talks to the extension.
    public func setTags(_ tags: Set<String>, for bookmark: Bookmark) throws {
        try tagStore.setTags(tags, for: bookmark.id)
        root = root.mapBookmarks { candidate in
            guard candidate.id == bookmark.id else { return candidate }
            var updated = candidate
            updated.tags = tags
            return updated
        }
        refreshDuplicates()
    }

    public func refreshDuplicates() {
        duplicateGroups = DuplicateDetector.findDuplicates(in: allBookmarks)
    }

    public func sortAllBookmarks(by strategy: SortStrategy) -> BookmarkFolder {
        FolderSorter.sort(allBookmarks, by: strategy)
    }

    public func checkAllLinks() async {
        let results = await deadLinkChecker.check(allBookmarks)
        for result in results {
            deadLinkResults[result.bookmarkID] = result.status
        }
    }

    public func applyFolderTree(_ newRoot: BookmarkFolder) async throws {
        try await bridge.replaceBookmarkTree(with: newRoot)
        root = newRoot
        refreshDuplicates()
    }

    public func delete(_ bookmark: Bookmark) async throws {
        try await bridge.deleteBookmark(id: bookmark.id)
        await refreshFromSafari()
    }
}
