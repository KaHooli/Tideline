import Testing
import Foundation
@testable import TidelineCore

struct FolderSorterTests {
    @Test func byDomainGroupsAndNormalizesWww() {
        let bookmarks = [
            Bookmark(title: "A", url: URL(string: "https://www.example.com/1")!),
            Bookmark(title: "B", url: URL(string: "https://example.com/2")!),
            Bookmark(title: "C", url: URL(string: "https://other.com/1")!)
        ]

        let root = FolderSorter.sort(bookmarks, by: .byDomain)
        let folderTitles = root.children.compactMap { node -> String? in
            if case .folder(let f) = node { return f.title }
            return nil
        }.sorted()

        #expect(folderTitles == ["example.com", "other.com"])
        #expect(root.allBookmarks.count == 3)
    }

    @Test func byTagFansOutMultiTaggedBookmarks() {
        let bookmark = Bookmark(title: "A", url: URL(string: "https://example.com")!, tags: ["work", "reading"])
        let untagged = Bookmark(title: "B", url: URL(string: "https://example.com/2")!)

        let root = FolderSorter.sort([bookmark, untagged], by: .byTag)
        let folders = root.children.compactMap { node -> BookmarkFolder? in
            if case .folder(let f) = node { return f }
            return nil
        }

        let titles = Set(folders.map(\.title))
        #expect(titles == ["work", "reading", "Untagged"])

        let workFolder = folders.first { $0.title == "work" }
        #expect(workFolder?.allBookmarks.map(\.id) == [bookmark.id])
    }

    @Test func byDateAddedGroupsByYear() {
        let calendar = Calendar(identifier: .gregorian)
        let date2023 = calendar.date(from: DateComponents(year: 2023, month: 5, day: 1))!
        let date2024 = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1))!

        let bookmarks = [
            Bookmark(title: "A", url: URL(string: "https://example.com/1")!, dateAdded: date2023),
            Bookmark(title: "B", url: URL(string: "https://example.com/2")!, dateAdded: date2024)
        ]

        let root = FolderSorter.sort(bookmarks, by: .byDateAdded(granularity: .year))
        let titles = root.children.compactMap { node -> String? in
            if case .folder(let f) = node { return f.title }
            return nil
        }.sorted()

        #expect(titles == ["2023", "2024"])
    }
}
