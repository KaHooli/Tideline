import Foundation

/// A set of bookmarks whose normalized URLs match, along with the one recommended to keep.
public struct DuplicateGroup: Identifiable, Sendable {
    public var id: URL { normalizedURL }
    public let normalizedURL: URL
    public let bookmarks: [Bookmark]

    /// The bookmark to keep: oldest by date added, breaking ties by most tags.
    public var recommendedKeeper: Bookmark {
        bookmarks.min { lhs, rhs in
            if lhs.dateAdded != rhs.dateAdded {
                return lhs.dateAdded < rhs.dateAdded
            }
            return lhs.tags.count > rhs.tags.count
        } ?? bookmarks[0]
    }

    /// Every bookmark other than the recommended keeper.
    public var discardCandidates: [Bookmark] {
        let keeperID = recommendedKeeper.id
        return bookmarks.filter { $0.id != keeperID }
    }

    /// The union of tags across all bookmarks in the group, useful when merging into the keeper.
    public var mergedTags: Set<String> {
        bookmarks.reduce(into: Set<String>()) { $0.formUnion($1.tags) }
    }
}

public enum DuplicateDetector {
    /// Groups bookmarks that share a normalized URL. Only groups with more than one
    /// bookmark are returned.
    public static func findDuplicates(in bookmarks: [Bookmark]) -> [DuplicateGroup] {
        var byNormalizedURL: [URL: [Bookmark]] = [:]
        for bookmark in bookmarks {
            byNormalizedURL[bookmark.normalizedURL, default: []].append(bookmark)
        }

        return byNormalizedURL
            .filter { $0.value.count > 1 }
            .map { DuplicateGroup(normalizedURL: $0.key, bookmarks: $0.value) }
            .sorted { $0.bookmarks.count > $1.bookmarks.count }
    }
}
