import Foundation
import Combine

final class Workspace: ObservableObject {
    @Published var directoryURL: URL?
    @Published var fileItems: [FileItem] = []
    @Published var selectedFileURL: URL?
    @Published var currentDocument: OutlinerDocument?
    @Published var currentFileURL: URL?

    private let scanner = FileTreeScanner()
    private let watcher = DirectoryWatcher()
    private var observers: Set<AnyCancellable> = []

    private static let savedPathKey = "workspaceDirectoryPath"

    // MARK: - Directory management

    func setDirectory(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: Self.savedPathKey)
        watcher.start(url: url) { [weak self] in
            DispatchQueue.main.async { self?.rebuildTree() }
        }
        DispatchQueue.main.async {
            self.directoryURL = url
            self.rebuildTree()
        }
    }

    func restoreSavedDirectory() {
        guard let path = UserDefaults.standard.string(forKey: Self.savedPathKey),
              FileManager.default.fileExists(atPath: path) else { return }
        setDirectory(URL(filePath: path))
    }

    // MARK: - File operations

    func selectFile(at url: URL) {
        guard url != currentFileURL else { return }
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
              !isDir.boolValue else { return }
        let document = try? orgDeserialize(String(contentsOf: url))
        DispatchQueue.main.async {
            self.currentFileURL = url
            self.selectedFileURL = url
            self.currentDocument = document
            if document == nil { self.currentFileURL = nil }
        }
    }

    func autoSave() {
        guard let document = currentDocument, let url = currentFileURL else { return }
        let text = orgSerialize(document)
        DispatchQueue.global(qos: .background).async {
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - File rename

    func renameFile(at url: URL, to newName: String) {
        let cleanName = newName.hasSuffix(".org") ? String(newName.dropLast(4)) : newName
        let newURL = url
            .deletingLastPathComponent()
            .appendingPathComponent(cleanName)
            .appendingPathExtension("org")
        guard url != newURL, !FileManager.default.fileExists(atPath: newURL.path) else { return }

        try? FileManager.default.moveItem(at: url, to: newURL)
        rebuildTree()

        if url == currentFileURL {
            currentFileURL = newURL
            selectedFileURL = newURL
        }
    }

    // MARK: - New file

    func createNewFile() {
        guard let directoryURL else { return }
        let fm = FileManager.default
        var index = 0
        let baseName = "untitled"
        var fileURL: URL
        repeat {
            let suffix = index == 0 ? "" : " \(index)"
            fileURL = directoryURL.appendingPathComponent("\(baseName)\(suffix).org")
            index += 1
        } while fm.fileExists(atPath: fileURL.path)

        let emptyDoc = OutlinerDocument(rootNode: OutlinerNode(text: ""))
        let content = orgSerialize(emptyDoc)
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        rebuildTree()
        selectFile(at: fileURL)
    }

    // MARK: - Private

    private func rebuildTree() {
        guard let directoryURL else { return }
        fileItems = (try? scanner.scan(directory: directoryURL)) ?? []
    }
}
