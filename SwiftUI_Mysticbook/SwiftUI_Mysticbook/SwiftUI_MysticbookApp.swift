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
	@State private var document = loadDocument()

	var body: some Scene {
			WindowGroup {
				ContentView(showCommandPalette: $showCommandPalette, document: $document)
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

private let fileURL = URL.homeDirectory
	.appending(component: "Documents")
	.appending(component: "test.org")

private func loadDocument() -> OutlinerDocument {
	if let text = try? String(contentsOf: fileURL, encoding: .utf8) {
		return orgDeserialize(text)
	}
	let doc = OutlinerDocument(
		rootNode: OutlinerNode(
			text: "My Document",
			children: [OutlinerNode(text: "New heading")]
		)
	)
	try? orgSerialize(doc).write(to: fileURL, atomically: true, encoding: .utf8)
	return doc
}

func autoSave(document: OutlinerDocument) {
	let text = orgSerialize(document)
	DispatchQueue.global(qos: .background).async {
		try? text.write(to: fileURL, atomically: true, encoding: .utf8)
	}
}
