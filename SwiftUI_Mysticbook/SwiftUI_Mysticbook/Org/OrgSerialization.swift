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
    if !rootParts.body.isEmpty {
        lines.append(rootParts.body)
    }

    for child in document.rootNode.children {
        if !lines.isEmpty {
            lines.append("")
        }
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
    if !parts.body.isEmpty {
        lines.append(parts.body)
    }
    for child in node.children {
        if !lines.isEmpty {
            lines.append("")
        }
        lines.append(contentsOf: serializeNode(child, depth: depth + 1))
    }
    return lines
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
            let titleStr = String(line.dropFirst("#+title:".count)).trimmingCharacters(in: .whitespaces)
            rootNode.text = titleStr
            continue
        }

        if line.hasPrefix("*") {
            foundFirstHeading = true
            let starCount = line.prefix(while: { $0 == "*" }).count
            let headingText = String(line.dropFirst(starCount)).trimmingCharacters(in: .whitespaces)

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

    rootNode.text = rootNode.text.trimmingCharacters(in: .whitespacesAndNewlines)

    return OutlinerDocument(rootNode: rootNode)
}
