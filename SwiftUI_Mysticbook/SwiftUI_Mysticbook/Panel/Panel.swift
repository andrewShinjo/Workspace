//
//  Panel.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 5/6/26.
//

import Combine
import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Split Direction

enum SplitDirection {
	case horizontal
	case vertical
}

// MARK: - Tab Item

struct TabItem: Identifiable, Equatable {
	let id: UUID
	var title: String
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
		case .split(id: let id, direction: let direction, first: let first, second: let second, fraction: let originalFraction):
			if id == panelId {
				return .split(id: id, direction: direction, first: first, second: second, fraction: fraction)
			}
			let newFirst = first.updateSplit(panelId: panelId, fraction: fraction)
			let newSecond = second.updateSplit(panelId: panelId, fraction: fraction)
			if newFirst == first && newSecond == second {
				return self
			}
			return .split(id: id, direction: direction, first: newFirst, second: newSecond, fraction: originalFraction)
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
			return .leaf(id: id, tabs: [], selectedTabIndex: 0)
		case .split(let id, let direction, let first, let second, let fraction):
			let newFirst = first.closeTab(in: panelId, at: index)
			let newSecond = second.closeTab(in: panelId, at: index)

			if case .leaf(_, let ftabs, _) = newFirst, ftabs.isEmpty {
				return newSecond
			}
			if case .leaf(_, let stabs, _) = newSecond, stabs.isEmpty {
				return newFirst
			}

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

	func addTab(to panelId: UUID, tab: TabItem, at index: Int) -> PanelModel {
		print("  📥 addTab(to:\(panelId) tab:\"\(tab.title)\" at:\(index))")
		switch self {
		case .leaf(let id, let tabs, _):
			guard id == panelId else {
				print("    ❌ leaf id=\(id) doesn't match dest \(panelId)")
				return self
			}
			var newTabs = tabs
			newTabs.insert(tab, at: min(index, tabs.count))
			print("    ✅ inserted into leaf \(id), tabs now \(newTabs.count)")
			return .leaf(id: id, tabs: newTabs, selectedTabIndex: min(index, tabs.count))
		case .split(let id, let direction, let first, let second, let fraction):
			print("    split \(id) — searching children")
			let newFirst = first.addTab(to: panelId, tab: tab, at: index)
			let newSecond = second.addTab(to: panelId, tab: tab, at: index)
			if newFirst == first && newSecond == second {
				print("    ❌ split \(id) — not found in either child")
				return self
			}
			print("    ✅ inserted into split \(id)")
			return .split(id: id, direction: direction, first: newFirst, second: newSecond, fraction: fraction)
		}
	}
}

// MARK: - Panel Model Helpers

extension PanelModel {

	func firstLeafId() -> UUID? {
		switch self {
		case .leaf(let id, _, _):
			return id
		case .split(_, _, let first, let second, _):
			return first.firstLeafId() ?? second.firstLeafId()
		}
	}

	func findLeaf(panelId: UUID) -> (tabs: [TabItem], selectedTabIndex: Int)? {
		switch self {
		case .leaf(let id, let tabs, let selectedIndex):
			return id == panelId ? (tabs, selectedIndex) : nil
		case .split(_, _, let first, let second, _):
			return first.findLeaf(panelId: panelId) ?? second.findLeaf(panelId: panelId)
		}
	}

	func allTabTitles() -> Set<String> {
		switch self {
		case .leaf(_, let tabs, _):
			return Set(tabs.map(\.title))
		case .split(_, _, let first, let second, _):
			return first.allTabTitles().union(second.allTabTitles())
		}
	}

	func replaceTab(in panelId: UUID, at index: Int, with tab: TabItem) -> PanelModel {
		switch self {
		case .leaf(let id, let tabs, let selectedIndex):
			guard id == panelId, index < tabs.count else { return self }
			var newTabs = tabs
			newTabs[index] = tab
			return .leaf(id: id, tabs: newTabs, selectedTabIndex: selectedIndex)
		case .split(let id, let direction, let first, let second, let fraction):
			let newFirst = first.replaceTab(in: panelId, at: index, with: tab)
			let newSecond = second.replaceTab(in: panelId, at: index, with: tab)
			if newFirst == first && newSecond == second {
				return self
			}
			return .split(id: id, direction: direction, first: newFirst, second: newSecond, fraction: fraction)
		}
	}

	// MARK: - Tab Movement

	func extractingTab(from sourcePanelId: UUID, at sourceIndex: Int) -> (newModel: PanelModel, tab: TabItem)? {
		print("🔍 extractingTab — looking for panelId=\(sourcePanelId) at index=\(sourceIndex)")
		switch self {
		case .leaf(let id, let tabs, let selectedIndex):
			guard id == sourcePanelId, sourceIndex < tabs.count else {
				print("  ❌ leaf id=\(id) — mismatched or bad index (tabs.count=\(tabs.count))")
				return nil
			}
			print("  ✅ FOUND in leaf \(id), tabs.count=\(tabs.count), title=\"\(tabs[sourceIndex].title)\"")
			let tab = tabs[sourceIndex]
			var newTabs = tabs
			newTabs.remove(at: sourceIndex)
			let newSelected: Int
			if newTabs.isEmpty {
				newSelected = 0
			} else if selectedIndex >= newTabs.count {
				newSelected = newTabs.count - 1
			} else if selectedIndex > sourceIndex {
				newSelected = selectedIndex - 1
			} else {
				newSelected = selectedIndex
			}
			return (.leaf(id: id, tabs: newTabs, selectedTabIndex: newSelected), tab)
		case .split(let id, let direction, let first, let second, let fraction):
			print("  split \(id) — searching first child")
			if let result = first.extractingTab(from: sourcePanelId, at: sourceIndex) {
				if case .leaf(_, let ftabs, _) = result.newModel, ftabs.isEmpty {
					print("  ⚠️ first child empty — collapsing split, returning second")
					return (second, result.tab)
				}
				return (.split(id: id, direction: direction, first: result.newModel, second: second, fraction: fraction), result.tab)
			}
			print("  split \(id) — searching second child")
			if let result = second.extractingTab(from: sourcePanelId, at: sourceIndex) {
				if case .leaf(_, let stabs, _) = result.newModel, stabs.isEmpty {
					print("  ⚠️ second child empty — collapsing split, returning first")
					return (first, result.tab)
				}
				return (.split(id: id, direction: direction, first: first, second: result.newModel, fraction: fraction), result.tab)
			}
			print("  ❌ split \(id) — not found in either child")
			return nil
		}
	}

	func moveTab(from sourcePanelId: UUID, at sourceIndex: Int, to destPanelId: UUID, at destIndex: Int) -> PanelModel {
		print("🔷 PanelModel.moveTab — src=\(sourcePanelId) idx=\(sourceIndex) dst=\(destPanelId) idx=\(destIndex)")
		guard sourcePanelId != destPanelId || sourceIndex != destIndex else {
			print("  ➡️ no-op: same panel + same index")
			return self
		}
		if sourcePanelId == destPanelId {
			print("  ➡️ same-panel reorder")
			return reorderTabs(in: sourcePanelId, from: sourceIndex, to: destIndex)
		}
		print("  ➡️ cross-panel move: extracting...")
		guard let (tempModel, tab) = extractingTab(from: sourcePanelId, at: sourceIndex) else {
			print("  ❌ extractingTab returned nil")
			return self
		}
		print("  ✅ extracted tab \"\(tab.title)\", now inserting into dest")
		return tempModel.addTab(to: destPanelId, tab: tab, at: destIndex)
	}

	private func reorderTabs(in panelId: UUID, from sourceIndex: Int, to destIndex: Int) -> PanelModel {
		switch self {
		case .leaf(let id, let tabs, let selectedIndex):
			guard id == panelId, sourceIndex < tabs.count, destIndex <= tabs.count else { return self }
			var newTabs = tabs
			let tab = newTabs.remove(at: sourceIndex)
			let adjustedDest = sourceIndex < destIndex ? destIndex - 1 : destIndex
			newTabs.insert(tab, at: min(adjustedDest, newTabs.count))
			let newSelected: Int
			if selectedIndex == sourceIndex {
				newSelected = min(adjustedDest, newTabs.count - 1)
			} else if selectedIndex > sourceIndex && selectedIndex <= adjustedDest {
				newSelected = selectedIndex - 1
			} else {
				newSelected = selectedIndex
			}
			return .leaf(id: id, tabs: newTabs, selectedTabIndex: newSelected)
		case .split(let id, let direction, let first, let second, let fraction):
			let newFirst = first.reorderTabs(in: panelId, from: sourceIndex, to: destIndex)
			let newSecond = second.reorderTabs(in: panelId, from: sourceIndex, to: destIndex)
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
	let activePanelId: UUID?
	@ViewBuilder let leafContent: (UUID, TabItem) -> Content
	let closePanel: (UUID) -> Void
	let selectTab: (UUID, Int) -> Void
	let closeTab: (UUID, Int) -> Void
	let addTab: (UUID) -> Void
	let resizeSplit: (UUID, CGFloat) -> Void
	let onFocusPanel: (UUID) -> Void
	let moveTab: (UUID, Int, UUID, Int) -> Void

	init(
		rootPanel: PanelModel,
		activePanelId: UUID? = nil,
		@ViewBuilder leafContent: @escaping (UUID, TabItem) -> Content,
		closePanel: @escaping (UUID) -> Void = { _ in },
		selectTab: @escaping (UUID, Int) -> Void = { _, _ in },
		closeTab: @escaping (UUID, Int) -> Void = { _, _ in },
		addTab: @escaping (UUID) -> Void = { _ in },
		resizeSplit: @escaping (UUID, CGFloat) -> Void = { _, _ in },
		onFocusPanel: @escaping (UUID) -> Void = { _ in },
		moveTab: @escaping (UUID, Int, UUID, Int) -> Void = { _, _, _, _ in }
	) {
		self.rootPanel = rootPanel
		self.activePanelId = activePanelId
		self.leafContent = leafContent
		self.closePanel = closePanel
		self.selectTab = selectTab
		self.closeTab = closeTab
		self.addTab = addTab
		self.resizeSplit = resizeSplit
		self.onFocusPanel = onFocusPanel
		self.moveTab = moveTab
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
					.onTapGesture { onFocusPanel(id) }
					.overlay(
						RoundedRectangle(cornerRadius: 4)
							.stroke(id == activePanelId ? Color.accentColor : Color.clear, lineWidth: 2)
					)
			}
		}
	}

	@ViewBuilder
	func tabBar(id: UUID, tabs: [TabItem], selectedTabIndex: Int) -> some View {
		HStack(spacing: 0) {
			ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
				InsertionDropZone(
					destPanelId: id,
					destIndex: index,
					moveTab: moveTab
				)
				.frame(width: 12)
				tabButton(panelId: id, tab: tab, isSelected: index == selectedTabIndex, index: index)
					.onDrag {
						let data = "\(id.uuidString):\(index)"
						return NSItemProvider(object: data as NSString)
					}
			}
			InsertionDropZone(
				destPanelId: id,
				destIndex: tabs.count,
				moveTab: moveTab
			)
			.frame(width: 12)
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

			TabCloseButton { closeTab(panelId, index) }
		}
		.padding(.horizontal, 8)
		.padding(.vertical, 4)
		.background(isSelected ? Color(.windowBackgroundColor) : Color.clear)
		.onTapGesture {
			selectTab(panelId, index)
			onFocusPanel(panelId)
		}
	}

	@ViewBuilder
	func addTabButton(panelId: UUID) -> some View {
		TabAddButton { addTab(panelId) }
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
			let divider: CGFloat = 3
			let secondSize = total - firstSize - divider

			if direction == .horizontal {
				HStack(spacing: 0) {
					PanelView(
						rootPanel: first,
						activePanelId: activePanelId,
						leafContent: leafContent,
						closePanel: closePanel,
						selectTab: selectTab,
						closeTab: closeTab,
						addTab: addTab,
						resizeSplit: resizeSplit,
						onFocusPanel: onFocusPanel,
						moveTab: moveTab
					)
					.frame(width: firstSize, height: geo.size.height)
					SplitDivider(
						direction: direction,
						total: total,
						fraction: fraction,
						splitId: id,
						onResize: resizeSplit
					)
					PanelView(
						rootPanel: second,
						activePanelId: activePanelId,
						leafContent: leafContent,
						closePanel: closePanel,
						selectTab: selectTab,
						closeTab: closeTab,
						addTab: addTab,
						resizeSplit: resizeSplit,
						onFocusPanel: onFocusPanel,
						moveTab: moveTab
					)
					.frame(width: max(0, secondSize), height: geo.size.height)
				}
			}
			else {
				VStack(spacing: 0) {
					PanelView(
						rootPanel: first,
						activePanelId: activePanelId,
						leafContent: leafContent,
						closePanel: closePanel,
						selectTab: selectTab,
						closeTab: closeTab,
						addTab: addTab,
						resizeSplit: resizeSplit,
						onFocusPanel: onFocusPanel,
						moveTab: moveTab
					)
					.frame(width: geo.size.width, height: firstSize)
					SplitDivider(
						direction: direction,
						total: total,
						fraction: fraction,
						splitId: id,
						onResize: resizeSplit
					)
					PanelView(
						rootPanel: second,
						activePanelId: activePanelId,
						leafContent: leafContent,
						closePanel: closePanel,
						selectTab: selectTab,
						closeTab: closeTab,
						addTab: addTab,
						resizeSplit: resizeSplit,
						onFocusPanel: onFocusPanel,
						moveTab: moveTab
					)
					.frame(width: geo.size.width, height: max(0, secondSize))
				}
			}
		}
	}
}

// MARK: - Tab Close Button

private struct TabCloseButton: View {
	let action: () -> Void

	@State private var isHovering = false

	var body: some View {
		Image(systemName: "xmark")
			.font(.system(size: 9, weight: .bold))
			.foregroundColor(.secondary)
			.padding(6)
			.background(
				RoundedRectangle(cornerRadius: 4)
					.fill(isHovering ? Color.gray.opacity(0.15) : Color.clear)
			)
			.onTapGesture { action() }
			.onHover { isHovering = $0 }
	}
}

// MARK: - Tab Add Button

private struct TabAddButton: View {
	let action: () -> Void

	@State private var isHovering = false

	var body: some View {
		Image(systemName: "plus")
			.font(.system(size: 11, weight: .medium))
			.foregroundColor(.secondary)
			.padding(6)
			.background(
				RoundedRectangle(cornerRadius: 4)
					.fill(isHovering ? Color.gray.opacity(0.15) : Color.clear)
			)
			.onTapGesture { action() }
			.onHover { isHovering = $0 }
	}
}

// MARK: - Split Divider

private struct SplitDivider: View {
	let direction: SplitDirection
	let total: CGFloat
	let fraction: CGFloat
	let splitId: UUID
	let onResize: (UUID, CGFloat) -> Void

	@State private var dragStartFraction: CGFloat? = nil
	@State private var isHoveringDivider = false

	var body: some View {
		Color.clear
			.frame(
				width: direction == .horizontal ? 8 : nil,
				height: direction == .vertical ? 8 : nil
			)
			.overlay(
				Rectangle()
					.fill(Color(nsColor: isHoveringDivider ? .controlAccentColor : .separatorColor))
					.frame(
						width: direction == .horizontal ? 3 : nil,
						height: direction == .vertical ? 3 : nil
					)
			)
			.contentShape(Rectangle())
			.onHover { hovering in
				isHoveringDivider = hovering
				if hovering {
					(direction == .horizontal
						? NSCursor.resizeLeftRight
						: NSCursor.resizeUpDown
					).push()
				} else {
					NSCursor.pop()
				}
			}
			.gesture(
				DragGesture()
					.onChanged { value in
						if !isHoveringDivider {
							isHoveringDivider = true
							(direction == .horizontal
								? NSCursor.resizeLeftRight
								: NSCursor.resizeUpDown
							).push()
						}
						let sf = dragStartFraction ?? fraction
						dragStartFraction = sf
						let delta = direction == .horizontal ? value.translation.width : value.translation.height
						let newFraction = max(0.15, min(0.85, sf + delta / total))
						onResize(splitId, newFraction)
					}
					.onEnded { _ in
						dragStartFraction = nil
						isHoveringDivider = false
						NSCursor.pop()
					}
			)
	}
}

// MARK: - Insertion Drop Zone

private struct InsertionDropZone: View {
	let destPanelId: UUID
	let destIndex: Int
	let moveTab: (UUID, Int, UUID, Int) -> Void

	@State private var isTargeted = false

	var body: some View {
		Color.clear
			.contentShape(Rectangle())
			.onDrop(of: [.plainText], isTargeted: $isTargeted) { providers, _ in
				handleDrop(providers)
				return true
			}
			.overlay(alignment: .leading) {
				if isTargeted {
					InsertionIndicator()
				}
			}
	}

	private func handleDrop(_ providers: [NSItemProvider]) {
		print("🟢 InsertionDropZone.handleDrop — destPanelId=\(destPanelId) destIndex=\(destIndex) providers=\(providers.count)")
		guard let provider = providers.first else {
			print("  ❌ no providers")
			return
		}
		_ = provider.loadObject(ofClass: NSString.self) { item, error in
			if let error = error { print("  ❌ loadObject error: \(error)"); return }
			guard let string = item as? String else {
				print("  ❌ item not String, type=\(type(of: item as Any))")
				return
			}
			print("  loaded string: \"\(string)\"")
			let parts = string.split(separator: ":")
			guard parts.count == 2,
				  let sourceId = UUID(uuidString: String(parts[0])),
				  let sourceIndex = Int(parts[1]) else {
				print("  ❌ failed to parse: parts=\(parts)")
				return
			}
			print("  ✅ parsed — sourceId=\(sourceId) sourceIndex=\(sourceIndex)")
			DispatchQueue.main.async {
				print("  📞 calling moveTab on main queue")
				moveTab(sourceId, sourceIndex, destPanelId, destIndex)
			}
		}
	}
}

// MARK: - Insertion Indicator

private struct InsertionIndicator: View {
	var body: some View {
		Rectangle()
			.fill(Color.accentColor)
			.frame(width: 2)
			.padding(.vertical, 4)
	}
}

// MARK: - Panel View Model

class PanelViewModel: ObservableObject {
	@Published var rootPanel: PanelModel = .leaf(id: UUID())
	@Published var activePanelId: UUID?

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
		let newPanel = rootPanel.closeTab(in: panelId, at: index)
		if case .leaf(_, let tabs, _) = newPanel, tabs.isEmpty {
			rootPanel = .leaf(id: UUID())
		} else {
			rootPanel = newPanel
		}
	}

	@discardableResult
	func addTab(to panelId: UUID, title: String = "New Tab") -> UUID {
		let tabId = UUID()
		let tab = TabItem(id: tabId, title: title)
		rootPanel = rootPanel.addTab(to: panelId, tab: tab)
		if let leaf = rootPanel.findLeaf(panelId: panelId) {
			rootPanel = rootPanel.selectTab(in: panelId, at: leaf.tabs.count - 1)
		}
		return tabId
	}

	func replaceTab(in panelId: UUID, at index: Int, with tab: TabItem) {
		rootPanel = rootPanel.replaceTab(in: panelId, at: index, with: tab)
	}

	func moveTab(from sourcePanelId: UUID, at sourceIndex: Int, to destPanelId: UUID, at destIndex: Int) {
		print("📦 PanelViewModel.moveTab — src=\(sourcePanelId) idx=\(sourceIndex) dst=\(destPanelId) idx=\(destIndex)")
		let old = rootPanel
		rootPanel = rootPanel.moveTab(from: sourcePanelId, at: sourceIndex, to: destPanelId, at: destIndex)
		if rootPanel == old {
			print("  ⚠️ rootPanel UNCHANGED after moveTab")
		} else {
			print("  ✅ rootPanel changed")
		}
	}
}
