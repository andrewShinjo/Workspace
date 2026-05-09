//
//  Panel.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 5/6/26.
//

import Combine
import Foundation
import SwiftUI

// Panel Data

enum SplitDirection {
	case horizontal
	case vertical
}

indirect enum PanelModel {
	case leaf(id: UUID)
	case split(
		id: UUID,
		direction: SplitDirection,
		first: PanelModel,
		second: PanelModel,
		fraction: CGFloat
	)
	
	var id: UUID {
		switch self {
		case .leaf(let id):
			return id
		case .split(let id, _, _, _, _):
			return id
		}
	}
	
	/// Removes a leaf panel from the panel tree.
	/// If the leaf is a direct child of a split, its sibling takes the entire area.
	/// If the leaf is a root leaf, it's replaced by a fresh empty leaf.
	///
	/// - Parameter panelId: The unique identifier of the leaf to remove.
	/// - Returns: A new panel tree with the leaf removed.
	func removeLeaf(panelId: UUID) -> PanelModel {
		switch self {
		case .leaf(let id):
			if id == panelId {
				return .leaf(id: UUID())
			}
			else {
				return self
			}
		case .split(let id, let direction, let first, let second, let fraction):
			if case .leaf(let firstId) = first, firstId == panelId {
				return second
			}
			if case .leaf(let secondId) = second, secondId == panelId {
				return first
			}
			let newFirst = first.removeLeaf(panelId: panelId)
			let newSecond = second.removeLeaf(panelId: panelId)
			if newFirst.id == first.id && newSecond.id == second.id {
				return self
			}
			return .split(
				id: id,
				direction: direction,
				first: newFirst,
				second: newSecond,
				fraction: fraction
			)
		}
	}
	
	func splitLeaf(panelId: UUID, direction: SplitDirection) -> PanelModel {
		switch self {
		case .leaf(let id):
			if id == panelId {
				return .split(
					id: UUID(),
					direction: direction,
					first: .leaf(id: id),
					second: .leaf(id: UUID()),
					fraction: 0.5
				)
			}
			return self
		case .split(let id, let direction, let first, let second, let fraction):
			let newFirst = first.splitLeaf(panelId: panelId, direction: direction)
			let newSecond = second.splitLeaf(panelId: panelId, direction: direction)
			if newFirst.id == first.id && newSecond.id == second.id {
				return self
			}
			return .split(
				id: id,
				direction: direction,
				first: newFirst,
				second: newSecond,
				fraction: fraction
			)
		}
	}
	
	func updateSplit(panelId: UUID, fraction: CGFloat) -> PanelModel {
		switch self {
		case .leaf:
			return self
		case .split(let id, let direction, let first, let second, let _):
			if id == panelId {
				return .split(
					id: id,
					direction: direction,
					first: first,
					second: second,
					fraction: fraction
				)
			}
			let newFirst = first.updateSplit(panelId: panelId, fraction: fraction)
			let newSecond = second.updateSplit(panelId: panelId, fraction: fraction)
			if newFirst.id == first.id && newSecond.id == second.id {
				return self
			}
			return .split(
				id: id,
				direction: direction,
				first: newFirst,
				second: newSecond,
				fraction: fraction
			)
		}
	}
}

// Panel View

struct PanelView<Content: View>: View {
	let rootPanel: PanelModel
	@ViewBuilder let leafContent: (UUID) -> Content
	let closePanel: (UUID) -> Void

	init(
		rootPanel: PanelModel,
		@ViewBuilder leafContent: @escaping (UUID) -> Content,
		closePanel: @escaping (UUID) -> Void = { _ in }
	) {
		self.rootPanel = rootPanel
		self.leafContent = leafContent
		self.closePanel = closePanel
	}
	
	var body: some View {
		switch rootPanel {
		case .leaf(let id):
			leafView(id: id).id(id)
		case .split(let id, let direction, let first, let second, let fraction):
			splitView(
				id: id,
				direction: direction,
				first: first,
				second: second,
				fraction: fraction
			)
		}
	}
	
	@ViewBuilder
	func leafView(id: UUID) -> some View {
		VStack(spacing: 0) {
			HStack {
				Spacer()
				Button(action: { closePanel(id) }) { Image(systemName: "xmark") }
				.buttonStyle(.borderless)
			}
			.padding(.horizontal, 4)
			.frame(height: 30)
			.background(.regularMaterial)
			
			leafContent(id)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
	}
	
	@ViewBuilder
	func splitView(
		id: UUID,
		direction: SplitDirection,
		first: PanelModel,
		second: PanelModel,
		fraction: CGFloat
	) -> some View {
		GeometryReader { geo in
			let total = direction == .horizontal ? geo.size.width : geo.size.height
			let firstSize = total * fraction
			let secondSize = total - firstSize
			
			if direction == .horizontal {
				HStack(spacing: 0) {
					PanelView(
						rootPanel: first,
						leafContent: leafContent,
						closePanel: closePanel
					)
						.frame(width: firstSize, height: geo.size.height)
					PanelView(
						rootPanel: second,
						leafContent: leafContent,
						closePanel: closePanel
					)
						.frame(width: secondSize, height: geo.size.height)
				}
			}
			else {
				VStack(spacing: 0) {
					PanelView(
						rootPanel: first,
						leafContent: leafContent,
						closePanel: closePanel
					)
						.frame(width: geo.size.width, height: firstSize)
					PanelView(
						rootPanel: second,
						leafContent: leafContent,
						closePanel: closePanel
					)
						.frame(width: geo.size.width, height: secondSize)
				}
			}
		}
		.id(id)
	}
}

// View Model

class PanelViewModel: ObservableObject {
	@Published var rootPanel: PanelModel = .leaf(id: UUID())
	
	func close(panelId: UUID) {
		rootPanel = rootPanel.removeLeaf(panelId: panelId)
	}
	
	func split(panelId: UUID, direction: SplitDirection) {
		rootPanel = rootPanel.splitLeaf(panelId: panelId, direction: direction)
	}
	
	func resize(splitId: UUID, newFraction: CGFloat) {
		rootPanel = rootPanel.updateSplit(panelId: splitId, fraction: newFraction)
	}
}
