import SwiftUI
import HeroKit

private let superpowers: [String] = [
    "You can turn INVISIBLE! 👻",
    "You have SUPER SPEED! 💨",
    "You can BREATHE FIRE! 🔥",
    "You can FLY! ✈️",
    "You can READ MINDS! 🧠",
    "You are SUPER STRONG! 💪",
    "You can FREEZE TIME! ⏸️",
    "You can TALK TO ANIMALS! 🐾",
    "You can SHOOT LASERS! ⚡",
    "You can TELEPORT! 🌀",
    "You are INVINCIBLE! 🛡️",
    "You can GROW GIANT! 🦖",
    "You have X-RAY VISION! 👁️",
    "You can COPY ANY POWER! ✨",
    "You can SHOOT WEBS! 🕷️",
    "You CONTROL LIGHTNING! ⚡",
]

struct ContentView: View {
    @State private var crownValue: Double = 0
    @State private var lastCrownIdx: Int = 0
    @State private var currentIdx: Int = 0
    @State private var isActivated = false
    @State private var activateScale: CGFloat = 1.0
    @State private var bgOpacity: Double = 0.1
    @State private var sparkles: [SparkleParticle] = []

    private let colors: [Color] = [.blue, .purple, .red, .orange, .green, .yellow, .pink, .teal]

    var body: some View {
        ZStack {
            colors[currentIdx % colors.count].opacity(bgOpacity).ignoresSafeArea()

            VStack(spacing: 6) {
                Text(isActivated ? "⚡ ACTIVATED ⚡" : "Spin to find\nyour power")
                    .font(.system(size: isActivated ? 10 : 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)

                Text(superpowers[currentIdx])
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .scaleEffect(activateScale)
                    .padding(.horizontal, 4)
                    .minimumScaleFactor(0.6)

                if isActivated {
                    Text("TAP AGAIN TO KEEP")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.4))
                        .kerning(1)
                }
            }
        }
        .focusable(true)
        .digitalCrownRotation($crownValue, from: 0, through: Double(superpowers.count - 1), by: 1, sensitivity: .medium, isContinuous: true, isHapticFeedbackEnabled: true)
        .onChange(of: crownValue) { newVal in
            let idx = Int(newVal.rounded()) % superpowers.count
            guard idx != lastCrownIdx else { return }
            lastCrownIdx = idx
            currentIdx = ((idx % superpowers.count) + superpowers.count) % superpowers.count
            isActivated = false
            HapticEngine.play(.click)
            withAnimation(.easeOut(duration: 0.1)) { bgOpacity = 0.05 }
        }
        .onTapGesture { activatePower() }
    }

    private func activatePower() {
        HapticEngine.play(.surge)
        isActivated = true

        withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) { activateScale = 1.3; bgOpacity = 0.3 }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) { activateScale = 1.0 }
        withAnimation(.easeOut(duration: 1.0).delay(0.5)) { bgOpacity = 0.1 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { HapticEngine.play(.success) }
    }
}

struct SparkleParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
}
