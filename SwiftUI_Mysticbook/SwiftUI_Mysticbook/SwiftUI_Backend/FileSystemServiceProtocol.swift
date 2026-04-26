//
//  FileSystemServiceProtocol.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 4/25/26.
//

import Foundation

protocol FileSystemServiceProtocol {
	func contentsOfDirectory(at directory: URL) throws -> [URL]
}
