//
//  ContentView.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/11/26.
//

import SwiftUI

struct ContentView: View {
	
	// Sets the visibility of columns in a navigation split view.
	// detailOnly means only show the detail area initially.
	@State private var columnVisibility = NavigationSplitViewVisibility.detailOnly
	
	let rootNode = OutlinerNode(
	 text: "Root node",
	 children: [OutlinerNode(text: "Child")]
 )
	 
	var body: some View {
		
		// A view that presents views in two or three columns.
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
