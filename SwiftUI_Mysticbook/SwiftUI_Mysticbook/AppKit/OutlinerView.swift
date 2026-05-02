//
//  OutlinerView.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 5/1/26.
//

import AppKit

class OutlinerView: NSOutlineView {
	
	override func makeView(
		withIdentifier identifier: NSUserInterfaceItemIdentifier,
		owner: Any?
	) -> NSView? {
	
		// Hide the default expand/collapse button as I can't figure out how to
		// control its position where I want it.
		if identifier == NSOutlineView.disclosureButtonIdentifier {
			return nil
		}
		
		return super.makeView(withIdentifier: identifier, owner: owner)
	}
}
