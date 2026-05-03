//
//  SwiftUI_MysticbookApp.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/11/26.
//

import SwiftUI

@main
struct SwiftUI_MysticbookApp: App {

	@State private var showCommandPalette = false
	@StateObject private var workspace = Workspace()

	var body: some Scene {
			WindowGroup {
				ContentView(showCommandPalette: $showCommandPalette, workspace: workspace)
					.onAppear {
						DispatchQueue.main.async {
							workspace.restoreSavedDirectory()
						}
					}
			}
			.commands {
				CommandGroup(before: .help) {
					Button("Open Command Palette") {
						showCommandPalette.toggle()
					}
					.keyboardShortcut("/", modifiers: .command)
				}
			}
	}
}

func autoSave(document: OutlinerDocument, to url: URL) {
	let text = orgSerialize(document)
	DispatchQueue.global(qos: .background).async {
		try? text.write(to: url, atomically: true, encoding: .utf8)
	}
}
