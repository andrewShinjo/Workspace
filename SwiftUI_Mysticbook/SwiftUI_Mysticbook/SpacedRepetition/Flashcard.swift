import Foundation

struct Flashcard: Identifiable {
    enum Direction: String {
        case forward
        case reverse
    }

    let node: OutlinerNode
    let question: String
    let answer: String
    let direction: Direction

    var id: String { "\(node.id.uuidString)-\(direction.rawValue)" }

    var reviewsKey: String { direction == .forward ? "SINGLE_REVIEWS" : "SINGLE_REV_REVIEWS" }
    var intervalKey: String { direction == .forward ? "SINGLE_INTERVAL" : "SINGLE_REV_INTERVAL" }
    var easeKey: String { direction == .forward ? "SINGLE_EASE" : "SINGLE_REV_EASE" }
    var lapsesKey: String { direction == .forward ? "SINGLE_LAPSES" : "SINGLE_REV_LAPSES" }
    var nextReviewKey: String { direction == .forward ? "SINGLE_NEXT_REVIEW" : "SINGLE_REV_NEXT_REVIEW" }
    var lastReviewedKey: String { direction == .forward ? "SINGLE_LAST_REVIEWED" : "SINGLE_REV_LAST_REVIEWED" }

    var delimiter: String {
        node.text.contains(":<->") ? "<->" : "->"
    }

    var ancestorHeadings: [String] {
        var headings: [String] = []
        var current = node.parent
        while let parent = current {
            let heading = parent.text.firstIndex(of: "\n").map { String(parent.text[..<$0]) } ?? parent.text
            if !heading.isEmpty { headings.insert(heading, at: 0) }
            current = parent.parent
        }
        return headings
    }
}
