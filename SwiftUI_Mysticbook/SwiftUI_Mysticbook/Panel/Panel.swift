//
//  Panel.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 5/6/26.
//

import Combine
import Foundation
import SwiftUI

// MARK: - Split Direction

enum SplitDirection {
	case horizontal
	case vertical
}

// MARK: - Panel Model

indirect enum PanelModel: Equatable {
	case leaf(id: UUID, tabs: [TabItem], selectedTabIndex: Int)
	case split(
		id: UUID,
		direction: SplitDirection,
		first: PanelModel,
		second: PanelModel,
		fraction: CGFloat
	)

	var id: UUID {
		switch self {
		case .leaf(let id, _, _):
			return id
		case .split(let id, _, _, _, _):
			return id
		}
	}
}

extension PanelModel {
	static func leaf(id: UUID) -> PanelModel {
		.leaf(id: id, tabs: [TabItem(id: id, title: "Untitled")], selectedTabIndex: 0)
	}
}

// MARK: - Panel Tree Operations

extension PanelModel {

	/// Removes a leaf panel from the panel tree.
	func removeLeaf(panelId: UUID) -> PanelModel {
		switch self {
		case .leaf(let id, _, _):
			if id == panelId {
				return .leaf(id: UUID())
			}
			return self
		case .split(let id, let direction, let first, let second, let fraction):
			if case .leaf(let firstId, _, _) = first, firstId == panelId {
				return second
			}
			if case .leaf(let secondId, _, _) = second, secondId == panelId {
				return first
			}
			let newFirst = first.removeLeaf(panelId: panelId)
			let newSecond = second.removeLeaf(panelId: panelId)
			if newFirst == first && newSecond == second {
				return self
			}
			return .split(id: id, direction: direction, first: newFirst, second: newSecond, fraction: fraction)
		}
	}

	func splitLeaf(panelId: UUID, direction: SplitDirection) -> PanelModel {
		switch self {
		case .leaf(let id, let tabs, let selectedIndex):
			if id == panelId {
				return .split(
					id: UUID(),
					direction: direction,
					first: .leaf(id: id, tabs: tabs, selectedTabIndex: selectedIndex),
					second: .leaf(id: UUID()),
					fraction: 0.5
				)
			}
			return self
		case .split(let id, let direction, let first, let second, let fraction):
			let newFirst = first.splitLeaf(panelId: panelId, direction: direction)
			let newSecond = second.splitLeaf(panelId: panelId, direction: direction)
			if newFirst == first && newSecond == second {
				return self
			}
			return .split(id: id, direction: direction, first: newFirst, second: newSecond, fraction: fraction)
		}
	}

	func updateSplit(panelId: UUID, fraction: CGFloat) -> PanelModel {
		switch self {
		case .leaf:
			return self
		case .split(let id, let direction, let first, let second, let _):
			if id == panelId {
				return .split(id: id, direction: direction, first: first, second: second, fraction: fraction)
			}
			let newFirst = first.updateSplit(panelId: panelId, fraction: fraction)
			let newSecond = second.updateSplit(panelId: panelId, fraction: fraction)
			if newFirst == first && newSecond == second {
				return self
			}
			return .split(id: id, direction: direction, first: newFirst, second: newSecond, fraction: fraction)
		}
	}

	// MARK: - Tab Operations

	func selectTab(in panelId: UUID, at index: Int) -> PanelModel {
		switch self {
		case .leaf(let id, let tabs, _):
			guard id == panelId, index < tabs.count else { return self }
			return .leaf(id: id, tabs: tabs, selectedTabIndex: index)
		case .split(let id, let direction, let first, let second, let fraction):
			let newFirst = first.selectTab(in: panelId, at: index)
			let newSecond = second.selectTab(in: panelId, at: index)
			if newFirst == first && newSecond == second {
				return self
			}
			return .split(id: id, direction: direction, first: newFirst, second: newSecond, fraction: fraction)
		}
	}

	func closeTab(in panelId: UUID, at index: Int) -> PanelModel {
		switch self {
		case .leaf(let id, let tabs, let selectedIndex):
			guard id == panelId, index < tabs.count else { return self }
			if tabs.count > 1 {
				var newTabs = tabs
				newTabs.remove(at: index)
				let newSelected: Int
				if selectedIndex >= newTabs.count {
					newSelected = newTabs.count - 1
				} else if selectedIndex > index {
					newSelected = selectedIndex - 1
				} else {
					newSelected = selectedIndex
				}
				return .leaf(id: id, tabs: newTabs, selectedTabIndex: newSelected)
			}
			return .leaf(id: UUID())
		case .split(let id, let direction, let first, let second, let fraction):
			let newFirst = first.closeTab(in: panelId, at: index)
			let newSecond = second.closeTab(in: panelId, at: index)
			if newFirst == first && newSecond == second {
				return self
			}
			return .split(id: id, direction: direction, first: newFirst, second: newSecond, fraction: fraction)
		}
	}

	func addTab(to panelId: UUID, tab: TabItem) -> PanelModel {
		switch self {
		case .leaf(let id, let tabs, let selectedIndex):
			guard id == panelId else { return self }
			return .leaf(id: id, tabs: tabs + [tab], selectedTabIndex: selectedIndex)
		case .split(let id, let direction, let first, let second, let fraction):
			let newFirst = first.addTab(to: panelId, tab: tab)
			let newSecond = second.addTab(to: panelId, tab: tab)
			if newFirst == first && newSecond == second {
				return self
			}
			return .split(id: id, direction: direction, first: newFirst, second: newSecond, fraction: fraction)
		}
	}
}

// MARK: - Panel View

struct PanelView<Content: View>: View {
	let rootPanel: PanelModel
	@ViewBuilder let leafContent: (UUID, TabItem) -> Content
	let closePanel: (UUID) -> Void
	let selectTab: (UUID, Int) -> Void
	let closeTab: (UUID, Int) -> Void
	let addTab: (UUID) -> Void

	init(
		rootPanel: PanelModel,
		@ViewBuilder leafContent: @escaping (UUID, TabItem) -> Content,
		closePanel: @escaping (UUID) -> Void = { _ in },
		selectTab: @escaping (UUID, Int) -> Void = { _, _ in },
		closeTab: @escaping (UUID, Int) -> Void = { _, _ in },
		addTab: @escaping (UUID) -> Void = { _ in }
	) {
		self.rootPanel = rootPanel
		self.leafContent = leafContent
		self.closePanel = closePanel
		self.selectTab = selectTab
		self.closeTab = closeTab
		self.addTab = addTab
	}

	var body: some View {
		switch rootPanel {
		case .leaf(let id, let tabs, let selectedTabIndex):
			leafView(id: id, tabs: tabs, selectedTabIndex: selectedTabIndex)
				.id(id)
		case .split(let id, let direction, let first, let second, let fraction):
			splitView(id: id, direction: direction, first: first, second: second, fraction: fraction)
		}
	}

	@ViewBuilder
	func leafView(id: UUID, tabs: [TabItem], selectedTabIndex: Int) -> some View {
		VStack(spacing: 0) {
			tabBar(id: id, tabs: tabs, selectedTabIndex: selectedTabIndex)
			if tabs.indices.contains(selectedTabIndex) {
				leafContent(id, tabs[selectedTabIndex])
					.frame(maxWidth: .infinity, maxHeight: .infinity)
			}
		}
	}

	@ViewBuilder
	func tabBar(id: UUID, tabs: [TabItem], selectedTabIndex: Int) -> some View {
		HStack(spacing: 0) {
			ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
				tabButton(panelId: id, tab: tab, isSelected: index == selectedTabIndex, index: index)
			}
			addTabButton(panelId: id)
			Spacer(minLength: 0)
		}
		.frame(height: 30)
		.background(.regularMaterial)
	}

	@ViewBuilder
	func tabButton(panelId: UUID, tab: TabItem, isSelected: Bool, index: Int) -> some View {
		HStack(spacing: 4) {
			Text(tab.title)
				.font(.caption)
				.lineLimit(1)
				.foregroundColor(isSelected ? .primary : .secondary)
				.onTapGesture { selectTab(panelId, index) }

			if isSelected {
				Text("[X]")
					.font(.caption2)
					.foregroundColor(.secondary)
					.onTapGesture { closeTab(panelId, index) }
			}
		}
		.padding(.horizontal, 8)
		.padding(.vertical, 4)
		.background(isSelected ? Color(.windowBackgroundColor) : Color.clear)
		.onTapGesture { selectTab(panelId, index) }
	}

	@ViewBuilder
	func addTabButton(panelId: UUID) -> some View {
		Text("[+]")
			.font(.caption)
			.foregroundColor(.secondary)
			.padding(.horizontal, 6)
			.onTapGesture { addTab(panelId) }
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
						closePanel: closePanel,
						selectTab: selectTab,
						closeTab: closeTab,
						addTab: addTab
					)
					.frame(width: firstSize, height: geo.size.height)
					PanelView(
						rootPanel: second,
						leafContent: leafContent,
						closePanel: closePanel,
						selectTab: selectTab,
						closeTab: closeTab,
						addTab: addTab
					)
					.frame(width: secondSize, height: geo.size.height)
				}
			}
			else {
				VStack(spacing: 0) {
					PanelView(
						rootPanel: first,
						leafContent: leafContent,
						closePanel: closePanel,
						selectTab: selectTab,
						closeTab: closeTab,
						addTab: addTab
					)
					.frame(width: geo.size.width, height: firstSize)
					PanelView(
						rootPanel: second,
						leafContent: leafContent,
						closePanel: closePanel,
						selectTab: selectTab,
						closeTab: closeTab,
						addTab: addTab
					)
					.frame(width: geo.size.width, height: secondSize)
				}
			}
		}
	}
}

// MARK: - Panel View Model

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

	// MARK: - Tab Actions

	func selectTab(panelId: UUID, at index: Int) {
		rootPanel = rootPanel.selectTab(in: panelId, at: index)
	}

	func closeTab(panelId: UUID, at index: Int) {
		rootPanel = rootPanel.closeTab(in: panelId, at: index)
	}

	func addTab(to panelId: UUID) {
		let tab = TabItem(id: UUID(), title: "New Tab")
		rootPanel = rootPanel.addTab(to: panelId, tab: tab)
	}
}
