import SwiftUI
import HeroKit

private enum TransformState { case robot, vehicle }

struct ContentView: View {
    @State private var selectedIdx: Int = 0
    @State private var crownValue: Double = 0
    @State private var transformState: TransformState = .robot
    @State private var isAnimating = false
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var skew: CGFloat = 0
    @State private var glowOpacity: Double = 0
    @State private var faction: Faction = .autobot

    private var bot: Transformer { Transformer.all[selectedIdx] }
    private var modeLabel: String {
        transformState == .robot ? bot.name : (bot.beastMode ?? bot.vehicleMode)
    }
    private var modeEmoji: String {
        transformState == .robot ? bot.emblem : (bot.beastMode != nil ? bot.beastMode! : bot.vehicleMode)
    }

    var body: some View {
        ZStack {
            bot.color.opacity(0.12).ignoresSafeArea()

            // Glow burst during transform
            Circle()
                .fill(bot.color.opacity(0.3))
                .frame(width: 120, height: 120)
                .blur(radius: 20)
                .opacity(glowOpacity)

            VStack(spacing: 4) {
                // Faction strip
                HStack(spacing: 6) {
                    ForEach(Faction.allCases, id: \.self) { f in
                        Text(f.emblem)
                            .font(.system(size: 11))
                            .opacity(f == bot.faction ? 1 : 0.25)
                    }
                }
                .padding(.top, 2)

                Spacer()

                // Main emblem
                Text(modeEmoji)
                    .font(.system(size: 40))
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .transformEffect(.init(a: 1, b: 0, c: skew, d: 1, tx: 0, ty: 0))

                Text(modeLabel)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(transformState == .robot ? "TAP TO TRANSFORM" : "TAP TO ROLL OUT")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(bot.color.opacity(0.8))
                    .kerning(1)

                Spacer()
            }
            .padding(.horizontal, 6)
        }
        .focusable(true)
        .digitalCrownRotation($crownValue, from: 0, through: Double(Transformer.all.count - 1), by: 1, sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
        .onChange(of: crownValue) { newVal in
            let idx = Int(newVal.rounded())
            guard idx != selectedIdx else { return }
            selectedIdx = idx
            transformState = .robot
            HapticEngine.play(.click)
        }
        .onTapGesture { toggleTransform() }
    }

    private func toggleTransform() {
        guard !isAnimating else { return }
        isAnimating = true

        HapticEngine.play(.surge)

        // Mechanical shudder sequence
        let shudderTimes = [0.0, 0.08, 0.16, 0.24, 0.32]
        for (i, t) in shudderTimes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                HapticEngine.play(i.isMultiple(of: 2) ? .click : .tap)
            }
        }

        // Visual: shear → scale flash → settle
        withAnimation(.easeInOut(duration: 0.1)) { skew = 0.3 }
        withAnimation(.easeInOut(duration: 0.1).delay(0.1)) { skew = -0.3 }
        withAnimation(.easeInOut(duration: 0.1).delay(0.2)) { skew = 0 }

        withAnimation(.spring(response: 0.2, dampingFraction: 0.3).delay(0.15)) { scale = 1.5 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.35)) { scale = 1.0 }

        withAnimation(.easeIn(duration: 0.15).delay(0.2)) { glowOpacity = 1 }
        withAnimation(.easeOut(duration: 0.4).delay(0.35)) { glowOpacity = 0 }

        // Beast Wars: spin on transform
        if bot.beastMode != nil {
            withAnimation(.linear(duration: 0.3).delay(0.1)) { rotation += 360 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            transformState = (transformState == .robot) ? .vehicle : .robot
            HapticEngine.play(.success)
            isAnimating = false
        }
    }
}
