import SwiftUI
import HeroKit

// MARK: - Shared models

private enum Universe: CaseIterable { case sonic, transformers }

// ── Sonic ──────────────────────────────────────────────────────────────────

private struct SonicForm {
    let name: String; let tagline: String; let emoji: String
    let color: Color; let haptic: HapticPattern; let move: String
    var isLocked: Bool = false

    static let all: [SonicForm] = [
        SonicForm(name: "Sonic",      tagline: "Gotta go fast!",      emoji: "💨", color: .blue,   haptic: .surge,     move: "SPIN DASH"),
        SonicForm(name: "Tails",       tagline: "I can fly!",          emoji: "✈️", color: .yellow, haptic: .click,     move: "PROPELLER"),
        SonicForm(name: "Knuckles",    tagline: "Digging deep!",       emoji: "⛏️", color: .red,    haptic: .doubleTap, move: "GROUND POUND"),
        SonicForm(name: "Shadow",      tagline: "Chaos Control!",      emoji: "🌑", color: Color(red:0.3,green:0,blue:0.4), haptic: .tap, move: "TELEPORT"),
        SonicForm(name: "Super Sonic", tagline: "UNLIMITED POWER! ⭐", emoji: "⭐", color: .yellow, haptic: .success,   move: "HYPER DASH", isLocked: true),
    ]
}

private struct Emerald: Identifiable, Codable { let id: Int; var collected = false
    static let all: [Emerald] = (0..<7).map { Emerald(id: $0) }
    static let emojis = ["💠","🔴","🟣","🟡","🟢","🩷","🤍"]
}

// ── Transformers ──────────────────────────────────────────────────────────

private struct TFBot {
    let name: String; let robotEmoji: String; let altEmoji: String
    let altLabel: String; let faction: String; let color: Color

    static let all: [TFBot] = [
        TFBot(name: "Optimus",    robotEmoji:"🔵", altEmoji:"🚛",  altLabel:"Semi Truck",  faction:"🔵", color:.blue),
        TFBot(name: "Bumblebee",  robotEmoji:"🟡", altEmoji:"🏎",  altLabel:"Sports Car",  faction:"🔵", color:.yellow),
        TFBot(name: "Megatron",   robotEmoji:"🟣", altEmoji:"✈️",  altLabel:"Jet Fighter", faction:"🟣", color:.purple),
        TFBot(name: "Starscream", robotEmoji:"🔴", altEmoji:"✈️",  altLabel:"F-15 Jet",    faction:"🟣", color:.red),
        TFBot(name: "O. Primal",  robotEmoji:"🦁", altEmoji:"🦍",  altLabel:"Gorilla",     faction:"🦁", color:.orange),
        TFBot(name: "Cheetor",    robotEmoji:"🟡", altEmoji:"🐆",  altLabel:"Cheetah",     faction:"🦁", color:.yellow),
    ]
}

// MARK: - Root ContentView

struct ContentView: View {
    @State private var universe: Universe = .sonic
    @State private var crownVal: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            // Universe toggle strip
            HStack(spacing: 0) {
                ForEach(Universe.allCases, id: \.self) { u in
                    Button(action: { switchTo(u) }) {
                        Text(u == .sonic ? "💨 Sonic" : "⚙️ TF")
                            .font(.system(size: 10, weight: universe == u ? .black : .light))
                            .foregroundColor(universe == u ? .white : .white.opacity(0.35))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(universe == u ? Color.white.opacity(0.12) : .clear)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.white.opacity(0.06))

            Divider().background(Color.white.opacity(0.1))

            // Active universe view
            if universe == .sonic {
                SonicView(crownVal: $crownVal)
            } else {
                TransformersView(crownVal: $crownVal)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func switchTo(_ u: Universe) {
        guard u != universe else { return }
        HapticEngine.play(.click)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { universe = u }
        crownVal = 0
    }
}

// MARK: - Sonic Universe

struct SonicView: View {
    @Binding var crownVal: Double
    @State private var formIdx = 0
    @State private var lastIdx = 0
    @State private var emeralds: [Emerald] = StorageKit.load([Emerald].self, key: "garage.sonic.gems", default: Emerald.all)
    @State private var scale: CGFloat = 1.0
    @State private var spin: Double = 0
    @State private var busy = false

    private var allCollected: Bool { emeralds.allSatisfy(\.collected) }
    private var form: SonicForm {
        let f = SonicForm.all[formIdx]
        return (f.isLocked && !allCollected) ? SonicForm.all[0] : f
    }

    var body: some View {
        VStack(spacing: 3) {
            // Gems
            HStack(spacing: 2) {
                ForEach(emeralds) { g in
                    Text(g.collected ? Emerald.emojis[g.id] : "⬜")
                        .font(.system(size: 9))
                }
            }
            .padding(.top, 3)

            Spacer()

            Text(form.emoji)
                .font(.system(size: 38))
                .scaleEffect(scale)
                .rotationEffect(.degrees(spin))
                .shadow(color: form.color, radius: 10)

            Text(form.name)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text(form.tagline)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable(true)
        .digitalCrownRotation($crownVal, from: 0, through: Double(SonicForm.all.count - 1),
                               by: 1, sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
        .onChange(of: crownVal) { val in
            let idx = Int(val.rounded())
            guard idx != lastIdx else { return }
            lastIdx = idx
            let target = SonicForm.all[idx]
            if target.isLocked && !allCollected { return }
            formIdx = idx
            HapticEngine.play(target.haptic)
            pop()
        }
        .onTapGesture { activate() }
    }

    private func activate() {
        guard !busy else { return }
        busy = true
        HapticEngine.play(form.haptic)
        if form.name == "Sonic" { withAnimation(.linear(duration: 0.4)) { spin += 360 } }
        pop(to: 1.45)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) { scale = 1.0 }

        if let gemIdx = emeralds.indices.filter({ !emeralds[$0].collected }).randomElement() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                emeralds[gemIdx].collected = true
                StorageKit.save(emeralds, key: "garage.sonic.gems")
                HapticEngine.play(.success)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { busy = false }
    }

    private func pop(to s: CGFloat = 1.25) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) { scale = s }
    }
}

// MARK: - Transformers Universe

struct TransformersView: View {
    @Binding var crownVal: Double
    @State private var botIdx = 0
    @State private var lastIdx = 0
    @State private var isRobot = true
    @State private var scale: CGFloat = 1.0
    @State private var skew: CGFloat = 0
    @State private var glow: Double = 0
    @State private var busy = false

    private var bot: TFBot { TFBot.all[botIdx] }

    var body: some View {
        VStack(spacing: 3) {
            // Faction dots
            HStack(spacing: 5) {
                Text("🔵 Autobots").font(.system(size: 8)).foregroundColor(.blue.opacity(0.7))
                Text("·")
                Text("🟣 Decepticons").font(.system(size: 8)).foregroundColor(.purple.opacity(0.7))
                Text("·")
                Text("🦁 Maximals").font(.system(size: 8)).foregroundColor(.orange.opacity(0.7))
            }
            .padding(.top, 3)

            Spacer()

            ZStack {
                Circle().fill(bot.color.opacity(0.2)).frame(width: 70, height: 70).blur(radius: 12).opacity(glow)
                Text(isRobot ? bot.robotEmoji : bot.altEmoji)
                    .font(.system(size: 38))
                    .scaleEffect(scale)
                    .transformEffect(.init(a: 1, b: 0, c: skew, d: 1, tx: 0, ty: 0))
            }

            Text(isRobot ? bot.name : bot.altLabel)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text(isRobot ? "TAP TO TRANSFORM" : "TAP TO ROLL OUT")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(bot.color.opacity(0.8))
                .kerning(0.5)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusable(true)
        .digitalCrownRotation($crownVal, from: 0, through: Double(TFBot.all.count - 1),
                               by: 1, sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
        .onChange(of: crownVal) { val in
            let idx = Int(val.rounded())
            guard idx != lastIdx else { return }
            lastIdx = idx
            botIdx = idx
            isRobot = true
            HapticEngine.play(.click)
            pop()
        }
        .onTapGesture { transform() }
    }

    private func transform() {
        guard !busy else { return }
        busy = true
        HapticEngine.play(.surge)

        // Shudder
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.07) {
                HapticEngine.play(i.isMultiple(of: 2) ? .click : .tap)
            }
        }
        withAnimation(.easeInOut(duration: 0.08)) { skew = 0.3 }
        withAnimation(.easeInOut(duration: 0.08).delay(0.08)) { skew = -0.3 }
        withAnimation(.easeInOut(duration: 0.08).delay(0.16)) { skew = 0 }
        withAnimation(.spring(response: 0.2, dampingFraction: 0.3).delay(0.1)) { scale = 1.5; glow = 1 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.3)) { scale = 1.0 }
        withAnimation(.easeOut(duration: 0.5).delay(0.35)) { glow = 0 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isRobot.toggle()
            HapticEngine.play(.success)
            busy = false
        }
    }

    private func pop() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { scale = 1.25 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1)) { scale = 1.0 }
    }
}
