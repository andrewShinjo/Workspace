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

}
