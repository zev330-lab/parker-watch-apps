import SwiftUI
import HeroKit

private let defaultHappyThings: [String] = [
    "Mom's hugs 🤗",
    "Dad's hugs 🤗",
    "My dog 🐶",
    "Superheroes 🦸",
    "Ben 10 👽",
    "Karate class 🥋",
    "Pizza 🍕",
    "Minecraft ⛏️",
    "Swimming 🏊",
    "Silly jokes 😂",
    "Snuggling in bed 😴",
    "Being brave 💪",
]

struct ContentView: View {
    @State private var items: [String] = StorageKit.load(
        [String].self, key: "happythings.list", default: defaultHappyThings)
    @State private var current: String = "Tap for something happy! 🌟"
    @State private var scale: CGFloat = 1.0
    @State private var bgColor: Color = .purple

    private let bgColors: [Color] = [.purple, .pink, .orange, .blue, .green, .teal, .indigo]
    @State private var colorIndex = 0

    var body: some View {
        ZStack {
            bgColor.opacity(0.25).ignoresSafeArea()

            VStack(spacing: 8) {
                Text("💛")
                    .font(.system(size: 32))
                    .scaleEffect(scale)

                Text(current)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .padding(.horizontal, 6)
            }
        }
        .onTapGesture { showHappy() }
    }

    private func showHappy() {
        guard !items.isEmpty else { return }
        HapticEngine.play(.surge)
        colorIndex = (colorIndex + 1) % bgColors.count
        current = items.randomElement()!

        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
            scale = 1.3
            bgColor = bgColors[colorIndex]
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15)) {
            scale = 1.0
        }
    }
}
