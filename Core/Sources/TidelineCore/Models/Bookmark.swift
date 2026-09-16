import Foundation

/// A single Safari bookmark, mirrored from the WebExtension `browser.bookmarks` node.
public struct Bookmark: Identifiable, Hashable, Codable, Sendable {
    public var id: String
    public var title: String
    public var url: URL
    public var dateAdded: Date
    public var tags: Set<String>
    public var parentFolderID: String?

    /// Result of the most recent dead-link check, if any has been run.
    public var linkStatus: LinkStatus?

    public init(
        id: String = UUID().uuidString,
        title: String,
        url: URL,
        dateAdded: Date = Date(),
        tags: Set<String> = [],
        parentFolderID: String? = nil,
        linkStatus: LinkStatus? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.dateAdded = dateAdded
        self.tags = tags
        self.parentFolderID = parentFolderID
        self.linkStatus = linkStatus
    }
}

extension Bookmark {
    /// A URL normalized for duplicate comparison: lowercased host, no "www.", no
    /// trailing slash, no fragment, and common tracking query params stripped.
    public var normalizedURL: URL {
        Self.normalize(url)
    }

    private static let trackingParamPrefixes = ["utm_", "gclid", "fbclid", "mc_cid", "mc_eid", "igshid"]

    public static func normalize(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        components.host = components.host?.lowercased().replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
        components.fragment = nil

        if let items = components.queryItems {
            let filtered = items.filter { item in
                !trackingParamPrefixes.contains { item.name.lowercased().hasPrefix($0) }
            }
            components.queryItems = filtered.isEmpty ? nil : filtered.sorted { $0.name < $1.name }
        }

        if components.path.count > 1, components.path.hasSuffix("/") {
            components.path.removeLast()
        }

        return components.url ?? url
    }
}
