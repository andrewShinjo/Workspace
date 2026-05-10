//
//  ContentView.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/11/26.
//

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

	var body: some View {
		PanelView(
			rootPanel: panelVM.rootPanel,
			leafContent: { id, tabItem in
				ZStack {
					(id == Self.tealLeaf ? Color.teal.opacity(0.2) :
						id == Self.indigoLeaf ? Color.indigo.opacity(0.2) :
						Color.orange.opacity(0.2))
					Text(tabItem.title)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			},
			selectTab: { panelVM.selectTab(panelId: $0, at: $1) },
			closeTab: { panelVM.closeTab(panelId: $0, at: $1) },
			addTab: { panelVM.addTab(to: $0) }
		)
	}
}

#Preview {
	ContentView(showCommandPalette: .constant(false), showFlashcardPane: .constant(false), workspace: Workspace())
}
