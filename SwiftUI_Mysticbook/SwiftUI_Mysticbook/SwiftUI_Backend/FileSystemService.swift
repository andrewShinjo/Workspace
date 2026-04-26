//
//  FileSystemService.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/25/26.
//

import Foundation

final class FileSystemService: FileSystemServiceProtocol {
	
	private let fileManager: FileManager
	
	init(fileManager: FileManager = .default) {
		self.fileManager = fileManager
	}
	
	func contentsOfDirectory(at directory: URL) throws -> [URL] {
		try fileManager.contentsOfDirectory(
			at: directory,
			includingPropertiesForKeys: nil,
			options: []
		)
	}
}
