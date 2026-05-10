import SwiftUI

struct ContentView: View {

	@Binding var showCommandPalette: Bool
	@Binding var showFlashcardPane: Bool
	@StateObject var workspace: Workspace

	@StateObject private var panelVM = PanelViewModel()

	@State private var tabDocuments: [UUID: OutlinerDocument] = [:]
	@State private var tabDocumentURLs: [UUID: URL] = [:]
	@State private var documentRegistry: [URL: OutlinerDocument] = [:]
	@State private var tabDragState = TabDragState()

	var body: some View {
			ZStack {
			PanelView(
				rootPanel: panelVM.rootPanel,
				activePanelId: panelVM.activePanelId,
				leafContent: { id, tabItem in
					if let document = tabDocuments[tabItem.id] {
						Outliner(document: document, saveURL: tabDocumentURLs[tabItem.id])
							.id(tabItem.id)
					} else {
						Text(tabItem.title)
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				},
				selectTab: { panelVM.selectTab(panelId: $0, at: $1) },
				closeTab: { panelId, index in
					if let leaf = panelVM.rootPanel.findLeaf(panelId: panelId),
					   index < leaf.tabs.count {
						let oldId = leaf.tabs[index].id
						tabDocuments.removeValue(forKey: oldId)
						tabDocumentURLs.removeValue(forKey: oldId)
					}
					panelVM.closeTab(panelId: panelId, at: index)
				},
				addTab: { panelVM.addTab(to: $0) },
				resizeSplit: { panelVM.resize(splitId: $0, newFraction: $1) },
				onFocusPanel: { panelVM.activePanelId = $0 },
				moveTab: { panelVM.moveTab(from: $0, at: $1, to: $2, at: $3) },
				moveTabToSplit: { panelVM.moveTabToSplit(from: $0, at: $1, to: $2, direction: $3, tabInFirst: $4) },
				dragState: tabDragState
			)

			if showCommandPalette {
				CommandPaletteView(
					isPresented: $showCommandPalette,
					files: workspace.fileItems,
					workspaceDirectoryURL: workspace.directoryURL,
					onSelectFile: openFileInActivePanel
				)
			}

			Button("") {
				createNewUntitledTab()
			}
			.keyboardShortcut("n", modifiers: .command)
			.opacity(0)
			.frame(width: 0, height: 0)

			Button("") {
				let panelId = panelVM.activePanelId ?? panelVM.rootPanel.firstLeafId()
				if let panelId { panelVM.addTab(to: panelId) }
			}
			.keyboardShortcut("t", modifiers: .command)
			.opacity(0)
			.frame(width: 0, height: 0)

			Button("") {
				guard let panelId = panelVM.activePanelId ?? panelVM.rootPanel.firstLeafId(),
					  let leaf = panelVM.rootPanel.findLeaf(panelId: panelId) else { return }
				let index = leaf.selectedTabIndex
				let oldId = leaf.tabs[index].id
				tabDocuments.removeValue(forKey: oldId)
				tabDocumentURLs.removeValue(forKey: oldId)
				panelVM.closeTab(panelId: panelId, at: index)
			}
			.keyboardShortcut("w", modifiers: .command)
			.opacity(0)
			.frame(width: 0, height: 0)
		}
		.onAppear {
			workspace.restoreSavedDirectory()
			restorePanelState()
		}
		.onChange(of: panelVM.rootPanel) { _ in
			savePanelState()
		}
		.onChange(of: tabDocumentURLs) { _ in
			savePanelState()
		}
		.onChange(of: workspace.directoryURL) { _ in
			restorePanelState()
		}
	}

	private func createNewUntitledTab() {
		guard let panelId = panelVM.activePanelId ?? panelVM.rootPanel.firstLeafId() else { return }

		let existingTitles = panelVM.rootPanel.allTabTitles()

		var index = 0
		let baseName = "Untitled"
		var candidate: String
		repeat {
			let suffix = index == 0 ? "" : " \(index)"
			candidate = "\(baseName)\(suffix).org"
			index += 1
		} while existingTitles.contains(candidate) || fileExistsOnDisk(candidate)

		let document = OutlinerDocument(rootNode: OutlinerNode(text: ""))
		let tabId = panelVM.addTab(to: panelId, title: candidate)
		tabDocuments[tabId] = document
	}

	private func fileExistsOnDisk(_ filename: String) -> Bool {
		guard let dir = workspace.directoryURL else { return false }
		let url = dir.appendingPathComponent(filename)
		return FileManager.default.fileExists(atPath: url.path)
	}

	private func openFileInActivePanel(_ url: URL) {
		let document: OutlinerDocument
		if let existing = documentRegistry[url] {
			document = existing
		} else {
			guard let newDoc = try? orgDeserialize(String(contentsOf: url)) else { return }
			documentRegistry[url] = newDoc
			document = newDoc
		}

		let panelId = panelVM.activePanelId ?? panelVM.rootPanel.firstLeafId()
		guard let panelId else { return }

		guard let leaf = panelVM.rootPanel.findLeaf(panelId: panelId) else { return }
		let tabIndex = leaf.selectedTabIndex
		let oldTabId = leaf.tabs[tabIndex].id

		tabDocuments.removeValue(forKey: oldTabId)
		tabDocumentURLs.removeValue(forKey: oldTabId)

		let newTabId = UUID()
		let tab = TabItem(id: newTabId, title: url.lastPathComponent)

		tabDocuments[newTabId] = document
		tabDocumentURLs[newTabId] = url

		panelVM.replaceTab(in: panelId, at: tabIndex, with: tab)
	}

	private func restorePanelState() {
		guard let dir = workspace.directoryURL else { return }
		let stateURL = dir.appendingPathComponent(".mysticbook_state")
		guard FileManager.default.fileExists(atPath: stateURL.path) else { return }

		guard let tabFiles = try? panelVM.restoreState(from: stateURL) else { return }

		for (tabId, relativePath) in tabFiles {
			let url = dir.appendingPathComponent(relativePath)
			guard FileManager.default.fileExists(atPath: url.path) else { continue }
			guard let document = try? orgDeserialize(String(contentsOf: url)) else { continue }
			tabDocuments[tabId] = document
			tabDocumentURLs[tabId] = url
			documentRegistry[url] = document
		}

		populateUntitledTabDocuments()
	}

	private func populateUntitledTabDocuments() {
		func populate(_ panel: PanelModel) {
			switch panel {
			case .leaf(_, let tabs, _):
				for tab in tabs where tabDocuments[tab.id] == nil {
					tabDocuments[tab.id] = OutlinerDocument(rootNode: OutlinerNode(text: ""))
				}
			case .split(_, _, let first, let second, _):
				populate(first)
				populate(second)
			}
		}
		populate(panelVM.rootPanel)
	}

	private func savePanelState() {
		guard let dir = workspace.directoryURL else { return }
		let stateURL = dir.appendingPathComponent(".mysticbook_state")

		let basePath = dir.path.hasSuffix("/") ? dir.path : dir.path + "/"
		var tabFiles: [UUID: String] = [:]
		for (tabId, url) in tabDocumentURLs {
			let filePath = url.path
			guard filePath.hasPrefix(basePath) else { continue }
			tabFiles[tabId] = String(filePath.dropFirst(basePath.count))
		}

		try? panelVM.saveState(to: stateURL, tabFiles: tabFiles)
	}
}

#Preview {
	ContentView(showCommandPalette: .constant(false), showFlashcardPane: .constant(false), workspace: Workspace())
}
