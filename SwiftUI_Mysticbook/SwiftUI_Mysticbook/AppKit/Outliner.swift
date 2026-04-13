//
//  Outliner.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/12/26.
//

import SwiftUI

struct Outliner: NSViewRepresentable {
	
	let rootNodes: [OutlinerNode]?
	
	func makeNSView(context: Context) -> some NSView {
		
		print("makeNSView")
		
		// Initialize NSOutlineView
		let outlineView = NSOutlineView()
		outlineView.dataSource = context.coordinator
		outlineView.delegate = context.coordinator
		outlineView.headerView = nil
		
		let column = NSTableColumn(
			identifier: NSUserInterfaceItemIdentifier("MainColumn")
		)
		column.title = "MainColumn"
		
		outlineView.addTableColumn(column)
		outlineView.outlineTableColumn = column
		
		// Initialize NSScrollView
		let scrollView = NSScrollView()
		scrollView.documentView = outlineView
		scrollView.hasVerticalScroller = true
		
		return scrollView
	}
	
	func updateNSView(_ nsView: NSViewType, context: Context) {}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(parent: self)
	}
	
	class Coordinator:
		NSObject,
		NSTextViewDelegate,
		NSOutlineViewDelegate,
		NSOutlineViewDataSource {
		
		let parent: Outliner
		
		init(parent: Outliner) {
			self.parent = parent
		}
		
		/// NSTextViewDelegate
		
		func textDidChange(_ notification: Notification) {
			print("textDidChange")
			guard let textView = notification.object as? NSTextView,
						let outlineView = textView.superview?.superview as? NSOutlineView
			else {
				return
			}
						
			let rowIndex = outlineView.row(for: textView)
			
			if rowIndex != -1 {
				if let node = outlineView.item(atRow: rowIndex) as? OutlinerNode {
					node.text = textView.string
				}
				
				NSAnimationContext.beginGrouping()
				NSAnimationContext.current.duration = 0
				outlineView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: rowIndex))
				NSAnimationContext.endGrouping()
			}
		}

		/// NSOutlineViewDelegate
		
		func outlineView(
			_ outlineView: NSOutlineView,
			shouldExpandItem item: Any
		) -> Bool {
			true
		}
		
		func outlineView(
			_ outlineView: NSOutlineView,
			shouldCollapseItem item: Any
		) -> Bool {
			true
		}
		
		func outlineView(
			_ outlineView: NSOutlineView,
			shouldSelect tableColumn: NSTableColumn?
		) -> Bool {
			true
		}
		
		func outlineView(
			_ outlineView: NSOutlineView,
			shouldSelectItem item: Any
		) -> Bool {
			true
		}
		
		func outlineView(
			_ outlineView: NSOutlineView,
			willDisplayCell cell: Any,
			for tableColumn: NSTableColumn?,
			item: Any
		) {
			print("willDisplayCell")
		}
		
		func outlineView(
			_ outlineView: NSOutlineView,
			willDisplayOutlineCell cell: Any,
			for tableColumn: NSTableColumn?,
			item: Any
		) {
			print("willDisplayOutlineCell")
		}
		
		func outlineView(
			_ outlineView: NSOutlineView,
			dataCellFor tableColumn: NSTableColumn?,
			item: Any
		) -> NSCell? {
			nil
		}
		
		func outlineView(
			_ outlineView: NSOutlineView,
			shouldShowOutlineCellForItem item: Any
		) -> Bool {
			true
		}
		
		func outlineView(
			_ outlineView: NSOutlineView,
			shouldShowCellExpansionFor tableColumn: NSTableColumn?,
			item: Any
		) -> Bool {
			true
		}
		
		func outlineView(
			_ outlineView: NSOutlineView,
			shouldEdit tableColumn: NSTableColumn?,
			item: Any
		) -> Bool {
			true
		}
		
		func outlineView(
			_ outlineView: NSOutlineView,
			heightOfRowByItem item: Any
		) -> CGFloat {
						
			guard let node = item as? OutlinerNode else {
				return 14
			}
			
			// Calculate dynamic height
			let textStorage = NSTextStorage(string: node.text)
			let textContainer = NSTextContainer(
				size: CGSize(
					width: CGFloat.greatestFiniteMagnitude,
					height: CGFloat.greatestFiniteMagnitude
				)
			)
			let layoutManager = NSLayoutManager()
			
			layoutManager.addTextContainer(textContainer)
			textStorage.addLayoutManager(layoutManager)
			layoutManager.glyphRange(for: textContainer)
			let usedRect = layoutManager.usedRect(for: textContainer)
			let result = max(14, usedRect.height)
			print("Outline View Height Result: \(result)")
			return result
		}
		
		func outlineView(
			_ outlineView: NSOutlineView,
			viewFor tableColumn: NSTableColumn?,
			item: Any
		) -> NSView? {
			let identifier = NSUserInterfaceItemIdentifier("MainColumn")
			var view = outlineView.makeView(
				withIdentifier: identifier, owner: self) as? NSTextView
			
			if view == nil {
				view = NSTextView()
				view?.delegate = self
				view?.identifier = identifier
			}
			
			if let node = item as? OutlinerNode {
				view?.string = node.text
			}
			
			return view
		}
		
		/// NSOutlineViewDataSource
		
		func outlineView(
			_ outlineView: NSOutlineView,
			child index: Int,
			ofItem item: Any?
		) -> Any {
			guard let node = item as? OutlinerNode else {
				return parent.rootNodes![index]
			}
			
			return node.children[index]
		}
		
		func outlineView(
			_ outlineView: NSOutlineView,
			isItemExpandable item: Any
		) -> Bool {
			guard let node = item as? OutlinerNode else {
				return false
			}
			return !node.children.isEmpty
		}
		
		func outlineView(
			_ outlineView: NSOutlineView,
			numberOfChildrenOfItem item: Any?
		) -> Int {
			guard let node = item as? OutlinerNode else {
				return parent.rootNodes?.count ?? 0
			}
			return node.children.count
		}
	}
}
