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
	
	var body: some Scene {
			WindowGroup {
				ContentView(showCommandPalette: $showCommandPalette)
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
