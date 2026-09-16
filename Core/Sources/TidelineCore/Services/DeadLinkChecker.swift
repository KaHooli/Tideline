import Foundation

/// Abstracts the network call so tests can substitute a fake without hitting the network.
public protocol LinkStatusClient: Sendable {
    func status(of url: URL) async -> LinkStatus
}

/// Default client: issues a HEAD request, falling back to GET if the server rejects HEAD.
public struct URLSessionLinkStatusClient: LinkStatusClient {
    private let session: URLSession
    private let timeout: TimeInterval

    public init(session: URLSession = .shared, timeout: TimeInterval = 10) {
        self.session = session
        self.timeout = timeout
    }

    public func status(of url: URL) async -> LinkStatus {
        do {
            let status = try await requestStatus(url: url, method: "HEAD")
            if status == 405 || status == 501 {
                return try await LinkStatus.from(statusCode: requestStatus(url: url, method: "GET"), finalURL: url, originalURL: url)
            }
            return .from(statusCode: status, finalURL: url, originalURL: url)
        } catch {
            return .unreachable(reason: error.localizedDescription)
        }
    }

    private func requestStatus(url: URL, method: String) async throws -> Int {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return http.statusCode
    }
}

extension LinkStatus {
    fileprivate static func from(statusCode: Int, finalURL: URL, originalURL: URL) -> LinkStatus {
        switch statusCode {
        case 200..<300:
            return .alive(statusCode: statusCode)
        case 300..<400:
            return .redirected(statusCode: statusCode, to: finalURL)
        default:
            return .dead(statusCode: statusCode)
        }
    }
}

/// Checks a batch of bookmarks concurrently, bounded by `maxConcurrentChecks`.
public actor DeadLinkChecker {
    private let client: LinkStatusClient
    private let maxConcurrentChecks: Int

    public init(client: LinkStatusClient = URLSessionLinkStatusClient(), maxConcurrentChecks: Int = 8) {
        self.client = client
        self.maxConcurrentChecks = maxConcurrentChecks
    }

    public func check(_ bookmarks: [Bookmark]) async -> [DeadLinkCheckResult] {
        await withTaskGroup(of: DeadLinkCheckResult.self) { group in
            var results: [DeadLinkCheckResult] = []
            results.reserveCapacity(bookmarks.count)

            var iterator = bookmarks.makeIterator()

            func addNext() {
                guard let bookmark = iterator.next() else { return }
                group.addTask {
                    let status = await self.client.status(of: bookmark.url)
                    return DeadLinkCheckResult(bookmarkID: bookmark.id, status: status)
                }
            }

            for _ in 0..<maxConcurrentChecks {
                addNext()
            }

            while let result = await group.next() {
                results.append(result)
                addNext()
            }

            return results
        }
    }
}
