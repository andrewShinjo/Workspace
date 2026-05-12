//
//  OrgSerialization.swift
//  SwiftUI_Mysticbook
//
//  Created by Andrew Shinjo on 5/2/26.
//

import Foundation

// MARK: - Serialization

func orgSerialize(_ document: OutlinerDocument) -> String {
    var lines: [String] = []

    let rootParts = splitHeadingAndBody(document.rootNode.text)
    if !rootParts.heading.isEmpty {
        lines.append("#+TITLE: \(rootParts.heading)")
    }

    var rootPropLines: [String] = []
    rootPropLines.append(":PROPERTIES:")
    rootPropLines.append(":ID: \(document.rootNode.orgID)")
    for (key, value) in document.rootNode.properties where key != "ID" {
        rootPropLines.append(":\(key): \(value)")
    }
    rootPropLines.append(":END:")
    lines.append(contentsOf: rootPropLines)

    if !rootParts.body.isEmpty {
        lines.append(rootParts.body)
    }

    for child in document.rootNode.children {
        lines.append(contentsOf: serializeNode(child, depth: 1))
    }

    let result = lines.joined(separator: "\n")
    return result.isEmpty ? "\n" : result + "\n"
}

private func splitHeadingAndBody(_ text: String) -> (heading: String, body: String) {
    guard let newlineIndex = text.firstIndex(of: "\n") else {
        return (text, "")
    }
    let heading = String(text[..<newlineIndex])
    let body = String(text[text.index(after: newlineIndex)...])
    return (heading, body)
}

private func serializeNode(_ node: OutlinerNode, depth: Int) -> [String] {
    var lines: [String] = []
    let parts = splitHeadingAndBody(node.text)
    let stars = String(repeating: "*", count: depth)
    lines.append("\(stars) \(parts.heading)")

    var propLines: [String] = []
    propLines.append(":PROPERTIES:")
    propLines.append(":ID: \(node.orgID)")
    for (key, value) in node.properties where key != "ID" {
        propLines.append(":\(key): \(value)")
    }
    propLines.append(":END:")
    lines.append(contentsOf: propLines)

    if !parts.body.isEmpty {
        lines.append(parts.body)
    }
    for child in node.children {
        lines.append(contentsOf: serializeNode(child, depth: depth + 1))
    }
    return lines
}

private func extractProperties(from text: inout String) -> (orgID: String, properties: [String: String]) {
    var orgID = UUID().uuidString
    var properties: [String: String] = [:]

    let parts = splitHeadingAndBody(text)
    let heading = parts.heading
    var body = parts.body

    guard !body.isEmpty else {
        return (orgID, properties)
    }

    let nsBody = body as NSString
    var searchRange = NSRange(location: 0, length: nsBody.length)

    while true {
        let propsRange = nsBody.range(of: ":PROPERTIES:", options: [], range: searchRange)
        if propsRange.location == NSNotFound { break }

        if propsRange.location > 0 {
            let prevChar = nsBody.substring(with: NSRange(location: propsRange.location - 1, length: 1))
            guard prevChar == "\n" || prevChar == "\r" else {
                searchRange = NSRange(location: propsRange.location + 1, length: nsBody.length - propsRange.location - 1)
                continue
            }
        }

        let afterProps = propsRange.location + propsRange.length
        let remLen = nsBody.length - afterProps
        let endRange = nsBody.range(of: ":END:", options: [], range: NSRange(location: afterProps, length: remLen))
        if endRange.location == NSNotFound { break }

        let content = nsBody.substring(with: NSRange(location: afterProps, length: endRange.location - afterProps))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix(":") else { continue }
            let rest = trimmed.dropFirst()
            guard let colonIdx = rest.firstIndex(of: ":") else { continue }
            let key = rest[..<colonIdx].trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty, key != "END", key != "PROPERTIES" else { continue }
            let value = rest[rest.index(after: colonIdx)...].trimmingCharacters(in: .whitespaces)
            properties[key] = value
            if key == "ID" { orgID = value }
        }

        let blockStart: Int
        if propsRange.location > 0 {
            let prevChar = nsBody.substring(with: NSRange(location: propsRange.location - 1, length: 1))
            if prevChar == "\n" || prevChar == "\r" {
                blockStart = propsRange.location - 1
            } else {
                blockStart = propsRange.location
            }
        } else {
            blockStart = 0
        }
        let blockEnd = endRange.location + endRange.length

        let beforeBlock = nsBody.substring(with: NSRange(location: 0, length: blockStart))
        let afterBlock = nsBody.substring(with: NSRange(location: blockEnd, length: nsBody.length - blockEnd))
        body = beforeBlock + afterBlock

        let nsBody2 = body as NSString
        searchRange = NSRange(location: blockStart, length: nsBody2.length - blockStart)
    }

    body = body.trimmingCharacters(in: .newlines)

    if body.isEmpty {
        text = heading
    } else {
        text = heading + "\n" + body
    }

    return (orgID, properties)
}

// MARK: - Deserialization

enum OrgDeserializationError: Error {
    case invalidFormat(String)
}

func orgDeserialize(_ text: String) -> OutlinerDocument {
    let lines = text.components(separatedBy: .newlines)

    let rootNode = OutlinerNode(text: "")
    var currentNode = rootNode
    var depthStack: [(depth: Int, node: OutlinerNode)] = []
    var foundFirstHeading = false

    for line in lines {
        if line.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("#+title:") {
            let titleStr = String(
							line.dropFirst("#+title:".count)
						).trimmingCharacters(in: .whitespaces)
            rootNode.text = titleStr
            continue
        }

        if line.hasPrefix("*") {
					foundFirstHeading = true
					while currentNode.text.hasSuffix("\n") {
						currentNode.text = String(currentNode.text.dropLast())
					}
					let starCount = line.prefix(while: { $0 == "*" }).count
					let headingText = String(line.dropFirst(starCount))
						.trimmingCharacters(in: .whitespaces)

					let newNode = OutlinerNode(text: headingText)

					while let last = depthStack.last, last.depth >= starCount {
						depthStack.removeLast()
					}

					if let parentNode = depthStack.last?.node {
						parentNode.children.append(newNode)
						newNode.parent = parentNode
					} else {
						rootNode.children.append(newNode)
						newNode.parent = rootNode
					}

					depthStack.append((starCount, newNode))
					currentNode = newNode
        } else {
					if foundFirstHeading {
							if currentNode.text.isEmpty {
									if !line.isEmpty {
											currentNode.text = line
									}
							} else {
									currentNode.text += "\n" + line
							}
					} else {
							if !line.isEmpty {
									if rootNode.text.isEmpty {
											rootNode.text = line
									} else {
											rootNode.text += "\n" + line
									}
							}
					}
        }
    }

    func extractPropertiesFromNode(_ node: OutlinerNode) {
        let (orgID, props) = extractProperties(from: &node.text)
        node.orgID = orgID
        node.properties = props
        for child in node.children {
            extractPropertiesFromNode(child)
        }
    }
    extractPropertiesFromNode(rootNode)

    func trimTrailingNewlines(_ node: OutlinerNode) {
        while node.text.hasSuffix("\n") {
            node.text = String(node.text.dropLast())
        }
        for child in node.children {
            trimTrailingNewlines(child)
        }
    }
    trimTrailingNewlines(rootNode)

    return OutlinerDocument(rootNode: rootNode)
}
