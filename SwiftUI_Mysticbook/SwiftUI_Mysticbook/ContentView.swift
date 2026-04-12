//
//  ContentView.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/11/26.
//

import SwiftUI

@Observable
class OutlinerNode: Identifiable {
	let id: UUID = UUID()
	var content: String
	var children: [OutlinerNode]? = nil
	
	init(content: String, children: [OutlinerNode]? = nil) {
		self.content = content
		self.children = children
	}
}

@Observable
class OutlinerNodeController {
	
	var root: [OutlinerNode]
	
	init(root: [OutlinerNode]) {
		self.root = root
	}
	
	@discardableResult
	func addSibling(after node: OutlinerNode, splitIndex: String.Index) -> OutlinerNode? {
				
		let location = search(of: node)
		let parent = location.0
		let index = location.1
		
		let nodeNotFoundUnderRoot = (parent == nil && index == -1)
		if nodeNotFoundUnderRoot {
			return nil
		}
		
		let leftSubstring = node.content[..<splitIndex]
		let rightSubstring = node.content[splitIndex...]
		let newNode = OutlinerNode(content: String(rightSubstring))
		node.content = String(leftSubstring)
		
		let nodeIsRoot = (parent == nil && index == 0)
		if nodeIsRoot {
			print("Add child to root")
			node.children?.insert(newNode, at: 0)
		}
		else {
			print("Add sibling")
			parent!.children?.insert(newNode, at: index + 1)
		}
		
		return newNode
	}
	
	private func search(of target: OutlinerNode) -> (OutlinerNode?, Int) {
		
		if root[0] === target {
			return (nil, 0)
		}
		
		var stack = root
		
		while !stack.isEmpty {
			let popped = stack.popLast()
			if let index = popped!.children?.firstIndex(where: {
				$0.id == target.id
			}) {
				return (popped, index)
			}
			if let children = popped!.children {
				stack.append(contentsOf: children)
			}
		}
		
		return (nil, -1)
	}
}

struct OutlinerRow: View {
	
	@Binding var outlinerNode: OutlinerNode
	let isFocused: Bool
	
	// Callbacks
	var onAddSibling: (OutlinerNode, String.Index) -> Void
	
	var body: some View {
		if isFocused {
			focusedView
		}
		else {
			defaultView
		}
	}
	
	private var focusedView: some View {
		TextField(
			"Node contents",
			text: $outlinerNode.content
		)
		.onSubmit {
			onAddSibling(outlinerNode, outlinerNode.content.startIndex)
		}
	}
	private var defaultView: some View {
		Text(outlinerNode.content)
	}
}

/// Responsibilities:
/// Rendering the entire outliner.
/// Deciding who is focused.
struct ContentView: View {
	
	@State private var nodeController = OutlinerNodeController(root:[
			OutlinerNode(
				content: "Node 1",
				children: [
					OutlinerNode(
						content: "Node 1.1",
					)
				]
			)
	])
	
	@State private var focused = Set<UUID>()
		
	var body: some View {
		List($nodeController.root, children: \.children, selection: $focused) {
			node in OutlinerRow(
				outlinerNode: node,
				isFocused: focused.contains(node.id),
				onAddSibling: {
					node, index in nodeController.addSibling(after:node, splitIndex: index)
				}
			)
		}
	}
}

#Preview {
	ContentView()
}
