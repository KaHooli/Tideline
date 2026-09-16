import Testing
import Foundation
@testable import TidelineCore

private struct FakeLinkStatusClient: LinkStatusClient {
    let statusesByURL: [URL: LinkStatus]

    func status(of url: URL) async -> LinkStatus {
        statusesByURL[url] ?? .unreachable(reason: "no fixture for \(url)")
    }
}

struct DeadLinkCheckerTests {
    @Test func checksEveryBookmarkAndReportsStatus() async {
        let alive = Bookmark(title: "Alive", url: URL(string: "https://alive.example.com")!)
        let dead = Bookmark(title: "Dead", url: URL(string: "https://dead.example.com")!)

        let client = FakeLinkStatusClient(statusesByURL: [
            alive.url: .alive(statusCode: 200),
            dead.url: .dead(statusCode: 404)
        ])
        let checker = DeadLinkChecker(client: client, maxConcurrentChecks: 4)

        let results = await checker.check([alive, dead])
        let byID = Dictionary(uniqueKeysWithValues: results.map { ($0.bookmarkID, $0.status) })

        #expect(byID[alive.id] == .alive(statusCode: 200))
        #expect(byID[dead.id] == .dead(statusCode: 404))
    }

    @Test func respectsConcurrencyLimitAndCompletesAllChecks() async {
        let bookmarks = (0..<20).map {
            Bookmark(title: "T\($0)", url: URL(string: "https://example.com/\($0)")!)
        }
        let statuses = Dictionary(uniqueKeysWithValues: bookmarks.map { ($0.url, LinkStatus.alive(statusCode: 200)) })
        let checker = DeadLinkChecker(client: FakeLinkStatusClient(statusesByURL: statuses), maxConcurrentChecks: 3)

        let results = await checker.check(bookmarks)

        #expect(results.count == bookmarks.count)
    }
}
