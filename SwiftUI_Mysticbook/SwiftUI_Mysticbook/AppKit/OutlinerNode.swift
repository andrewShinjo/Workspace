//
//  OutlinerNode.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/12/26.
//

import AppKit

class OutlinerNode {
	
	let id: UUID = UUID()
	var text: String
	var children: [OutlinerNode] = []
	weak var parent: OutlinerNode?
	
	init(text: String, children: [OutlinerNode]) {
		self.text = text
		self.children = children
		children.forEach {
			$0.parent = self
		}
	}
	
	init(text: String) {
		self.text = text
	}
	
	func isRoot() -> Bool {
		return parent == nil
	}
}
