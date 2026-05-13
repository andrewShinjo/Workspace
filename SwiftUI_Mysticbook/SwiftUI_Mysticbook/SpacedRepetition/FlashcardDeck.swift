import Foundation

private let flashcardDateFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f
}()

@Observable
final class FlashcardDeck {
    var flashcards: [Flashcard] = []
    var currentIndex: Int = 0
    var isAnswerRevealed: Bool = false
    private(set) var rootNode: OutlinerNode?
    private(set) var totalFlashcardCount: Int = 0

    var onSave: (() -> Void)?

    var currentFlashcard: Flashcard? {
        guard currentIndex < flashcards.count else { return nil }
        return flashcards[currentIndex]
    }

    init() {}

    static func extractAll(from text: String) -> [(question: String, answer: String)]? {
        if let range = text.range(of: ":<->") {
            let front = text[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
            let back = text[range.upperBound...].trimmingCharacters(in: .whitespaces)
            guard !front.isEmpty, !back.isEmpty else { return nil }
            return [
                (question: front, answer: back),
                (question: back, answer: front),
            ]
        } else if let range = text.range(of: ":->") {
            let question = text[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
            let answer = text[range.upperBound...].trimmingCharacters(in: .whitespaces)
            guard !question.isEmpty, !answer.isEmpty else { return nil }
            return [(question: question, answer: answer)]
        }
        return nil
    }

    func load(from node: OutlinerNode) {
        rootNode = node
        var result: [Flashcard] = []
        collectFlashcards(from: node, into: &result)
        totalFlashcardCount = result.count
        flashcards = result.filter { isDue($0) }
        currentIndex = 0
        isAnswerRevealed = false
    }

    private func collectFlashcards(from node: OutlinerNode, into result: inout [Flashcard]) {
        if let cards = Self.extractAll(from: node.text) {
            for (i, card) in cards.enumerated() {
                let direction: Flashcard.Direction = i == 0 ? .forward : .reverse
                result.append(Flashcard(node: node, question: card.question, answer: card.answer, direction: direction))
            }
        }
        for child in node.children {
            collectFlashcards(from: child, into: &result)
        }
    }

    func showAnswer() {
        isAnswerRevealed = true
    }

    func next() {
        currentIndex += 1
        isAnswerRevealed = false
    }

    func rateEasy(_ card: Flashcard) {
        let node = card.node
        let currentReviews = Int(node.properties[card.reviewsKey] ?? "0") ?? 0
        let currentInterval = Int(node.properties[card.intervalKey] ?? "0") ?? 0
        let currentEase = Double(node.properties[card.easeKey] ?? "2.5") ?? 2.5
        let currentLapses = Int(node.properties[card.lapsesKey] ?? "0") ?? 0

        let newReviews = currentReviews + 1
        let newInterval = currentReviews == 0 ? 4 : Int(Double(currentInterval) * currentEase)
        let now = Date()
        let nextReview = Calendar.current.date(byAdding: .day, value: newInterval, to: now) ?? now

        node.properties[card.reviewsKey] = "\(newReviews)"
        node.properties[card.intervalKey] = "\(newInterval)"
        node.properties[card.easeKey] = "\(currentEase)"
        node.properties[card.lapsesKey] = "\(currentLapses)"
        node.properties[card.nextReviewKey] = flashcardDateFormatter.string(from: nextReview)
        node.properties[card.lastReviewedKey] = flashcardDateFormatter.string(from: now)

        onSave?()
        next()
    }

    func rateForgot(_ card: Flashcard) {
        let node = card.node
        let currentEase = Double(node.properties[card.easeKey] ?? "2.5") ?? 2.5
        let currentLapses = Int(node.properties[card.lapsesKey] ?? "0") ?? 0
        let now = Date()

        let newEase = max(1.3, currentEase - 0.2)
        let newLapses = currentLapses + 1

        node.properties[card.reviewsKey] = "0"
        node.properties[card.intervalKey] = "0"
        node.properties[card.easeKey] = "\(newEase)"
        node.properties[card.lapsesKey] = "\(newLapses)"
        node.properties[card.lastReviewedKey] = flashcardDateFormatter.string(from: now)
        node.properties.removeValue(forKey: card.nextReviewKey)

        onSave?()
        next()
    }

    private func isDue(_ card: Flashcard) -> Bool {
        guard let nextReviewStr = card.node.properties[card.nextReviewKey],
              let nextReview = flashcardDateFormatter.date(from: nextReviewStr)
        else { return true }
        return nextReview <= Date()
    }

    func previewIntervalIfEasy(for card: Flashcard) -> TimeInterval {
        let currentReviews = Int(card.node.properties[card.reviewsKey] ?? "0") ?? 0
        let currentInterval = Int(card.node.properties[card.intervalKey] ?? "0") ?? 0
        let currentEase = Double(card.node.properties[card.easeKey] ?? "2.5") ?? 2.5
        let newInterval = currentReviews == 0 ? 4 : Int(Double(currentInterval) * currentEase)
        return TimeInterval(newInterval * 86400)
    }

    func previewIntervalIfForgot(for card: Flashcard) -> TimeInterval {
        0
    }

    func formatInterval(_ interval: TimeInterval) -> String {
        switch interval {
        case ..<60:
            return "Now"
        case ..<3600:
            let minutes = Int(interval / 60)
            return minutes == 1 ? "Next: 1 min" : "Next: \(minutes) min"
        case ..<86400:
            let hours = Int(interval / 3600)
            return hours == 1 ? "Next: 1 hour" : "Next: \(hours) hours"
        default:
            let days = Int(interval / 86400)
            return days == 1 ? "Next: 1 day" : "Next: \(days) days"
        }
    }
}
