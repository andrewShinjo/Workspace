//
//  OutlinerDocument.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/17/26.
//

import AppKit
import Combine
import Foundation

class OutlinerDocument {
	
	let rootNode: OutlinerNode
	let objectDidChange = PassthroughSubject<Void, Never>()
	
	init(rootNode: OutlinerNode) {
		self.rootNode = rootNode
	}
	
	func updateNodeText(_ node: OutlinerNode, text: String) {
		node.text = text
		objectDidChange.send()
	}
	
	func indentNode(_ node: OutlinerNode) {
		
		// If the node is root, can't indent.
		guard let parent = node.parent else {
			return
		}
		
		guard let index = parent.children.firstIndex(where: {
			$0.id == node.id
		})
		else {
			return
		}
		
		if index == 0 {
			return
		}
		
		parent.children.remove(at: index)
		
		let newParent = parent.children[index - 1]
		newParent.children.append(node)
		node.parent = newParent
		objectDidChange.send()
	}
	
	func unindentNode(_ node: OutlinerNode) {
		
		// If the node is root, can't unindent.
		guard let parent = node.parent
		else {
			return
		}
		
		// If the parent is root, can't unindent.
		guard let grandparent = parent.parent
		else {
			return
		}
		
		guard let currentIndex = parent.children.firstIndex(where: {
			$0.id == node.id
		})
		else {
			return
		}
		
		// Remove the node from it's current parent's children list.
		parent.children.remove(at: currentIndex)
		
		// Add the node to the grandparent's children list.
		guard let parentCurrentIndex = grandparent.children.firstIndex(where: {
			$0.id == parent.id
		})
		else {
			return
		}
		
		grandparent.children.insert(node, at: parentCurrentIndex + 1)
		
		// Update the node's new parent.
		node.parent = grandparent
		objectDidChange.send()
	}
	
	func mergeNode(_ node: OutlinerNode) {
		
		guard let parent = node.parent else {
			return
		}
		
		guard let index = parent.children.firstIndex(where: {
			$0.id == node.id
		}) else {
			return
		}
				
		if index == 0 {
			parent.text += node.text
		}
		else {
			let previousSibling = parent.children[index - 1]
			previousSibling.text += node.text
		}
		
		parent.children.remove(at: index)
		objectDidChange.send()
	}
	
	@discardableResult
	func splitNode(after node: OutlinerNode, in textView: NSTextView)
	-> (parent: OutlinerNode, index: Int) {
		defer { objectDidChange.send() }
		
		let isRoot = node.isRoot()
		let selectedRange = textView.selectedRange()
		let text = node.text
		let startIndex = String.Index(utf16Offset: selectedRange.location, in: text)
		
		let newNode: OutlinerNode
		
		if selectedRange.length > 0 {
			let endIndex = String.Index(utf16Offset: selectedRange.location + selectedRange.length, in: text)
			let leftPart = text.prefix(upTo: startIndex)
			let rightPart = text.suffix(from: endIndex)
			node.text = String(leftPart + rightPart)
			newNode = OutlinerNode(text: "")
		} else {
			let rightSubstring = text.suffix(from: startIndex)
			node.text = String(text.prefix(upTo: startIndex))
			newNode = OutlinerNode(text: String(rightSubstring))
		}
		
		if isRoot {
			node.children.insert(newNode, at: 0)
			newNode.parent = node
			return (node, 0)
		}
		else {
			guard let parent = node.parent,
						let index = parent.children.firstIndex(where: { $0.id == node.id }) else {
				fatalError("Node has no parent or not found in parent's children")
			}
			
			let insertIndex = index + 1
			parent.children.insert(newNode, at: insertIndex)
			newNode.parent = parent
			return (parent: parent, index: insertIndex)
		}
	}
}
