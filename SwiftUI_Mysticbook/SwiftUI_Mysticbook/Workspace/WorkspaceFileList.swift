import SwiftUI
import UniformTypeIdentifiers

struct WorkspaceFileList: View {
    @ObservedObject var workspace: Workspace
    @State private var selectedURL: URL?
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var renamingURL: URL?

    var body: some View {
        if workspace.directoryURL == nil {
            emptyState
        } else if workspace.fileItems.isEmpty {
            emptyWorkspaceState
        } else {
            fileList
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No Workspace Open")
                .font(.headline)
            Text("Choose a folder containing .org files to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Choose Folder\u{2026}") {
                chooseDirectory()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Workspace")
    }

    @ViewBuilder
    private var emptyWorkspaceState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.badge.plus")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Empty Workspace")
                .font(.headline)
            Text("No .org files found in this workspace.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("New File", systemImage: "plus") {
                workspace.createNewFile()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(workspace.directoryURL?.lastPathComponent ?? "Workspace")
    }

    private var fileList: some View {
        List(workspace.fileItems, children: \.children, selection: $selectedURL) { item in
            if item.isDirectory {
                Label(item.name, systemImage: "folder")
                    .selectionDisabled(true)
            } else {
                Label(item.name, systemImage: "doc.text")
                    .contextMenu {
                        Button("Rename\u{2026}") {
                            renamingURL = item.url
                            renameText = item.name.replacingOccurrences(of: ".org", with: "")
                            showRenameAlert = true
                        }
                    }
            }
        }
        .onChange(of: selectedURL) { _, newValue in
            guard let url = newValue else { return }
            workspace.selectFile(at: url)
        }
        .alert("Rename File", isPresented: $showRenameAlert) {
            TextField("File name", text: $renameText)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                if let url = renamingURL {
                    workspace.renameFile(at: url, to: renameText)
                }
            }
        }
        .navigationTitle(workspace.directoryURL?.lastPathComponent ?? "Workspace")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New File", systemImage: "plus") {
                    workspace.createNewFile()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Choose Folder", systemImage: "folder") {
                    chooseDirectory()
                }
            }
        }
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a workspace directory"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                workspace.setDirectory(url)
            }
        }
    }
}
