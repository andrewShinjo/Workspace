//
//  OutlinerCellView.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/26/26.
//

import AppKit

class OutlinerCellView: NSTableCellView {

	var customDisclosureButton: NSButton?

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)

		// Create a custom disclosure button
		customDisclosureButton = NSButton()
		customDisclosureButton?.bezelStyle = .disclosure
		customDisclosureButton?.setButtonType(.momentaryPushIn)
		customDisclosureButton?.title = ""
		customDisclosureButton?.target = self
		customDisclosureButton?.action = #selector(onClick)

		// Add the button to the cell
		addSubview(customDisclosureButton!)

		// Set up constraints so the button stays at the top‑left corner
		customDisclosureButton?.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			customDisclosureButton!.topAnchor.constraint(equalTo: topAnchor, constant: 0),
			customDisclosureButton!.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
			customDisclosureButton!.widthAnchor.constraint(equalToConstant: 16),
			customDisclosureButton!.heightAnchor.constraint(equalToConstant: 16)
		])
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}

	// Removed layout() override – constraints are sufficient

	@objc func onClick() {
		print("Click")
		// Here you would implement expand/collapse logic for your outline view
	}
}
