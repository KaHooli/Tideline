import Foundation

/// Outcome of checking whether a bookmark's URL still resolves.
public enum LinkStatus: Hashable, Codable, Sendable {
    case alive(statusCode: Int)
    case redirected(statusCode: Int, to: URL)
    case dead(statusCode: Int)
    case unreachable(reason: String)

    public var isDead: Bool {
        switch self {
        case .alive, .redirected:
            return false
        case .dead, .unreachable:
            return true
        }
    }
}

/// A single check result paired with the bookmark it was performed for.
public struct DeadLinkCheckResult: Identifiable, Sendable {
    public var id: String { bookmarkID }
    public let bookmarkID: String
    public let status: LinkStatus
    public let checkedAt: Date

    public init(bookmarkID: String, status: LinkStatus, checkedAt: Date = Date()) {
        self.bookmarkID = bookmarkID
        self.status = status
        self.checkedAt = checkedAt
    }
}
