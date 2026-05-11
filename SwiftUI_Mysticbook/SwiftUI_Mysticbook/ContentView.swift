import SwiftUI

private struct SidebarButtonBar: View {
	let onOpenFlashcards: () -> Void

	var body: some View {
		VStack(spacing: 0) {
			Button(action: onOpenFlashcards) {
				Image(systemName: "rectangle.on.rectangle")
					.font(.system(size: 13, weight: .medium))
			}
			.buttonStyle(.plain)
			.foregroundColor(.secondary)
			.padding(.top, 10)

			Spacer()
		}
		.frame(width: 24)
		.frame(maxHeight: .infinity)
		.background {
			Color(nsColor: .windowBackgroundColor)
		}
		.overlay(alignment: .trailing) {
			Rectangle()
				.fill(Color(nsColor: .separatorColor))
				.frame(width: 1)
		}
	}
}

private struct FlashcardTabView: View {
	let workspaceDirectoryURL: URL?

	@State private var flashcardCount = 0
	@State private var isLoading = true

	var body: some View {
		VStack(spacing: 20) {
			Image(systemName: "rectangle.on.rectangle")
				.font(.system(size: 48))
				.foregroundColor(.secondary)

			if isLoading {
				ProgressView("Scanning for flashcards...")
			} else {
				Text("Flashcards")
					.font(.title2)

				Button("Study Flashcards: \(flashcardCount)") {
					// Future: open study UI
				}
				.buttonStyle(.borderedProminent)
				.disabled(flashcardCount == 0)
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.task {
			await scanFlashcards()
		}
	}

	private func scanFlashcards() async {
		guard let directoryURL = workspaceDirectoryURL else {
			isLoading = false
			return
		}

		let count = await Task.detached { () -> Int in
			var total = 0
			guard let enumerator = FileManager.default.enumerator(
				at: directoryURL,
				includingPropertiesForKeys: nil,
				options: [.skipsHiddenFiles]
			) else { return 0 }

			while let fileURL = enumerator.nextObject() as? URL {
				guard fileURL.pathExtension == "org" else { continue }
				guard let content = try? String(contentsOf: fileURL) else { continue }
				let document = orgDeserialize(content)
				total += countFlashcards(in: document.rootNode)
			}
			return total
		}.value

		flashcardCount = count
		isLoading = false
	}

	private func countFlashcards(in node: OutlinerNode) -> Int {
		var count = FlashcardDeck.extract(from: node.text) != nil ? 1 : 0
		for child in node.children {
			count += countFlashcards(in: child)
		}
		return count
	}
}

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
		HStack(spacing: 0) {
			SidebarButtonBar(onOpenFlashcards: openFlashcards)

			ZStack {
				PanelView(
					rootPanel: panelVM.rootPanel,
					activePanelId: panelVM.activePanelId,
					leafContent: { id, tabItem in
						if tabItem.isFlashcard || tabItem.title == "Flashcards" {
							FlashcardTabView(workspaceDirectoryURL: workspace.directoryURL)
								.id(tabItem.id)
						} else if let document = tabDocuments[tabItem.id] {
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
		.onChange(of: showFlashcardPane) { newValue in
			if newValue {
				openFlashcards()
				showFlashcardPane = false
			}
		}
	}

	private func openFlashcards() {
		guard let panelId = panelVM.activePanelId ?? panelVM.rootPanel.firstLeafId() else {
			print("[openFlashcards] no active panel")
			return
		}
		guard let leaf = panelVM.rootPanel.findLeaf(panelId: panelId) else {
			print("[openFlashcards] no leaf for panel \(panelId)")
			return
		}

		print("[openFlashcards] panel \(panelId) has \(leaf.tabs.count) tabs")
		for (index, tab) in leaf.tabs.enumerated() {
			print("[openFlashcards]   tab[\(index)]: id=\(tab.id) title='\(tab.title)' isFlashcard=\(tab.isFlashcard)")
			if tab.isFlashcard || tab.title == "Flashcards" {
				print("[openFlashcards] found existing flashcard tab at index \(index), selecting it")
				panelVM.selectTab(panelId: panelId, at: index)
				return
			}
		}

		print("[openFlashcards] creating new flashcard tab")
		panelVM.addTab(to: panelId, title: "Flashcards", isFlashcard: true)
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
		guard let dir = workspace.directoryURL else {
			print("[restorePanelState] no directory URL")
			return
		}
		let stateURL = dir.appendingPathComponent(".mysticbook_state")
		guard FileManager.default.fileExists(atPath: stateURL.path) else {
			print("[restorePanelState] no state file at \(stateURL.path)")
			return
		}

		guard let tabFiles = try? panelVM.restoreState(from: stateURL) else {
			print("[restorePanelState] failed to restore state")
			return
		}
		print("[restorePanelState] restored \(tabFiles.count) file tabs")

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
					print("[populateUntitledTabDocuments] tab '\(tab.title)' has no document, leaving as placeholder")
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
