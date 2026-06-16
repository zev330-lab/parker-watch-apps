import SwiftUI
import HeroKit

// MARK: - Sonic characters

private struct SonicChar {
    let name: String
    let emoji: String
    let color: Color
    let action: String
    let haptic: HapticPattern
    var isLocked: Bool = false
}

private let sonicChars: [SonicChar] = [
    SonicChar(name: "Sonic",       emoji: "💙", color: .blue,   action: "SPIN DASH! 💨", haptic: .surge),
    SonicChar(name: "Tails",       emoji: "🦊", color: .yellow, action: "FLYING! ✈️",    haptic: .click),
    SonicChar(name: "Knuckles",    emoji: "🦔", color: .red,    action: "PUNCH! 👊",     haptic: .doubleTap),
    SonicChar(name: "Shadow",      emoji: "🖤", color: .purple, action: "CHAOS! 🌑",     haptic: .tap),
    SonicChar(name: "Super Sonic", emoji: "⭐", color: .orange, action: "UNLIMITED! 🌟", haptic: .success, isLocked: true),
]

private let gemEmojis = ["💠","🔴","🟣","🟡","🟢","🩷","🤍"]

// MARK: - Transformers characters

private struct TFChar {
    let name: String
    let robotEmoji: String
    let carEmoji: String
    let color: Color
}

private let tfChars: [TFChar] = [
    TFChar(name: "Optimus Prime", robotEmoji: "🤖", carEmoji: "🚛",  color: .blue),
    TFChar(name: "Bumblebee",     robotEmoji: "🟡", carEmoji: "🏎️",  color: .yellow),
    TFChar(name: "Megatron",      robotEmoji: "😈", carEmoji: "✈️",  color: .purple),
    TFChar(name: "Starscream",    robotEmoji: "🔴", carEmoji: "🛩️",  color: .red),
    TFChar(name: "Grimlock",      robotEmoji: "🦕", carEmoji: "🦖",  color: .green),
    TFChar(name: "Cheetor",       robotEmoji: "🐆", carEmoji: "💛",  color: .yellow),
]

// MARK: - Root

enum GarageUniverse { case sonic, transformers }

struct ContentView: View {
    @State private var universe: GarageUniverse = .sonic
    @State private var crownVal: Double = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            if universe == .sonic {
                SonicView(crownVal: $crownVal)
            } else {
                TransformersView(crownVal: $crownVal)
            }

            Button {
                HapticEngine.play(.click)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    universe = universe == .sonic ? .transformers : .sonic
                    crownVal = 0
                }
            } label: {
                Text(universe == .sonic ? "⚙️ ROBOTS" : "💨 SONIC")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Sonic Universe

struct SonicView: View {
    @Binding var crownVal: Double
    @State private var charIdx = 0
    @State private var lastIdx = 0
    @State private var scale: CGFloat = 1.0
    @State private var spin: Double = 0
    @State private var showAction = false
    @State private var emeralds: [Bool] = StorageKit.load([Bool].self, key: "garage.gems2",
                                                           default: Array(repeating: false, count: 7))

    private var allCollected: Bool { emeralds.allSatisfy { $0 } }
    private var char: SonicChar {
        let c = sonicChars[charIdx]
        return (c.isLocked && !allCollected) ? sonicChars[0] : c
    }

    var body: some View {
        ZStack {
            char.color.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { i in
                        Text(emeralds[i] ? gemEmojis[i] : "⬛")
                            .font(.system(size: 14))
                    }
                }
                .padding(.top, 6)

                Spacer()

                Text(char.emoji)
                    .font(.system(size: 62))
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(spin))
                    .shadow(color: char.color, radius: 14)

                Text(char.name)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 4)

                if showAction {
                    Text(char.action)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(char.color)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("TAP ME!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))
                }

                Spacer()
                    .frame(height: 42)
            }
        }
        .focusable(true)
        .digitalCrownRotation($crownVal,
                               from: 0, through: Double(sonicChars.count - 1),
                               by: 1, sensitivity: .medium,
                               isContinuous: false, isHapticFeedbackEnabled: true)
        .onChange(of: crownVal) { val in
            let idx = max(0, min(Int(val.rounded()), sonicChars.count - 1))
            guard idx != lastIdx else { return }
            lastIdx = idx
            let target = sonicChars[idx]
            if target.isLocked && !allCollected { return }
            charIdx = idx
            HapticEngine.play(target.haptic)
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { scale = 1.3 }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1)) { scale = 1.0 }
        }
        .onTapGesture { activate() }
    }

    private func activate() {
        HapticEngine.play(char.haptic)
        SpeechEngine.shared.speak(char.name + "! " + char.action)
        if char.name == "Sonic" {
            withAnimation(.linear(duration: 0.35)) { spin += 360 }
        }
        withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) { scale = 1.55 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.15)) { scale = 1.0 }
        withAnimation { showAction = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showAction = false }
        }
        let uncollected = emeralds.indices.filter { !emeralds[$0] }
        if let i = uncollected.randomElement() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                emeralds[i] = true
                StorageKit.save(emeralds, key: "garage.gems2")
                HapticEngine.play(.success)
            }
        }
    }
}

// MARK: - Transformers Universe

struct TransformersView: View {
    @Binding var crownVal: Double
    @State private var charIdx = 0
    @State private var lastIdx = 0
    @State private var isRobot = true
    @State private var scale: CGFloat = 1.0
    @State private var skew: CGFloat = 0
    @State private var busy = false

    private var char: TFChar { tfChars[charIdx] }

    var body: some View {
        ZStack {
            char.color.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 6) {
                Spacer()

                Text(isRobot ? char.robotEmoji : char.carEmoji)
                    .font(.system(size: 66))
                    .scaleEffect(scale)
                    .transformEffect(.init(a: 1, b: 0, c: skew, d: 1, tx: 0, ty: 0))
                    .shadow(color: char.color, radius: 12)

                Text(char.name)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(isRobot ? "TAP: TRANSFORM! 🔄" : "TAP: ROBOT! 🤖")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(char.color)

                Spacer()
                    .frame(height: 42)
            }
        }
        .focusable(true)
        .digitalCrownRotation($crownVal,
                               from: 0, through: Double(tfChars.count - 1),
                               by: 1, sensitivity: .medium,
                               isContinuous: false, isHapticFeedbackEnabled: true)
        .onChange(of: crownVal) { val in
            let idx = max(0, min(Int(val.rounded()), tfChars.count - 1))
            guard idx != lastIdx else { return }
            lastIdx = idx; charIdx = idx; isRobot = true
            HapticEngine.play(.click)
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { scale = 1.3 }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1)) { scale = 1.0 }
        }
        .onTapGesture { transform() }
    }

    private func transform() {
        guard !busy else { return }
        busy = true
        HapticEngine.play(.surge)
        let newState = !isRobot
        let speech = newState ? "\(char.name)! Robot mode!" : "\(char.name) transforms!"
        SpeechEngine.shared.speak(speech)
        withAnimation(.easeInOut(duration: 0.07)) { skew = 0.35 }
        withAnimation(.easeInOut(duration: 0.07).delay(0.07)) { skew = -0.35 }
        withAnimation(.easeInOut(duration: 0.07).delay(0.14)) { skew = 0 }
        withAnimation(.spring(response: 0.15, dampingFraction: 0.3).delay(0.05)) { scale = 1.55 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2)) { scale = 1.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isRobot.toggle()
            HapticEngine.play(.success)
            busy = false
        }
    }
}
