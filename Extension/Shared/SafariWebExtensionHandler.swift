import Foundation
import SafariServices

/// Receives native messages from background.js (`browser.runtime.sendNativeMessage`) and
/// relays bookmark data through the App Group shared container so the main app — which
/// cannot talk to the extension's JavaScript directly — can read it.
///
/// Shared verbatim between the macOS and iOS extension targets (see project.yml); the
/// `SafariServices` + `Foundation` APIs used here are identical on both platforms.
public class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private let appGroupID = "group.au.id.cavanaghs.Tideline"
    private let snapshotFilename = "bookmarks-snapshot.json"
    private let pendingOperationsFilename = "pending-operations.json"

    public func beginRequest(with context: NSExtensionContext) {
        guard
            let item = context.inputItems.first as? NSExtensionItem,
            let message = item.userInfo?[SFExtensionMessageKey] as? [String: Any],
            let type = message["type"] as? String
        else {
            respond(context, with: ["error": "malformed message"])
            return
        }

        switch type {
        case "syncSnapshot":
            handleSyncSnapshot(message: message, context: context)
        case "fetchPendingOperations":
            handleFetchPendingOperations(context: context)
        case "clearPendingOperations":
            handleClearPendingOperations(context: context)
        default:
            respond(context, with: ["error": "unknown message type: \(type)"])
        }
    }

    private func handleSyncSnapshot(message: [String: Any], context: NSExtensionContext) {
        guard
            let folderPayload = message["folder"],
            JSONSerialization.isValidJSONObject(folderPayload),
            let data = try? JSONSerialization.data(withJSONObject: folderPayload),
            let container = containerURL
        else {
            respond(context, with: ["error": "failed to serialize snapshot"])
            return
        }

        do {
            try data.write(to: container.appendingPathComponent(snapshotFilename), options: .atomic)
            respond(context, with: ["ok": true])
        } catch {
            respond(context, with: ["error": error.localizedDescription])
        }
    }

    private func handleFetchPendingOperations(context: NSExtensionContext) {
        guard
            let container = containerURL,
            let data = try? Data(contentsOf: container.appendingPathComponent(pendingOperationsFilename)),
            let operations = try? JSONSerialization.jsonObject(with: data)
        else {
            respond(context, with: ["operations": []])
            return
        }
        respond(context, with: ["operations": operations])
    }

    private func handleClearPendingOperations(context: NSExtensionContext) {
        if let container = containerURL {
            try? FileManager.default.removeItem(at: container.appendingPathComponent(pendingOperationsFilename))
        }
        respond(context, with: ["ok": true])
    }

    private func respond(_ context: NSExtensionContext, with payload: [String: Any]) {
        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: payload]
        context.completeRequest(returningItems: [response], completionHandler: nil)
    }

    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }
}
