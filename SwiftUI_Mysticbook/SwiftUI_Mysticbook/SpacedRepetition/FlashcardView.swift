import SwiftUI

struct FlashcardView: View {
    let deck: FlashcardDeck
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            if deck.flashcards.isEmpty {
                VStack(spacing: 12) {
                    Text("No flashcards found")
                        .font(.title2)
                    Text("Add `:->` to outliner rows to create flashcards")
                        .foregroundColor(.secondary)
                    Button("Close") {
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }
            } else if let card = deck.currentFlashcard {
                Text("\(deck.currentIndex + 1) / \(deck.flashcards.count)")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text(card.question)
                    .font(.title)
                    .multilineTextAlignment(.center)

                if deck.isAnswerRevealed {
                    Divider()
                    Text(card.answer)
                        .font(.body)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 20) {
                        Button("Forgot") {
                            deck.next()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)

                        Button("Easy") {
                            deck.next()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    .padding(.top, 8)
                } else {
                    Button("Show Answer") {
                        deck.showAnswer()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }

                if deck.currentIndex == deck.flashcards.count - 1 && deck.isAnswerRevealed {
                    Text("Last card!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding(40)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 20)
        .frame(maxWidth: 450, maxHeight: .infinity)
        .background(Color.black.opacity(0.2))
        .onTapGesture {
            isPresented = false
        }
    }
}
