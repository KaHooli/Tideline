import Testing
import Foundation
@testable import TidelineCore

struct DuplicateDetectorTests {
    @Test func findsDuplicatesIgnoringTrailingSlashAndWww() {
        let a = Bookmark(title: "A", url: URL(string: "https://www.example.com/page/")!, dateAdded: Date(timeIntervalSince1970: 100))
        let b = Bookmark(title: "B", url: URL(string: "https://example.com/page")!, dateAdded: Date(timeIntervalSince1970: 200))
        let unrelated = Bookmark(title: "C", url: URL(string: "https://example.com/other")!)

        let groups = DuplicateDetector.findDuplicates(in: [a, b, unrelated])

        #expect(groups.count == 1)
        #expect(Set(groups[0].bookmarks.map(\.id)) == Set([a.id, b.id]))
    }

    @Test func stripsTrackingQueryParamsButKeepsOthers() {
        let a = Bookmark(title: "A", url: URL(string: "https://example.com/page?utm_source=x&id=1")!)
        let b = Bookmark(title: "B", url: URL(string: "https://example.com/page?id=1")!)
        let c = Bookmark(title: "C", url: URL(string: "https://example.com/page?id=2")!)

        let groups = DuplicateDetector.findDuplicates(in: [a, b, c])

        #expect(groups.count == 1)
        #expect(groups[0].bookmarks.count == 2)
    }

    @Test func recommendedKeeperIsOldest() {
        let older = Bookmark(title: "Older", url: URL(string: "https://example.com/x")!, dateAdded: Date(timeIntervalSince1970: 0))
        let newer = Bookmark(title: "Newer", url: URL(string: "https://example.com/x")!, dateAdded: Date(timeIntervalSince1970: 1000))

        let groups = DuplicateDetector.findDuplicates(in: [newer, older])

        #expect(groups.first?.recommendedKeeper.id == older.id)
        #expect(groups.first?.discardCandidates.map(\.id) == [newer.id])
    }

    @Test func mergedTagsUnionsAcrossGroup() {
        let a = Bookmark(title: "A", url: URL(string: "https://example.com/x")!, tags: ["work"])
        let b = Bookmark(title: "B", url: URL(string: "https://example.com/x")!, tags: ["reference"])

        let group = DuplicateDetector.findDuplicates(in: [a, b]).first

        #expect(group?.mergedTags == ["work", "reference"])
    }

    @Test func noDuplicatesWhenAllURLsDistinct() {
        let bookmarks = (0..<5).map {
            Bookmark(title: "T\($0)", url: URL(string: "https://example.com/\($0)")!)
        }

        #expect(DuplicateDetector.findDuplicates(in: bookmarks).isEmpty)
    }
}
