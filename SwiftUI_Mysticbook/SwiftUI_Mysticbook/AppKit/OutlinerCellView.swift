//
//  OutlinerCellView.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/26/26.
//

import AppKit

class OutlinerCellView: NSTableCellView {

	var customDisclosureButton: NSButton?
	var bulletLabel: NSTextField?

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)

		// Create a custom disclosure button
		customDisclosureButton = NSButton()
		customDisclosureButton?.bezelStyle = .regularSquare
		customDisclosureButton?.isBordered = false
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

		// Bullet point label
		let bullet = NSTextField(labelWithString: "•")
		bullet.font = NSFont.systemFont(ofSize: 13)
		bullet.textColor = NSColor.secondaryLabelColor
		bullet.translatesAutoresizingMaskIntoConstraints = false
		addSubview(bullet)
		NSLayoutConstraint.activate([
			bullet.leadingAnchor.constraint(equalTo: customDisclosureButton!.trailingAnchor, constant: 4),
			bullet.topAnchor.constraint(equalTo: topAnchor),
			bullet.widthAnchor.constraint(equalToConstant: 10)
		])
		bulletLabel = bullet
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}

	func setExpanded(_ expanded: Bool) {
		let symbolName = expanded ? "chevron.down" : "chevron.right"
		let config = NSImage.SymbolConfiguration(pointSize: 11, weight: .medium)
		customDisclosureButton?.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?.withSymbolConfiguration(config)
		customDisclosureButton?.image?.isTemplate = true
	}

	@objc func onClick() {
		guard let outlineView = sequence(
			first: self as NSView?,
			next: { $0?.superview }
		).compactMap({ $0 as? NSOutlineView }).first else { return }

		let row = outlineView.row(for: self)
		guard row >= 0, let item = outlineView.item(atRow: row) else { return }

		if outlineView.isItemExpanded(item) {
			outlineView.collapseItem(item)
		} else {
			outlineView.expandItem(item)
		}

		setExpanded(outlineView.isItemExpanded(item))
	}
}
