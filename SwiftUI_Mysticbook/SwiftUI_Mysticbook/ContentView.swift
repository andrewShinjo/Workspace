//
//  ContentView.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/11/26.
//

import SwiftUI

struct ContentView: View {
	
	@State private var focused = Set<UUID>()
		
	var body: some View {
		Outliner(rootNodes: [
			OutlinerNode(
				text: "Root node",
				children: [OutlinerNode(text: "Child")]
			)
		])
	}
}

#Preview {
	ContentView()
}
