import SwiftUI
import TidelineCore

struct BookmarkRowView: View {
    let bookmark: Bookmark
    let status: LinkStatus?

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: faviconURL) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                Image(systemName: "globe")
                    .foregroundStyle(.secondary)
            }
            .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(bookmark.title)
                    .font(.body)
                    .lineLimit(1)
                Text(bookmark.url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if !bookmark.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(bookmark.tags.sorted(), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.15), in: Capsule())
                    }
                }
            }

            if let status, status.isDead {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .help("This link may be broken")
            }
        }
        .padding(.vertical, 2)
    }

    /// Fetches the favicon directly from the bookmarked site itself, never through a
    /// third-party favicon service — routing every bookmarked domain through someone
    /// else's endpoint would leak the user's bookmark list to that third party.
    private var faviconURL: URL? {
        guard var components = URLComponents(url: bookmark.url, resolvingAgainstBaseURL: false) else { return nil }
        components.path = "/favicon.ico"
        components.query = nil
        components.fragment = nil
        return components.url
    }
}
