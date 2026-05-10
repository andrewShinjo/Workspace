import SwiftUI

struct ContentView: View {

	@Binding var showCommandPalette: Bool
	@Binding var showFlashcardPane: Bool
	@StateObject var workspace: Workspace

	private static let tealLeaf = UUID()
	private static let indigoLeaf = UUID()
	private static let orangeLeaf = UUID()

	@StateObject private var panelVM: PanelViewModel = {
		let vm = PanelViewModel()
		vm.rootPanel = .split(
			id: UUID(),
			direction: .horizontal,
			first: .leaf(id: ContentView.tealLeaf, tabs: [TabItem(id: UUID(), title: "Panel 1")], selectedTabIndex: 0),
			second: .split(
				id: UUID(),
				direction: .vertical,
				first: .leaf(id: ContentView.indigoLeaf, tabs: [TabItem(id: UUID(), title: "Panel 2")], selectedTabIndex: 0),
				second: .leaf(id: ContentView.orangeLeaf, tabs: [TabItem(id: UUID(), title: "Panel 3")], selectedTabIndex: 0),
				fraction: 0.5
			),
			fraction: 0.4
		)
		return vm
	}()

	@State private var tabDocuments: [UUID: OutlinerDocument] = [:]
	@State private var tabDocumentURLs: [UUID: URL] = [:]
	@State private var documentRegistry: [URL: OutlinerDocument] = [:]

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
						ZStack {
							(id == Self.tealLeaf ? Color.teal.opacity(0.2) :
								id == Self.indigoLeaf ? Color.indigo.opacity(0.2) :
								Color.orange.opacity(0.2))
							Text(tabItem.title)
								.font(.caption)
								.foregroundStyle(.secondary)
						}
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
				onFocusPanel: { panelVM.activePanelId = $0 }
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
}

#Preview {
	ContentView(showCommandPalette: .constant(false), showFlashcardPane: .constant(false), workspace: Workspace())
}
