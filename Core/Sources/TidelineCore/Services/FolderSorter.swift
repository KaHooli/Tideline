import Foundation

/// Strategies for regrouping a flat list of bookmarks into folders.
public enum SortStrategy: Sendable {
    case byDomain
    case byDateAdded(granularity: DateGranularity)
    case byTag

    public enum DateGranularity: Sendable {
        case year
        case month
    }
}

public enum FolderSorter {
    /// Builds a new folder tree from a flat list of bookmarks according to `strategy`.
    /// Bookmarks that don't fit any group (e.g. no tags, under `.byTag`) are placed in
    /// a trailing "Unsorted" folder.
    public static func sort(_ bookmarks: [Bookmark], by strategy: SortStrategy, rootTitle: String = "Tideline Sorted") -> BookmarkFolder {
        switch strategy {
        case .byDomain:
            return groupIntoFolders(bookmarks, rootTitle: rootTitle) { bookmark in
                bookmark.url.host()?.replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
            }
        case .byDateAdded(let granularity):
            return groupIntoFolders(bookmarks, rootTitle: rootTitle) { bookmark in
                dateLabel(for: bookmark.dateAdded, granularity: granularity)
            }
        case .byTag:
            return groupByTag(bookmarks, rootTitle: rootTitle)
        }
    }

    private static func groupIntoFolders(
        _ bookmarks: [Bookmark],
        rootTitle: String,
        keyFor: (Bookmark) -> String?
    ) -> BookmarkFolder {
        var groups: [String: [Bookmark]] = [:]
        var unsorted: [Bookmark] = []

        for bookmark in bookmarks {
            if let key = keyFor(bookmark), !key.isEmpty {
                groups[key, default: []].append(bookmark)
            } else {
                unsorted.append(bookmark)
            }
        }

        var children: [BookmarkNode] = groups.keys.sorted().map { key in
            .folder(BookmarkFolder(title: key, children: groups[key]!.map(BookmarkNode.bookmark)))
        }

        if !unsorted.isEmpty {
            children.append(.folder(BookmarkFolder(title: "Unsorted", children: unsorted.map(BookmarkNode.bookmark))))
        }

        return BookmarkFolder(title: rootTitle, children: children)
    }

    /// Tags fan out: a bookmark with multiple tags appears under each tag's folder.
    private static func groupByTag(_ bookmarks: [Bookmark], rootTitle: String) -> BookmarkFolder {
        var groups: [String: [Bookmark]] = [:]
        var untagged: [Bookmark] = []

        for bookmark in bookmarks {
            if bookmark.tags.isEmpty {
                untagged.append(bookmark)
            } else {
                for tag in bookmark.tags {
                    groups[tag, default: []].append(bookmark)
                }
            }
        }

        var children: [BookmarkNode] = groups.keys.sorted().map { tag in
            .folder(BookmarkFolder(title: tag, children: groups[tag]!.map(BookmarkNode.bookmark)))
        }

        if !untagged.isEmpty {
            children.append(.folder(BookmarkFolder(title: "Untagged", children: untagged.map(BookmarkNode.bookmark))))
        }

        return BookmarkFolder(title: rootTitle, children: children)
    }

    private static func dateLabel(for date: Date, granularity: SortStrategy.DateGranularity) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = granularity == .year ? "yyyy" : "yyyy-MM"
        return formatter.string(from: date)
    }
}
