//
//  Outliner.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/12/26.
//

import SwiftUI

struct Outliner: NSViewRepresentable {
	
	let rootNodes: [OutlinerNode]?
	let identifier = NSUserInterfaceItemIdentifier("MainColumn")
	
	func makeNSView(context: Context) -> some NSView {
		
		print("makeNSView")
		
		// A view to display hierarchical data.
		// Doesn't store its own data; instead, it retrieves data values as needed
		// from a data source to which it has a weak reference.
		// NSOutlineViewDataSource has methods an NSOutlineView uses to access the
		// contents of its data source object.
		let outlineView = NSOutlineView()
		
		// Sets the object that provides the data displayed by the receiver.
		outlineView.dataSource = context.coordinator
		
		// Sets the outline view's delegate.
		outlineView.delegate = context.coordinator
		outlineView.headerView = nil
		
		// An identifier and display characteristics for a column.
		// Determines the width, min and max, of its column in the outline view and
		// specifies the resizing and editing behavior.
		let column = NSTableColumn(identifier: identifier)
		
		// Set the table column's header title.
		column.title = "MainColumn"
		
		// Adds column as the outline view's last column.
		outlineView.addTableColumn(column)
		
		// Sets the outline view's table column in which hierarchical data is
		// displayed.
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
		// Protocol to implement a set of optional methods that text view delegates
		// can use to manage selection, set text attributes, work with the spell
		// checker, and more.
		// Subclass of NSTextDelegate.
		NSTextViewDelegate,
		NSOutlineViewDelegate,
		NSOutlineViewDataSource {
		
			let parent: Outliner
			
			init(parent: Outliner) {
				self.parent = parent
			}
			
			/// NSTextViewDelegate
			
			// Informs the delegate that the text object has changed its characters or
			// formatting attributes.
			func textDidChange(_ notification: Notification) {
				
				// Extract the text view object from the notification.
				guard let textView = notification.object as? NSTextView,
							let outlineView = textView.superview?.superview as? NSOutlineView
				else {
					return
				}
				
				// Returns the row for the text view in the outline view.
				let rowIndex = outlineView.row(for: textView)
				
				// If the row isn't found, then exit.
				if rowIndex == -1 {
					return
				}
				
				// Synchronize the text view and data model.
				if let node = outlineView.item(atRow: rowIndex) as? OutlinerNode,
					 node.text != textView.string {
					node.text = textView.string
					
					// Tell the outline view to update the height.
					outlineView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: rowIndex))
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
				
				// Typecast item from Any type to OutlinerNode type.
				// If it's impossible, then return a height of 14.
				guard let node = item as? OutlinerNode else {
					return 14
				}
				
				if outlineView.tableColumns.isEmpty {
					return 14
				}
								
				print("outlineView::heightOfRowByItem")
				print("Let's get outline view layout data:")
				
				let columnWidth = outlineView.tableColumns[0].width
				
				print("columnWidth: \(columnWidth)")
				
				// NSAttributedString
				// - A string of text that manages data, layout, and stylistic info for
				// ranges of character to support rendering.
				// - Contains key-value pair known as attributes that specify info about
				//   ranges of character within the string.
				// - Attributes like: font, color, kern, ligature, attachments, URL, etc.
				// - Use when you need to style text, of associate info with text.
				// - It's immutable so you can't change it after specifying styles.
				// - Internally, I'm guessing NSAttributedString is a String and a Map of
				//   attributes.
				//
				// NSMutableAttributedString
				// - A mutable string with attributes like visual style, hyperlinks, or
				//   accessibility.
				// - Subclass of NSAttributedString, but declares additional methods for
				//   mutating the content of an attributed string.
				// - Two additional methods: replaceCharacters and setAttributes.
				//
				// NSTextStorage
				// - Semi-concrete subclass of NSMutableAttributedString that adds
				//   behavior for managing a set of client NSLayoutManager objects
				// - Notifies its layout manager of changes to its characters or
				//   attributes, which lets the layout managers redisplay the text as
				//   needed.
				let textStorage = NSTextStorage(string: node.text)
				
				// NSTextContainer
				// - Used by NSLayoutManager to determine where to break lines, lay out
				//   portions of text, and so on.
				// - Defines rectangular regions, but you can define exclusion paths
				//   inside the text container to create regions where text doesn't flow
				let textContainer = NSTextContainer(
					size: CGSize(
						width: columnWidth,
						height: CGFloat.greatestFiniteMagnitude
					)
				)
				
				// NSLayoutManager
				// - Coordinates the layout and display of text characters.
				// - Maps Unicode characters to glyphs.
				let layoutManager = NSLayoutManager()
				
				// Appends the text container to the series of text containers where the
				// layout manager arranges text.
				layoutManager.addTextContainer(textContainer)
				
				// Adds a layout manager to the text storage object's set of layout
				// managers.
				textStorage.addLayoutManager(layoutManager)
				
				// Returns the range of glyphs lying within the specified text container.
				layoutManager.glyphRange(for: textContainer)
				
				// Returns the bounding rectangle for the glyphs in the specified text
				// container.
				// Returns the text container's currently used area, which determines the
				// size that the view would need to be in order to display all the glyphs
				// that are currently laid out in the container.
				let usedRect = layoutManager.usedRect(for: textContainer)
				
				print("usedRect.height: \(usedRect.height)")
				
				// The height is 14 or the height of the text container, whichever is
				// greater.
				let result = max(14, usedRect.height)
				print("Outline View Height Result: \(result)")
				return result
			}
			
			// Returns the view used to display the specified item and column.
			// Recommended to call makeView to reuse a view, if exists.
			func outlineView(
				_ outlineView: NSOutlineView,
				viewFor tableColumn: NSTableColumn?,
				item: Any
			) -> NSView? {
				
				// Returns a new or existing view with the specified identifier.
				var view = outlineView.makeView(
					withIdentifier: parent.identifier, owner: self) as? NSTextView
								
				// If the view doesn't exist, then create a new one.
				if view == nil {
					view = NSTextView()
					view?.delegate = self
					view?.identifier = parent.identifier
				}
				
				// Set the textview's string to the node's text.
				if let node = item as? OutlinerNode {
					view?.string = node.text
				}
				
				view?.textContainer?.heightTracksTextView = true
				view?.textContainer?.widthTracksTextView = true
				
				// Need to set wantsLayer to show a border.
				view?.wantsLayer = true
				view?.layer?.borderWidth = 1
				view?.layer?.borderColor = NSColor.red.cgColor
				
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
