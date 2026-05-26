import SwiftUI
import HeroKit

// Default messages — Dad can long-press to edit
private let defaultMessages: [String] = [
    "I love you, Parker. ❤️",
    "You are SO brave.",
    "I'm thinking of you right now.",
    "You make me so proud.",
    "Have the best day ever! 🌟",
    "You are strong AND kind.",
    "I'll be home soon. 🏠",
    "You're my favorite Parker.",
]

struct ContentView: View {
    @AppStorage("dadmessages.list.json") private var messagesData: Data = Data()
    @AppStorage("dadmessages.index") private var messageIndex: Int = 0
    @State private var isEditing = false
    @State private var messages: [String] = []
    @State private var scale: CGFloat = 1.0
    @State private var showHeart = false

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.15).ignoresSafeArea()

            if isEditing {
                EditView(messages: $messages, onDone: saveAndClose)
            } else {
                messageCard
            }
        }
        .onAppear { loadMessages() }
    }

    private var messageCard: some View {
        VStack(spacing: 6) {
            Text("💌")
                .font(.system(size: 26))
                .overlay(
                    Text("💛")
                        .font(.system(size: 14))
                        .offset(x: 14, y: -14)
                        .scaleEffect(showHeart ? 1.4 : 0)
                        .opacity(showHeart ? 0 : 1)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: showHeart)
                )

            Text(messages.isEmpty ? "No messages yet" : messages[safe: messageIndex] ?? messages[0])
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .scaleEffect(scale)
                .padding(.horizontal, 6)

            Text("from Dad")
                .font(.system(size: 10, weight: .light))
                .foregroundColor(.white.opacity(0.4))
        }
        .onTapGesture { nextMessage() }
        .onLongPressGesture(minimumDuration: 2.0) {
            HapticEngine.play(.success)
            isEditing = true
        }
    }

    private func nextMessage() {
        guard !messages.isEmpty else { return }
        HapticEngine.play(.notification)
        showHeart = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { showHeart = false }

        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { scale = 1.1 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.15)) { scale = 1.0 }
        messageIndex = (messageIndex + 1) % messages.count
    }

    private func loadMessages() {
        if let loaded = try? JSONDecoder().decode([String].self, from: messagesData), !loaded.isEmpty {
            messages = loaded
        } else {
            messages = defaultMessages
        }
    }

    private func saveAndClose() {
        messagesData = (try? JSONEncoder().encode(messages)) ?? Data()
        isEditing = false
    }
}

// Minimal edit view — parent-gated by the 2-second long press
struct EditView: View {
    @Binding var messages: [String]
    let onDone: () -> Void
    @State private var newMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text("Dad's Messages")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))

                ForEach(messages.indices, id: \.self) { i in
                    Text(messages[i])
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(6)
                }

                Button("Done ✓") { onDone() }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green)
            }
            .padding(6)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
