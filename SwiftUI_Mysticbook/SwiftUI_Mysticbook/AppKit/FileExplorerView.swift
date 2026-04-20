//
//  FileExplorerView.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/19/26.
//

import SwiftUI

struct FileExplorerView: NSViewRepresentable {
	
	let identifier = NSUserInterfaceItemIdentifier("FileExplorerColumn")
	
	func makeNSView(context: Context) -> some NSView {
		let outlineView = NSOutlineView()
		outlineView.dataSource = context.coordinator
		outlineView.delegate = context.coordinator
		outlineView.headerView = nil
		
		let column = NSTableColumn(identifier: identifier)
		column.title = ""
		outlineView.addTableColumn(column)
		outlineView.outlineTableColumn = column
		
		let scrollView = NSScrollView()
		scrollView.documentView = outlineView
		scrollView.hasVerticalScroller = true
		
		return scrollView
	}
	
	func updateNSView(_ nsView: NSViewType, context: Context) {}
	
	func makeCoordinator() -> Coordinator {
		Coordinator()
	}
	
	class Coordinator: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
		
		class FileSystemItem {
			let name: String
			let path: String
			let isDirectory: Bool
			var children: [FileSystemItem] = []
			var childrenLoaded = false
			
			init(name: String, path: String, isDirectory: Bool) {
				self.name = name
				self.path = path
				self.isDirectory = isDirectory
			}
		}
		
		private var rootItem: FileSystemItem?
		
		override init() {
			super.init()
			loadDocumentsDirectory()
		}
		
		private func loadDocumentsDirectory() {
			let fileManager = FileManager.default
			guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
				print("ERROR: Could not find Documents directory")
				return
			}
			
			do {
				rootItem = FileSystemItem(name: "Documents", path: documentsURL.path, isDirectory: true)
				loadChildren(for: rootItem!)
			} catch {
				print("ERROR: Error accessing Documents: \(error)")
			}
		}
		

		
		private func loadChildren(for item: FileSystemItem) {
			let fileManager = FileManager.default
			let url = URL(fileURLWithPath: item.path)
			
			do {
				let contents = try fileManager.contentsOfDirectory(
					at: url,
					includingPropertiesForKeys: [.isDirectoryKey],
					options: []
				)
				
				for childURL in contents {
					let resourceValues = try childURL.resourceValues(forKeys: [.isDirectoryKey])
					let isDirectory = resourceValues.isDirectory ?? false
					let childItem = FileSystemItem(
						name: childURL.lastPathComponent,
						path: childURL.path,
						isDirectory: isDirectory
					)
					item.children.append(childItem)
				}
				
				item.children.sort { a, b in
					if a.isDirectory && !b.isDirectory { return true }
					if !a.isDirectory && b.isDirectory { return false }
					return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
				}
				
			} catch {
				print("Error loading directory contents: \(error)")
			}
			
			item.childrenLoaded = true
		}
		
		func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
			if item == nil {
				return rootItem != nil ? 1 : 0
			}
			guard let fileItem = item as? FileSystemItem else { return 0 }
			
			// Load children if this is a directory and hasn't been loaded yet
			if fileItem.isDirectory && !fileItem.childrenLoaded {
				loadChildren(for: fileItem)
			}
			
			return fileItem.children.count
		}
		
		func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
			if item == nil {
				return rootItem!
			}
			guard let fileItem = item as? FileSystemItem else { return NSNull() }
			return fileItem.children[index]
		}
		
		func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
			guard let fileItem = item as? FileSystemItem else { return false }
			return fileItem.isDirectory
		}
		
		func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
			let cellIdentifier = NSUserInterfaceItemIdentifier("FileCell")
			var cell = outlineView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView
			
			if cell == nil {
				cell = NSTableCellView()
				cell?.identifier = cellIdentifier
				
				let imageView = NSImageView()
				imageView.translatesAutoresizingMaskIntoConstraints = false
				imageView.imageScaling = .scaleProportionallyDown
				cell?.imageView = imageView
				
				let textField = NSTextField()
				textField.translatesAutoresizingMaskIntoConstraints = false
				textField.isEditable = false
				textField.isBordered = false
				textField.drawsBackground = false
				cell?.textField = textField
				
				cell?.addSubview(imageView)
				cell?.addSubview(textField)
				
				NSLayoutConstraint.activate([
					imageView.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 2),
					imageView.centerYAnchor.constraint(equalTo: cell!.centerYAnchor),
					imageView.widthAnchor.constraint(equalToConstant: 16),
					imageView.heightAnchor.constraint(equalToConstant: 16),
					
					textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 4),
					textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -2),
					textField.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
				])
			}
			
			guard let fileItem = item as? FileSystemItem else { return cell }
			
			cell?.textField?.stringValue = fileItem.name
			
			if fileItem.isDirectory {
				cell?.imageView?.image = NSImage(named: NSImage.folderName)
			} else {
				cell?.imageView?.image = NSImage(named: NSImage.actionTemplateName)
			}
			cell?.imageView?.image?.size = NSSize(width: 16, height: 16)
			
			return cell
		}
		
		func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
			return 20
		}
	}
}
