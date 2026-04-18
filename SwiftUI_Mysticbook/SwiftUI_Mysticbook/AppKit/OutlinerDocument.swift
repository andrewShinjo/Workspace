//
//  OutlinerDocument.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/17/26.
//

import AppKit
import Foundation
class OutlinerDocument {
	
	let rootNode: OutlinerNode
	
	init(rootNode: OutlinerNode) {
		self.rootNode = rootNode
	}
	
	@discardableResult
	func splitNode(after node: OutlinerNode, in textView: NSTextView) -> OutlinerNode {
		
		let isRoot = node.isRoot()
		let selectedRange = textView.selectedRange()
		let utf16Offset = selectedRange.location
		let text = node.text
		let splitIndex = String.Index(utf16Offset: utf16Offset, in: text)
		
		// Get the left and right side of node's string
		let leftSubstring = node.text.prefix(upTo: splitIndex)
		let rightSubstring = node.text.suffix(from: splitIndex)
		
		node.text = String(leftSubstring)
		let newNode = OutlinerNode(text: String(rightSubstring))
		
		if isRoot {
			node.children.insert(newNode, at: 0)
			newNode.parent = node
		}
		else {
			if let parent = node.parent,
				 let index = parent.children.firstIndex(where: { $0.id == node.id }) {
				parent.children.insert(newNode, at: index + 1)
				newNode.parent = parent
			}
		}
			
		return newNode
	}
}
