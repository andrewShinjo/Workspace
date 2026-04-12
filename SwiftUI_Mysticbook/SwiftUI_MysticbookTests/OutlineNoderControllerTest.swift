//
//  OutlineNoderControllerTest.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/11/26.
//

import Testing
@testable import SwiftUI_Mysticbook

struct OutlineNoderControllerTest {
	
	@MainActor
	@Test
	func addSiblingTest() async throws {
		
		let rootNode = OutlinerNode(content: "Node 1", children: [])
		let childNode = OutlinerNode(content: "Node 1.1")
		rootNode.children?.append(childNode)
		
		let nodeController = OutlinerNodeController(root: [rootNode])
		let result = nodeController.addSibling(
			after: childNode,
			splitIndex:childNode.content.startIndex
		)
		
		#expect(rootNode.children?.count == 2)
		#expect(result?.content == "Node 1.1")
	}
}
