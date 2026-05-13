//
//  SwiftUI_MysticbookTests.swift
//  SwiftUI_MysticbookTests
//
//  Created by Andrew Shinjo on 4/11/26.
//

import Testing
@testable import SwiftUI_Mysticbook

struct SwiftUI_MysticbookTests {

	@Test func deserializeNoTrailingNewline() {
		let input = "* A\nbody\n\n* B"
		let doc = orgDeserialize(input)
		let nodeA = doc.rootNode.children[0]
		#expect(nodeA.text == "A\nbody")
	}

	@Test func serializeTest() {
		let rootNode = OutlinerNode(
			text: "Root node",
			children: [
				OutlinerNode(text: "1"),
				OutlinerNode(text: "2"),
				OutlinerNode(text: "3"),
				OutlinerNode(text: "4"),
				OutlinerNode(text: "5"),
			]
		)
		rootNode.orgID = "ROOT-ID"
		rootNode.properties = ["CUSTOM": "root-val"]
		rootNode.children[0].orgID = "CHILD1-ID"
		rootNode.children[1].orgID = "CHILD2-ID"
		rootNode.children[2].orgID = "CHILD3-ID"
		rootNode.children[3].orgID = "CHILD4-ID"
		rootNode.children[4].orgID = "CHILD5-ID"

		let input = OutlinerDocument(rootNode: rootNode)
		let text = orgSerialize(input)
		#expect(text == "#+TITLE: Root node\n:PROPERTIES:\n:ID: ROOT-ID\n:CUSTOM: root-val\n:END:\n* 1\n:PROPERTIES:\n:ID: CHILD1-ID\n:END:\n* 2\n:PROPERTIES:\n:ID: CHILD2-ID\n:END:\n* 3\n:PROPERTIES:\n:ID: CHILD3-ID\n:END:\n* 4\n:PROPERTIES:\n:ID: CHILD4-ID\n:END:\n* 5\n:PROPERTIES:\n:ID: CHILD5-ID\n:END:\n")
	}

	@Test func deserializeWithProperties() {
		let input = "* Heading\n:PROPERTIES:\n:ID: my-test-id\n:CUSTOM_ID: foo\n:END:\nbody text\n* Next"
		let doc = orgDeserialize(input)
		let node = doc.rootNode.children[0]
		#expect(node.text == "Heading\nbody text")
		#expect(node.orgID == "my-test-id")
		#expect(node.properties["CUSTOM_ID"] == "foo")
	}

	@Test func deserializeWithoutProperties() {
		let input = "* Heading\nbody text"
		let doc = orgDeserialize(input)
		let node = doc.rootNode.children[0]
		#expect(node.text == "Heading\nbody text")
		#expect(!node.orgID.isEmpty)
	}

	@Test func deserializeRootWithProperties() {
		let input = "#+TITLE: My Document\n:PROPERTIES:\n:ID: root-id\n:END:\nIntro text\n* Heading"
		let doc = orgDeserialize(input)
		#expect(doc.rootNode.text == "My Document\nIntro text")
		#expect(doc.rootNode.orgID == "root-id")
	}
}
