import Foundation

struct FileTreeScanner {
    private let fileService: FileSystemServiceProtocol

    init(fileService: FileSystemServiceProtocol = FileSystemService()) {
        self.fileService = fileService
    }

    func scan(directory url: URL) throws -> [FileItem] {
        let contents = try fileService.contentsOfDirectory(at: url)
        var items: [FileItem] = []
        for childURL in contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let resourceValues = try childURL.resourceValues(forKeys: [.isDirectoryKey])
            if resourceValues.isDirectory == true {
                let subitems = try scan(directory: childURL)
                items.append(FileItem(url: childURL, children: subitems))
            } else if childURL.pathExtension == "org" {
                items.append(FileItem(url: childURL))
            }
        }
        return items
    }
}
