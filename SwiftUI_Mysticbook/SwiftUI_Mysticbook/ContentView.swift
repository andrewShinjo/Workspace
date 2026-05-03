//
//  ContentView.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/11/26.
//

import SwiftUI

struct ContentView: View {

	@State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
	@Binding var showCommandPalette: Bool
	@Binding var document: OutlinerDocument

	var body: some View {

		ZStack {
			NavigationSplitView(columnVisibility: $columnVisibility) {
				List {
					Label("NavigationSplitView", systemImage: "list.bullet")
				}
			} detail: {
				Outliner(document: document)
			}

			if showCommandPalette {
				CommandPaletteView(isPresented: $showCommandPalette)
					.transition(.move(edge: .top).combined(with: .opacity))
					.zIndex(1)
			}
		}
		.animation(.spring(), value: showCommandPalette)
	}
}

#Preview {
	ContentView(showCommandPalette: .constant(false), document: .constant(OutlinerDocument(
		rootNode: OutlinerNode(text: "Root node", children: [OutlinerNode(text: "Child")])
	)))
}
