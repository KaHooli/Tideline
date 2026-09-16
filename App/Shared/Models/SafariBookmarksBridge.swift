import Foundation
import TidelineCore

/// Talks to Safari's live bookmark store, which is only reachable through the
/// TidelineExtension Safari Web Extension (`browser.bookmarks` in background.js) —
/// neither macOS nor iOS lets the containing app read Safari's bookmarks directly.
public protocol SafariBookmarksBridge: Sendable {
    func fetchBookmarkTree() async throws -> BookmarkFolder
    func replaceBookmarkTree(with root: BookmarkFolder) async throws
    func deleteBookmark(id: String) async throws
}

public enum BridgeError: Error {
    case extensionNotEnabled
    case decodingFailed
}

/// Default bridge implementation.
///
/// IMPORTANT — architecture note for contributors:
/// The app process cannot call into the extension's JavaScript on demand; Safari only
/// runs `background.js` in response to its own triggers (toolbar icon, popup, a matching
/// page load). So state flows one way at a time, through an App Group shared container
/// (`group.au.id.cavanaghs.Tideline`):
///   1. `background.js` reads `browser.bookmarks.getTree()` and, via
///      `browser.runtime.sendNativeMessage`, hands the tree to `SafariWebExtensionHandler`,
///      which writes `bookmarks-snapshot.json` into the shared container.
///   2. This app reads that snapshot for `fetchBookmarkTree()`.
///   3. For writes, this app appends an operation to `pending-operations.json` in the same
///      container. The extension's popup, when opened, drains that queue and applies each
///      operation via `browser.bookmarks.*`, then re-syncs the snapshot.
///
/// This needs verifying against Apple's current WebExtension native-messaging docs once
/// Xcode is installed and the extension can actually run on-device — the exact plumbing
/// (whether a background/persistent page is available on iOS vs. only popup-triggered sync)
/// may need adjusting.
public struct NativeMessagingBookmarksBridge: SafariBookmarksBridge {
    private let appGroupID = "group.au.id.cavanaghs.Tideline"
    private let snapshotFilename = "bookmarks-snapshot.json"
    private let pendingOperationsFilename = "pending-operations.json"

    public init() {}

    public func fetchBookmarkTree() async throws -> BookmarkFolder {
        guard let container = containerURL else { throw BridgeError.extensionNotEnabled }
        let data = try Data(contentsOf: container.appendingPathComponent(snapshotFilename))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BookmarkFolder.self, from: data)
    }

    public func replaceBookmarkTree(with root: BookmarkFolder) async throws {
        try enqueue(.replaceTree(root))
    }

    public func deleteBookmark(id: String) async throws {
        try enqueue(.deleteBookmark(id: id))
    }

    private func enqueue(_ operation: PendingOperation) throws {
        guard let container = containerURL else { throw BridgeError.extensionNotEnabled }
        let queueURL = container.appendingPathComponent(pendingOperationsFilename)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        var queue: [PendingOperation] = []
        if let existing = try? Data(contentsOf: queueURL) {
            queue = (try? decoder.decode([PendingOperation].self, from: existing)) ?? []
        }
        queue.append(operation)

        let data = try encoder.encode(queue)
        try data.write(to: queueURL, options: .atomic)
    }

    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }
}

/// Operations queued for the extension to apply on its next sync.
enum PendingOperation: Codable {
    case replaceTree(BookmarkFolder)
    case deleteBookmark(id: String)
}
