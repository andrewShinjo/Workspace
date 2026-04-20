//
//  ContentView.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/11/26.
//

import SwiftUI

struct ContentView: View {
	
	@State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
	@State private var focused = Set<UUID>()
	
	let rootNode = OutlinerNode(
	 text: "Root node",
	 children: [OutlinerNode(text: "Child")]
 )
	 
		
	var body: some View {
		NavigationSplitView(columnVisibility: $columnVisibility) {
			List {
				Label("NavigationSplitView", systemImage: "list.bullet")
			}
		} detail: {
			Outliner(document: OutlinerDocument(rootNode: rootNode))
		}
		
	}
}

#Preview {
	ContentView()
}
