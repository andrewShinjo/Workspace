//
//  Outliner.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/12/26.
//

import SwiftUI

struct Outliner: NSViewRepresentable {
	
	let document: OutlinerDocument
	//let rootNodes: [OutlinerNode]?
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
				
				// Extract the text view out of the notification.
				guard let textView = notification.object as? NSTextView else { return }
				
				// Walk up the view hierarchy to find the outline view
				guard let outlineView = sequence(
					first: textView as NSView?,
					next: { $0?.superview }
				)
					.compactMap({ $0 as? NSOutlineView })
					.first else {
					return
				}
				
				let rowIndex = outlineView.row(for: textView)
				if rowIndex == -1 {
					return
				}
				
				if let node = outlineView.item(atRow: rowIndex) as? OutlinerNode,
					 node.text != textView.string {
					node.text = textView.string
					NSAnimationContext.beginGrouping()
					NSAnimationContext.current.duration = 0
					outlineView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: rowIndex))
					NSAnimationContext.endGrouping()
				}
			}
			
			// Sent to allow the delegate to perform the command for the text view.
			// textView = the text view sending the message
			// commandSelector = the selector
			// Return true to tell the text view the delegate will handle the command.
			// Return false to tell the text view to handle the command.
			func textView(
				_ textView: NSTextView,
				doCommandBy commandSelector: Selector
			) -> Bool {
				
				// If delete backward command is requested, the delegate handles it.
				if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
					handleDeleteKey(in: textView)
					return true
				}
				// If insert new line command is requested, the delegate handles it.
				if commandSelector == #selector(NSResponder.insertNewline(_:)) {
					handleReturnKey(in: textView)
					return true
				}
				
				return false
			}
			
			private func handleDeleteKey(in textView: NSTextView) {
				
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
					
				parent.document.mergeNode(node)
				
				outlineView.removeItems(
					at: IndexSet(integer: childIndex),
					inParent: node.parent,
					withAnimation: .effectFade
				)
				
				// Set the focus.
				// Two cases:
				// (1) Set focus on parent
				// (2) Set focus on previous sibling
				
				let focusRow = (childIndex == 0) ?
				outlineView.row(forItem: nodeParent) :
				outlineView.row(forItem: nodeParent.children[childIndex - 1])
				
				let cellView = outlineView.view(
					atColumn: 0,
					row: focusRow,
					makeIfNecessary: false
				)
				as? NSTableCellView
				let textView = cellView?.subviews.first(where: { $0 is NSTextView })
				as? NSTextView
				
				outlineView.window?.makeFirstResponder(textView)
			}
			
			// When the return key is pressed in a text view, we will split the
			// text view's node.
			private func handleReturnKey(in textView: NSTextView) {
				
				// Find the outline view and the current node.
				// sequence(first:next) recursively generates the next value using the
				// first value. It generates a lazy sequence, meaning the actual values
				// aren't generated until they are used.
				guard let outlineView = sequence(
					first: textView as NSTextView?,
					next: { $0?.superview }
				)
					// Removes the nils and transforms each optional NSOutlineViews into
					// non-optional ones.
					.compactMap({ $0 as? NSOutlineView }).first,
							let node = outlineView.item(
								atRow: outlineView.row(for: textView)) as? OutlinerNode else {
					// Perform the default behavior.
					textView.insertNewlineIgnoringFieldEditor(nil)
					return
				}
				
				// Create the new node.
				let (parent, index) = parent.document.splitNode(after: node, in: textView)
				
				outlineView.insertItems(
					at: IndexSet(integer: index),
					inParent: parent,
					withAnimation: .slideDown
				)
				
				NSAnimationContext.beginGrouping()
				NSAnimationContext.current.duration = 0
				// Update the row's height.
				outlineView.noteHeightOfRows(
					withIndexesChanged: IndexSet(integer: outlineView.row(for: textView)))
				NSAnimationContext.endGrouping()
				
				// Expand the parent if collapsed so that the new child is visible.
				if !outlineView.isItemExpanded(parent) {
					outlineView.expandItem(parent)
				}
				
				// Set focus.
				
				let newNode = parent.children[index]
				let row = outlineView.row(forItem: newNode)
				guard row != -1,
							let cellView = outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as? NSTableCellView,
							let textView = cellView.subviews.first(where: { $0 is NSTextView }) as? NSTextView else {
						return
				}

				outlineView.window?.makeFirstResponder(textView)
				textView.setSelectedRange(NSRange(location: 0, length: 0))
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
					
				let cellIdentifier = parent.identifier
				var cell = outlineView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView
				
				if cell == nil {
					cell = NSTableCellView()
					cell?.identifier = cellIdentifier
					
					let textView = NSTextView()
					textView.delegate = self
					
					// Inset is padding around the text view.
					textView.textContainerInset = .zero
					textView.textContainer?.lineFragmentPadding = 0
					textView.isVerticallyResizable = true
					textView.isHorizontallyResizable = false
					textView.textContainer?.heightTracksTextView = true
					textView.textContainer?.widthTracksTextView = true
					
					textView.translatesAutoresizingMaskIntoConstraints = false
					cell?.addSubview(textView)
					
					NSLayoutConstraint.activate([
						textView.leadingAnchor.constraint(equalTo: cell!.leadingAnchor),
						textView.trailingAnchor.constraint(equalTo: cell!.trailingAnchor),
						textView.topAnchor.constraint(equalTo: cell!.topAnchor),
						textView.bottomAnchor.constraint(equalTo: cell!.bottomAnchor)
					])
					
					textView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
					
					// Optional debug border
					textView.wantsLayer = true
					textView.layer?.borderWidth = 1
					textView.layer?.borderColor = NSColor.red.cgColor
				}
				
				// Find the text view inside the cell
				guard let textView = cell?.subviews.first(where: { $0 is NSTextView }) as? NSTextView else {
					return cell
				}
				
				if let node = item as? OutlinerNode {
					textView.string = node.text
				}
				
				return cell
			}
			
			/// NSOutlineViewDataSource
			
			func outlineView(
				_ outlineView: NSOutlineView,
				child index: Int,
				ofItem item: Any?
			) -> Any {
				guard let node = item as? OutlinerNode else {
					return parent.document.rootNode
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
					return 1
				}
				return node.children.count
			}
	}
}
