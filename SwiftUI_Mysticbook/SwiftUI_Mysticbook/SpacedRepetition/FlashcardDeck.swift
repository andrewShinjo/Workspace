import Foundation

@Observable
final class FlashcardDeck {
    var flashcards: [Flashcard] = []
    var currentIndex: Int = 0
    var isAnswerRevealed: Bool = false

    var currentFlashcard: Flashcard? {
        guard currentIndex < flashcards.count else { return nil }
        return flashcards[currentIndex]
    }

    init() {}

    static func extract(from text: String) -> (question: String, answer: String)? {
        guard let range = text.range(of: ":->") else { return nil }
        let question = text[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
        let answer = text[range.upperBound...].trimmingCharacters(in: .whitespaces)
        guard !question.isEmpty, !answer.isEmpty else { return nil }
        return (question, answer)
    }

    func load(from node: OutlinerNode) {
        var result: [Flashcard] = []
        collectFlashcards(from: node, into: &result)
        flashcards = result
        currentIndex = 0
        isAnswerRevealed = false
    }

    private func collectFlashcards(from node: OutlinerNode, into result: inout [Flashcard]) {
        if let card = Self.extract(from: node.text) {
            result.append(Flashcard(question: card.question, answer: card.answer))
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
}
