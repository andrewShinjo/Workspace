import Foundation

struct Flashcard: Identifiable {
    let id: UUID
    let question: String
    let answer: String

    init(question: String, answer: String) {
        self.id = UUID()
        self.question = question
        self.answer = answer
    }
}
