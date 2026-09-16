import Testing
import Foundation
@testable import TidelineCore

struct BookmarkFolderTests {
    @Test func mapBookmarksPreservesStructureAndAppliesTransform() {
        let a = Bookmark(title: "A", url: URL(string: "https://example.com/a")!)
        let b = Bookmark(title: "B", url: URL(string: "https://example.com/b")!)
        let inner = BookmarkFolder(id: "inner", title: "Inner", children: [.bookmark(b)])
        let root = BookmarkFolder(id: "root", title: "Root", children: [.bookmark(a), .folder(inner)])

        let mapped = root.mapBookmarks { bookmark in
            var updated = bookmark
            updated.tags = ["tagged"]
            return updated
        }

        #expect(mapped.id == "root")
        #expect(mapped.title == "Root")
        #expect(mapped.allBookmarks.allSatisfy { $0.tags == ["tagged"] })
        #expect(Set(mapped.allBookmarks.map(\.id)) == Set([a.id, b.id]))

        // Structure (which bookmarks live under which folder) is preserved.
        guard case .folder(let mappedInner) = mapped.children[1] else {
            Issue.record("expected second child to still be the Inner folder")
            return
        }
        #expect(mappedInner.id == "inner")
        #expect(mappedInner.allBookmarks.map(\.id) == [b.id])
    }

    @Test func mapBookmarksOnEmptyFolderIsNoOp() {
        let root = BookmarkFolder(id: "root", title: "Root")
        let mapped = root.mapBookmarks { $0 }
        #expect(mapped.allBookmarks.isEmpty)
    }
}
