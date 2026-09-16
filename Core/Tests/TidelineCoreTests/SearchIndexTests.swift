import Testing
import Foundation
@testable import TidelineCore

struct SearchIndexTests {
    @Test func exactTitleMatchRanksAboveSubstring() {
        let exact = Bookmark(title: "Swift", url: URL(string: "https://example.com/1")!)
        let substring = Bookmark(title: "SwiftUI Tutorials", url: URL(string: "https://example.com/2")!)

        let results = SearchIndex.search([substring, exact], query: "swift")

        #expect(results.first?.id == exact.id)
    }

    @Test func matchesByTag() {
        let tagged = Bookmark(title: "Untitled", url: URL(string: "https://example.com/1")!, tags: ["recipes"])
        let other = Bookmark(title: "Other", url: URL(string: "https://example.com/2")!)

        let results = SearchIndex.search([tagged, other], query: "recipes")

        #expect(results.map(\.id) == [tagged.id])
    }

    @Test func matchesByURL() {
        let bookmark = Bookmark(title: "Home", url: URL(string: "https://github.com/anthropics")!)

        let results = SearchIndex.search([bookmark], query: "github")

        #expect(results.map(\.id) == [bookmark.id])
    }

    @Test func emptyQueryReturnsAllUnfiltered() {
        let bookmarks = [
            Bookmark(title: "A", url: URL(string: "https://example.com/1")!),
            Bookmark(title: "B", url: URL(string: "https://example.com/2")!)
        ]

        #expect(SearchIndex.search(bookmarks, query: "").count == 2)
    }

    @Test func noMatchesReturnsEmpty() {
        let bookmarks = [Bookmark(title: "A", url: URL(string: "https://example.com/1")!)]

        #expect(SearchIndex.search(bookmarks, query: "zzz-nomatch").isEmpty)
    }
}
