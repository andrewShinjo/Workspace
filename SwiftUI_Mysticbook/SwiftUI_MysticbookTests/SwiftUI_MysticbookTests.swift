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
	
	// Situation:
	// Outliner in the app looked like this:
	//	- Root node
	//   	- 1
	//		- 2
  //   	- 3
	//   	- 4
	//   	- 5
	//
	// Actual serialization output:
	// #+TITLE: Root node
	// * 1
	//
	// * 2
	//
	// * 3
	//
	// * 4
	//
	// * 5
	//
	// Expected serialization output:
	// #+TITLE: Root node
	// * 1
	// * 2
	// * 3
	// * 4
	// * 5
	@Test func serializeTest() {
		let input = OutlinerDocument(
			rootNode: OutlinerNode(
				text: "Root node",
				children: [
					OutlinerNode(text: "1"),
					OutlinerNode(text: "2"),
					OutlinerNode(text: "3"),
					OutlinerNode(text: "4"),
					OutlinerNode(text: "5"),
				]
			)
		)
		
		let text = orgSerialize(input)
		#expect(text == "#+TITLE: Root node\n* 1\n* 2\n* 3\n* 4\n* 5\n")
	}

}
