//
//  Outliner.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/12/26.
//

import Combine
import SwiftUI
import AppKit

struct Outliner: NSViewRepresentable {

	var document: OutlinerDocument
	var saveURL: URL?
	let identifier = NSUserInterfaceItemIdentifier("MainColumn")

	func makeNSView(context: Context) -> some NSView {

		print("makeNSView")

		let outlineView = OutlinerView()

		outlineView.selectionHighlightStyle = .none
		outlineView.allowsEmptySelection = true
		outlineView.allowsMultipleSelection = false

		outlineView.dataSource = context.coordinator
		outlineView.delegate = context.coordinator
		outlineView.headerView = nil

		let column = NSTableColumn(identifier: identifier)
		column.title = "MainColumn"
		outlineView.addTableColumn(column)
		outlineView.outlineTableColumn = column

		let scrollView = NSScrollView()
		scrollView.documentView = outlineView
		scrollView.hasVerticalScroller = true
		scrollView.hasHorizontalScroller = false
		scrollView.horizontalScrollElasticity = .none

		outlineView.sizeLastColumnToFit()
		outlineView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle

		outlineView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			outlineView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
			outlineView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
			outlineView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
		])

		return scrollView
	}

	func updateNSView(_ nsView: NSViewType, context: Context) {
		guard let scrollView = nsView as? NSScrollView,
					let outlineView = scrollView.documentView as? NSOutlineView else { return }

		context.coordinator.parent = self
		context.coordinator.outlineView = outlineView

		if context.coordinator.lastDocument !== document {
			context.coordinator.lastDocument = document
			context.coordinator.resubscribe()
			DispatchQueue.main.async {
				CATransaction.begin()
				CATransaction.setDisableActions(true)

				context.coordinator.hasExpandedRoot = true
				outlineView.reloadData()

				let rows = IndexSet(integersIn: 0..<outlineView.numberOfRows)
				outlineView.noteHeightOfRows(withIndexesChanged: rows)

				let rootNode = document.rootNode
				if !rootNode.children.isEmpty {
					outlineView.expandItem(rootNode)
					let rootRow = outlineView.row(forItem: rootNode)
					if rootRow >= 0 {
						outlineView.reloadData(forRowIndexes: IndexSet(integer: rootRow), columnIndexes: IndexSet(integer: 0))
					}
				}

				CATransaction.commit()
			}
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(parent: self)
	}

	class Coordinator:
		NSObject,
		NSTextViewDelegate,
		NSOutlineViewDelegate,
		NSOutlineViewDataSource {

		var parent: Outliner

		init(parent: Outliner) {
			self.parent = parent
		}

		var hasExpandedRoot = false
		var lastDocument: OutlinerDocument?
		weak var outlineView: NSOutlineView?
		var changeCancellable: AnyCancellable?

		func resubscribe() {
			changeCancellable = parent.document.objectDidChange
				.receive(on: DispatchQueue.main)
				.sink { [weak self] _ in
					guard let self, let ov = self.outlineView else { return }
					let isEditing: Bool = {
						guard let fr = ov.window?.firstResponder as? NSTextView else { return false }
						return fr.isDescendant(of: ov)
					}()
					if isEditing { return }
					ov.reloadData()
				}
		}

		// MARK: - NSTextViewDelegate

		func textDidChange(_ notification: Notification) {
			guard let textView = notification.object as? NSTextView else { return }
			guard let outlineView = sequence(
				first: textView as NSView?,
				next: { $0?.superview }
			)
				.compactMap({ $0 as? NSOutlineView })
				.first else {
				return
			}

			let rowIndex = outlineView.row(for: textView)
			if rowIndex == -1 { return }

			if let node = outlineView.item(atRow: rowIndex) as? OutlinerNode,
				 node.text != textView.string {
				parent.document.updateNodeText(node, text: textView.string)
				if let url = parent.saveURL {
				autoSave(document: parent.document, to: url)
			}
				NSAnimationContext.beginGrouping()
				NSAnimationContext.current.duration = 0
				outlineView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: rowIndex))
				NSAnimationContext.endGrouping()
			}
		}

		func textView(
			_ textView: NSTextView,
			doCommandBy commandSelector: Selector
		) -> Bool {
			if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
				handleDeleteKey(in: textView)
				return true
			}
			if commandSelector == #selector(NSResponder.insertNewline(_:)) {
				if let event = NSApp.currentEvent, event.modifierFlags.contains(.shift) {
					textView.insertNewlineIgnoringFieldEditor(nil)
				} else {
					handleReturnKey(in: textView)
				}
				return true
			}
			if commandSelector == #selector(NSResponder.insertTab(_:)) {
				handleIndent(in: textView)
				return true
			}
			if commandSelector == #selector(NSResponder.insertBacktab(_:)) {
				handleUnindent(in: textView)
				return true
			}
			return false
		}

		private func handleIndent(in textView: NSTextView) {
			guard let outlineView = sequence(
				first: textView as NSTextView?,
				next: { $0?.superview }
			)
				.compactMap({ $0 as? NSOutlineView }).first,
						let node = outlineView.item(
							atRow: outlineView.row(for: textView)
						) as? OutlinerNode else {
				return
			}

			parent.document.indentNode(node)
			outlineView.reloadData()

			if let newParent = node.parent, !outlineView.isItemExpanded(newParent) {
				outlineView.expandItem(newParent)
			}

			DispatchQueue.main.async {
				self.focusNode(
					in: outlineView,
					node: node,
					cursorPosition: textView.selectedRange().location
				)
			}
		}

		private func handleUnindent(in textView: NSTextView) {
			guard let outlineView = sequence(
				first: textView as NSTextView?,
				next: { $0?.superview }
			)
				.compactMap({ $0 as? NSOutlineView }).first,
						let node = outlineView.item(
							atRow: outlineView.row(for: textView)
						) as? OutlinerNode else {
				return
			}

			parent.document.unindentNode(node)
			outlineView.reloadData()

			DispatchQueue.main.async {
				self.focusNode(
					in: outlineView,
					node: node,
					cursorPosition: textView.selectedRange().location
				)
			}
		}

		private func focusNode(in outlineView: NSOutlineView, node: OutlinerNode, cursorPosition: Int? = nil) {
			let row = outlineView.row(forItem: node)
			guard row != -1,
						let cellView = outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as? NSTableCellView,
						let textView = cellView.subviews.first(where: { $0 is NSTextView }) as? NSTextView else {
				return
			}
			outlineView.window?.makeFirstResponder(textView)
			let position = cursorPosition ?? 0
			textView.setSelectedRange(NSRange(location: position, length: 0))
		}

		private func handleDeleteKey(in textView: NSTextView) {
			let selectedRange = textView.selectedRange()
			guard selectedRange.location == 0 && selectedRange.length == 0
			else {
				textView.deleteBackward(nil)
				return
			}

			guard let outlineView = sequence(
				first: textView as NSTextView?,
				next: { $0?.superview }
			)
				.compactMap({ $0 as? NSOutlineView }).first,
						let node = outlineView.item(
							atRow: outlineView.row(for: textView)
						) as? OutlinerNode else {
				textView.deleteBackward(nil)
				return
			}

			guard let nodeParent = node.parent
			else {
				textView.deleteBackward(nil)
				return
			}

			guard let childIndex = nodeParent.children.firstIndex(where: { $0.id == node.id })
			else {
				textView.deleteBackward(nil)
				return
			}

			let originalTextLength = if childIndex == 0 {
				nodeParent.text.count
			}
			else {
				nodeParent.children[childIndex - 1].text.count
			}

			parent.document.mergeNode(node)

			outlineView.removeItems(
				at: IndexSet(integer: childIndex),
				inParent: node.parent,
				withAnimation: .effectFade
			)

			let nodeToFocus = if childIndex == 0 {
				nodeParent
			}
			else {
				nodeParent.children[childIndex - 1]
			}

			let focusRow = outlineView.row(forItem: nodeToFocus)

			outlineView.reloadData(
				forRowIndexes: IndexSet(integer: focusRow),
				columnIndexes: IndexSet(integer: 0)
			)

			NSAnimationContext.beginGrouping()
			NSAnimationContext.current.duration = 0
			outlineView.noteHeightOfRows(
				withIndexesChanged: IndexSet(integer: focusRow))
			NSAnimationContext.endGrouping()

			self.focusNode(
				in: outlineView,
				node: nodeToFocus,
				cursorPosition: originalTextLength
			)
		}

		private func handleReturnKey(in textView: NSTextView) {
			guard let outlineView = sequence(
				first: textView as NSTextView?,
				next: { $0?.superview }
			)
				.compactMap({ $0 as? NSOutlineView }).first,
						let node = outlineView.item(
							atRow: outlineView.row(for: textView)) as? OutlinerNode else {
				textView.insertNewlineIgnoringFieldEditor(nil)
				return
			}

			let (parent, index) = parent.document.splitNode(after: node, in: textView)

			outlineView.insertItems(
				at: IndexSet(integer: index),
				inParent: parent,
				withAnimation: .slideDown
			)

			NSAnimationContext.beginGrouping()
			NSAnimationContext.current.duration = 0
			outlineView.noteHeightOfRows(
				withIndexesChanged: IndexSet(integer: outlineView.row(for: textView)))
			NSAnimationContext.endGrouping()

			if !outlineView.isItemExpanded(parent) {
				outlineView.expandItem(parent)
			}

			if index == 0 {
				outlineView.reloadData(
					forRowIndexes: IndexSet(
						integer: outlineView.row(forItem: parent)
					),
					columnIndexes: IndexSet(integer: 0)
				)
			}
			else {
				outlineView.reloadData(
					forRowIndexes: IndexSet(
						integer: outlineView.row(forItem: parent.children[index - 1])
					),
					columnIndexes: IndexSet(integer: 0)
				)
			}

			let newNode = parent.children[index]
			self.focusNode(in: outlineView, node: newNode, cursorPosition: 0)
		}

		// MARK: - NSOutlineViewDelegate

		func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool { true }
		func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
			guard let node = item as? OutlinerNode else { return true }
			return !node.isRoot()
		}
		func outlineView(_ outlineView: NSOutlineView, shouldSelect tableColumn: NSTableColumn?) -> Bool { true }
		func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool { true }

		func outlineView(_ outlineView: NSOutlineView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, item: Any) {
			print("willDisplayCell")
		}

		func outlineView(_ outlineView: NSOutlineView, willDisplayOutlineCell cell: Any, for tableColumn: NSTableColumn?, item: Any) {
			print("willDisplayOutlineCell")
		}

		func outlineView(_ outlineView: NSOutlineView, dataCellFor tableColumn: NSTableColumn?, item: Any) -> NSCell? { nil }
		func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool { true }
		func outlineView(_ outlineView: NSOutlineView, shouldShowCellExpansionFor tableColumn: NSTableColumn?, item: Any) -> Bool { true }
		func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool { true }

		func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
			guard let node = item as? OutlinerNode else { return 14 }

			if outlineView.tableColumns.isEmpty { return 14 }

			let columnWidth = max(outlineView.tableColumns[0].width, outlineView.bounds.width - 20)
			let fontSize: CGFloat = node.isRoot() ? 26 : 13
			let textStorage = NSTextStorage(string: node.text)
			textStorage.setAttributes([NSAttributedString.Key.font: NSFont.systemFont(ofSize: fontSize)], range: NSRange(location: 0, length: (node.text as NSString).length))

			let textContainer = NSTextContainer(size: CGSize(width: columnWidth, height: CGFloat.greatestFiniteMagnitude))
			let layoutManager = NSLayoutManager()
			layoutManager.addTextContainer(textContainer)
			textStorage.addLayoutManager(layoutManager)

			layoutManager.glyphRange(for: textContainer)
			let usedRect = layoutManager.usedRect(for: textContainer)

			let minHeight = ceil(NSFont.systemFont(ofSize: fontSize).boundingRectForFont.height)
			let result = max(minHeight, usedRect.height)
			return result
		}

		// ★ Updated viewFor to place the text view below the disclosure button
		func outlineView(
			_ outlineView: NSOutlineView,
			viewFor tableColumn: NSTableColumn?,
			item: Any
		) -> NSView? {

			let cellIdentifier = parent.identifier
			var cell = outlineView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView

			if cell == nil {
				// Create a new cell of the custom subclass
				let newCell = OutlinerCellView()
				newCell.identifier = cellIdentifier

				let textView = NSTextView()
				textView.delegate = self

				textView.textContainerInset = .zero
				textView.textContainer?.lineFragmentPadding = 0
				textView.isVerticallyResizable = true
				textView.isHorizontallyResizable = false
				textView.textContainer?.heightTracksTextView = true
				textView.textContainer?.widthTracksTextView = true
				textView.translatesAutoresizingMaskIntoConstraints = false

				// Place the text view below the disclosure button so it doesn't cover it
				if let button = newCell.customDisclosureButton {
					newCell.addSubview(textView, positioned: .below, relativeTo: button)
				} else {
					newCell.addSubview(textView)
				}

				// Leave room for disclosure button + bullet (36 points)
				NSLayoutConstraint.activate([
					textView.leadingAnchor.constraint(equalTo: newCell.leadingAnchor, constant: 36),
					textView.trailingAnchor.constraint(equalTo: newCell.trailingAnchor),
					textView.topAnchor.constraint(equalTo: newCell.topAnchor),
					textView.bottomAnchor.constraint(equalTo: newCell.bottomAnchor)
				])

				textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

				textView.wantsLayer = true
				textView.layer?.actions = [
					"bounds": NSNull(),
					"position": NSNull(),
					"frame": NSNull()
				]
				textView.layer?.borderWidth = 1
				textView.layer?.borderColor = NSColor.red.cgColor

				cell = newCell
			}

			// At this point `cell` might still be typed as NSTableCellView?, but we need to find its text view
			// The text view is now always a subview, so we can search for it generically.
			guard let textView = cell?.subviews.first(where: { $0 is NSTextView }) as? NSTextView else {
				return cell
			}

			guard let node = item as? OutlinerNode else { return cell }

			textView.string = node.text
			textView.font = NSFont.systemFont(ofSize: node.isRoot() ? 26 : 13)

			if let outlinerCell = cell as? OutlinerCellView {
				let hasChildren = !node.children.isEmpty
				outlinerCell.customDisclosureButton?.isHidden = !hasChildren || node.isRoot()
				outlinerCell.bulletLabel?.isHidden = node.isRoot()
				outlinerCell.setExpanded(outlineView.isItemExpanded(node))
			}

			return cell
		}

		// MARK: - NSOutlineViewDataSource

		func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
			guard let node = item as? OutlinerNode else {
				return parent.document.rootNode
			}
			return node.children[index]
		}

		func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
			guard let node = item as? OutlinerNode else { return false }
			return !node.children.isEmpty
		}

		func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
			guard let node = item as? OutlinerNode else { return 1 }
			return node.children.count
		}
	}
}
