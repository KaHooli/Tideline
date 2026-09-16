import Foundation

/// Simple substring/relevance search over titles, URLs, and tags.
/// No external dependencies, so it works identically in the app and in unit tests.
public enum SearchIndex {
    public static func search(_ bookmarks: [Bookmark], query: String) -> [Bookmark] {
        let terms = query
            .lowercased()
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }

        guard !terms.isEmpty else { return bookmarks }

        return bookmarks
            .compactMap { bookmark -> (Bookmark, Int)? in
                let score = terms.reduce(0) { $0 + matchScore(for: bookmark, term: $1) }
                return score > 0 ? (bookmark, score) : nil
            }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    private static func matchScore(for bookmark: Bookmark, term: String) -> Int {
        var score = 0
        let title = bookmark.title.lowercased()
        let urlString = bookmark.url.absoluteString.lowercased()

        if title == term { score += 10 }
        else if title.hasPrefix(term) { score += 6 }
        else if title.contains(term) { score += 3 }

        if urlString.contains(term) { score += 2 }

        if bookmark.tags.contains(where: { $0.lowercased() == term }) { score += 8 }
        else if bookmark.tags.contains(where: { $0.lowercased().contains(term) }) { score += 4 }

        return score
    }
}
