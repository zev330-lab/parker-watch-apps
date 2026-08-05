import SwiftUI
import HeroKit

private let phrases: [String] = [
    "It's always\nright now.",
    "Still right\nnow.",
    "Guess what?\nRight now.",
    "Yep.\nRight. Now.",
    "Forever and\nalways now.",
    "Now.\nJust now.",
    "The answer\nis now.",
    "Right now\nforever.",
    "Now o'clock.",
    "Always\nright now.",
]

struct ContentView: View {
    @State private var index = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var starBurst = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if starBurst {
                Circle()
                    .stroke(Color.yellow.opacity(0.6), lineWidth: 2)
                    .frame(width: starBurst ? 160 : 40, height: starBurst ? 160 : 40)
                    .scaleEffect(starBurst ? 2.2 : 0.1)
                    .opacity(starBurst ? 0 : 1)
                    .animation(.easeOut(duration: 0.5), value: starBurst)
            }

            VStack(spacing: 6) {
                Text("🕰️")
                    .font(.system(size: 36))
                    .scaleEffect(scale)

                Text(phrases[index])
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .opacity(opacity)
                    .scaleEffect(scale)
                    .padding(.horizontal, 8)
            }
        }
        .onTapGesture { nextPhrase() }
    }

    private func nextPhrase() {
        HapticEngine.play(.tap)

        starBurst = false
        withAnimation { starBurst = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { starBurst = false }

        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { scale = 1.15 }
        withAnimation(.easeOut(duration: 0.15)) { opacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            index = (index + 1) % phrases.count
            SpeechEngine.shared.speak(phrases[index])
            withAnimation(.easeIn(duration: 0.15)) { opacity = 1 }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { scale = 1.0 }
        }
    }
}
