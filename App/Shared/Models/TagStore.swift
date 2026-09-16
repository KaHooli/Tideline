import Foundation

/// Persists bookmark tags outside of Safari, since `browser.bookmarks` has no native
/// concept of tags — Safari itself never sees or stores this data. Lives in the same App
/// Group container as the bookmarks bridge so it survives app relaunches.
public struct TagStore: Sendable {
    private let appGroupID = "group.au.id.cavanaghs.Tideline"
    private let filename = "tags.json"

    public init() {}

    public func loadAll() -> [String: Set<String>] {
        guard
            let container = containerURL,
            let data = try? Data(contentsOf: container.appendingPathComponent(filename)),
            let decoded = try? JSONDecoder().decode([String: Set<String>].self, from: data)
        else {
            return [:]
        }
        return decoded
    }

    public func setTags(_ tags: Set<String>, for bookmarkID: String) throws {
        var all = loadAll()
        if tags.isEmpty {
            all.removeValue(forKey: bookmarkID)
        } else {
            all[bookmarkID] = tags
        }
        try save(all)
    }

    private func save(_ tagsByBookmarkID: [String: Set<String>]) throws {
        guard let container = containerURL else { throw BridgeError.extensionNotEnabled }
        let data = try JSONEncoder().encode(tagsByBookmarkID)
        try data.write(to: container.appendingPathComponent(filename), options: .atomic)
    }

    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }
}
