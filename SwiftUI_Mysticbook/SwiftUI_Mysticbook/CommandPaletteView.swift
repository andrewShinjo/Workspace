//
//  CommandPaletteView.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/25/26.
//

import SwiftUI

struct CommandPaletteView: View {
	@Binding var isPresented: Bool
	
	var body: some View {
		VStack(spacing: 16) {
			Text("Command Palette")
					.font(.largeTitle)
			Text("Type a command…")
					.foregroundColor(.secondary)
		}
		.padding(40)
		.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
		.shadow(radius: 20)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color.black.opacity(0.2))
		.onTapGesture {
				isPresented = false
		}
	}
}
