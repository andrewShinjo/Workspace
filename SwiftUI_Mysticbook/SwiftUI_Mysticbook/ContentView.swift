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
		}
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
