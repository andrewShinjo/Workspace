//
//  ContentView.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/11/26.
//

import SwiftUI

struct ContentView: View {

	@State private var columnVisibility = NavigationSplitViewVisibility.all
	@Binding var showCommandPalette: Bool
	@Binding var showFlashcardPane: Bool
	@StateObject var workspace: Workspace
	@State private var flashcardDeck = FlashcardDeck()
	private static let tealLeaf = UUID()
	private static let indigoLeaf = UUID()
	private static let orangeLeaf = UUID()

	@State private var rootPanel: PanelModel = .split(
		id: UUID(),
		direction: .horizontal,
		first: .leaf(id: ContentView.tealLeaf),
		second: .split(
			id: UUID(),
			direction: .vertical,
			first: .leaf(id: indigoLeaf),
			second: .leaf(id: orangeLeaf),
			fraction: 0.5
		),
		fraction: 0.4
	)

	var body: some View {
		PanelView(
			rootPanel: rootPanel,
			leafContent: { id in
				ZStack {
				(id == Self.tealLeaf ? Color.teal.opacity(0.2) :
					id == Self.indigoLeaf ? Color.indigo.opacity(0.2) :
					Color.orange.opacity(0.2))
					Text(id.uuidString.prefix(8))
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			},
			closePanel: { id in
				rootPanel = rootPanel.removeLeaf(panelId: id)
			}
		)
		
		
		

//		ZStack {
//			NavigationSplitView(columnVisibility: $columnVisibility) {
//				WorkspaceFileList(workspace: workspace)
//			} detail: {
//				if let doc = workspace.currentDocument {
//					Outliner(document: doc, saveURL: workspace.currentFileURL)
//						.toolbar {
//							ToolbarItem {
//								Button {
//									showFlashcardPane.toggle()
//								} label: {
//									Label("Flashcards", systemImage: "rectangle.stack")
//								}
//							}
//						}
//				} else {
//					ContentUnavailableView(
//						"Select a File",
//						systemImage: "doc.text",
//						description: Text("Choose an Org file from the sidebar.")
//					)
//				}
//			}
//
//			if showCommandPalette {
//				CommandPaletteView(isPresented: $showCommandPalette)
//					.transition(.move(edge: .top).combined(with: .opacity))
//					.zIndex(1)
//			}
//
//			if showFlashcardPane {
//				FlashcardView(deck: flashcardDeck, isPresented: $showFlashcardPane)
//					.transition(.move(edge: .top).combined(with: .opacity))
//					.zIndex(1)
//			}
//		}
//		.animation(.spring(), value: showCommandPalette)
//		.animation(.spring(), value: showFlashcardPane)
//		.onChange(of: showFlashcardPane) { _, newValue in
//			if newValue, let doc = workspace.currentDocument {
//				flashcardDeck.load(from: doc.rootNode)
//			}
//		}
	}
}

#Preview {
	ContentView(showCommandPalette: .constant(false), showFlashcardPane: .constant(false), workspace: Workspace())
}
