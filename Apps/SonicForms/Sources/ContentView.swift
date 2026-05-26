import SwiftUI
import HeroKit

struct ContentView: View {
    @State private var formIndex: Int = 0
    @State private var crownValue: Double = 0
    @State private var lastCrownIndex: Int = 0
    @State private var isTransforming = false
    @State private var transformScale: CGFloat = 1.0
    @State private var transformRotation: Double = 0
    @State private var emeralds: [ChaosEmerald] = StorageKit.load(
        [ChaosEmerald].self, key: "sonic.emeralds", default: ChaosEmerald.all)
    @State private var showEmeraldFlash = false
    @State private var crownActive = false
    @State private var moveOpacity: Double = 0

    private var allCollected: Bool { emeralds.allSatisfy(\.collected) }
    private var currentForm: SonicForm {
        let forms = SonicForm.all
        if forms[formIndex].isLocked && !allCollected {
            return SonicForm.all[0]
        }
        return forms[formIndex]
    }

    var body: some View {
        ZStack {
            currentForm.color.opacity(0.15).ignoresSafeArea()

            VStack(spacing: 4) {
                // Emerald progress strip
                HStack(spacing: 3) {
                    ForEach(emeralds) { gem in
                        Text(gem.collected ? gem.emoji : "⬜")
                            .font(.system(size: 10))
                    }
                }
                .padding(.top, 2)

                Spacer()

                // Hero emblem
                Text(currentForm.emoji)
                    .font(.system(size: 42))
                    .scaleEffect(transformScale)
                    .rotationEffect(.degrees(transformRotation))
                    .shadow(color: currentForm.color, radius: 12)

                Text(currentForm.name)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text(currentForm.tagline)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                // Crown move label
                Text("▲▼ \(currentForm.crownMove)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(currentForm.color)
                    .opacity(moveOpacity)

                Spacer()
            }
            .padding(.horizontal, 6)
        }
        .focusable(true)
        .digitalCrownRotation($crownValue, from: 0, through: Double(SonicForm.all.count - 1), by: 1, sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
        .onChange(of: crownValue) { newVal in
            let idx = Int(newVal.rounded())
            guard idx != lastCrownIndex else { return }
            lastCrownIndex = idx
            switchForm(to: idx)
        }
        .onTapGesture { activateMove() }
    }

    private func switchForm(to idx: Int) {
        let target = SonicForm.all[idx]
        if target.isLocked && !allCollected { return }
        formIndex = idx
        HapticEngine.play(target.haptic)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { transformScale = 1.3 }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15)) { transformScale = 1.0 }

        // Flash the Crown move label
        withAnimation(.easeIn(duration: 0.1)) { moveOpacity = 1 }
        withAnimation(.easeOut(duration: 0.8).delay(1.0)) { moveOpacity = 0 }
    }

    private func activateMove() {
        guard !isTransforming else { return }
        isTransforming = true
        HapticEngine.play(currentForm.haptic)

        withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) { transformScale = 1.5 }

        if currentForm.id == 0 { // Sonic spin dash
            withAnimation(.linear(duration: 0.4)) { transformRotation += 360 }
        } else if currentForm.id == 3 { // Shadow chaos control
            withAnimation(.easeOut(duration: 0.2)) { transformScale = 0.01 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { transformScale = 1.0 }
            }
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2)) { transformScale = 1.0 }

        // Collect a random uncollected emerald on power use
        if let gemIdx = emeralds.indices.filter({ !emeralds[$0].collected }).randomElement() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                emeralds[gemIdx].collected = true
                StorageKit.save(emeralds, key: "sonic.emeralds")
                HapticEngine.play(.success)

                if allCollected {
                    // Super Sonic is now unlocked — trigger celebration
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) { transformScale = 1.6 }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.2)) { transformScale = 1.0 }
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { isTransforming = false }
    }
}
