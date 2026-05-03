import Foundation

struct FileItem: Hashable, Identifiable {
    let url: URL
    var children: [FileItem]?

    var id: URL { url }
    var name: String { url.lastPathComponent }
    var isDirectory: Bool { children != nil }
}
