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
	@StateObject var workspace: Workspace

	var body: some View {

		ZStack {
			NavigationSplitView(columnVisibility: $columnVisibility) {
				WorkspaceFileList(workspace: workspace)
			} detail: {
				if let doc = workspace.currentDocument {
					Outliner(document: doc, saveURL: workspace.currentFileURL)
				} else {
					ContentUnavailableView(
						"Select a File",
						systemImage: "doc.text",
						description: Text("Choose an Org file from the sidebar.")
					)
				}
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
	ContentView(showCommandPalette: .constant(false), workspace: Workspace())
}
