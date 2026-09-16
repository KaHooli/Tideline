import Foundation

/// A node in the bookmark tree: either a folder containing more nodes, or a leaf bookmark.
public indirect enum BookmarkNode: Identifiable, Codable, Sendable {
    case folder(BookmarkFolder)
    case bookmark(Bookmark)

    public var id: String {
        switch self {
        case .folder(let folder): return folder.id
        case .bookmark(let bookmark): return bookmark.id
        }
    }

    public var title: String {
        switch self {
        case .folder(let folder): return folder.title
        case .bookmark(let bookmark): return bookmark.title
        }
    }
}

public struct BookmarkFolder: Identifiable, Codable, Sendable {
    public var id: String
    public var title: String
    public var children: [BookmarkNode]

    public init(id: String = UUID().uuidString, title: String, children: [BookmarkNode] = []) {
        self.id = id
        self.title = title
        self.children = children
    }
}

extension BookmarkFolder {
    /// Flattens every bookmark in this folder and its subfolders, depth-first.
    public var allBookmarks: [Bookmark] {
        children.flatMap { node -> [Bookmark] in
            switch node {
            case .bookmark(let bookmark): return [bookmark]
            case .folder(let folder): return folder.allBookmarks
            }
        }
    }
}
