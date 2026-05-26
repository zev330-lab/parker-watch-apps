import SwiftUI
import HeroKit

// Belt progression: white → yellow → orange → green → blue → purple → brown → black
private struct Belt: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let color: String // hex string for persistence
    var breathsCompleted: Int = 0
    static let breathsPerLevel = 25 // sessions, not breaths

    static let all: [Belt] = [
        Belt(id: 0, name: "White",  color: "#FFFFFF"),
        Belt(id: 1, name: "Yellow", color: "#FFD700"),
        Belt(id: 2, name: "Orange", color: "#FF8C00"),
        Belt(id: 3, name: "Green",  color: "#228B22"),
        Belt(id: 4, name: "Blue",   color: "#1E90FF"),
        Belt(id: 5, name: "Purple", color: "#8B008B"),
        Belt(id: 6, name: "Brown",  color: "#8B4513"),
        Belt(id: 7, name: "Black",  color: "#1A1A1A"),
    ]
}

private enum BreathPhase { case idle, inhale, hold, exhale, done }

struct ContentView: View {
    @State private var phase: BreathPhase = .idle
    @State private var breathCount = 0
    @State private var sessionsDone: Int = StorageKit.load(Int.self, key: "karate.sessions", default: 0)
    @State private var coreScale: CGFloat = 0.6
    @State private var coreOpacity: Double = 0.7
    @State private var glowRadius: CGFloat = 0

    private var beltLevel: Int { min(sessionsDone / Belt.breathsPerLevel, Belt.all.count - 1) }
    private var belt: Belt { Belt.all[beltLevel] }
    private var beltColor: Color { Color(hex: belt.color) ?? .white }
    private let totalBreaths = 5

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Glow ring
            Circle()
                .fill(beltColor.opacity(0.15))
                .frame(width: 110, height: 110)
                .blur(radius: glowRadius)

            // Breathing core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [beltColor.opacity(0.9), beltColor.opacity(0.3)],
                        center: .center,
                        startRadius: 5,
                        endRadius: 45
                    )
                )
                .frame(width: 80, height: 80)
                .scaleEffect(coreScale)
                .opacity(coreOpacity)

            // Label
            VStack {
                Spacer()
                phaseLabel
                    .padding(.bottom, 8)
            }

            // Belt badge top-right
            VStack {
                HStack {
                    Spacer()
                    Text(belt.name)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(beltColor.opacity(0.3))
                        .cornerRadius(4)
                        .padding(4)
                }
                Spacer()
            }
        }
        .onTapGesture { handleTap() }
    }

    @ViewBuilder
    private var phaseLabel: some View {
        switch phase {
        case .idle:
            VStack(spacing: 2) {
                Text("Center yourself.")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                Text("Tap to power up")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.4))
            }
        case .inhale:
            Text("Breathe in…")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(beltColor)
        case .hold:
            Text("Hold…")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        case .exhale:
            Text("Breathe out…")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(beltColor.opacity(0.7))
        case .done:
            VStack(spacing: 2) {
                Text("Power level: max 💪")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Tap to rest")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    private func handleTap() {
        switch phase {
        case .idle:
            startBreathing()
        case .done:
            endSession()
        default:
            break
        }
    }

    private func startBreathing() {
        breathCount = 0
        phase = .inhale
        runInhale()
    }

    private func runInhale() {
        HapticEngine.play(.heartbeat)
        withAnimation(.easeInOut(duration: 3.5)) {
            coreScale = 1.0
            coreOpacity = 1.0
            glowRadius = 20
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            phase = .hold
            runHold()
        }
    }

    private func runHold() {
        HapticEngine.play(.click)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            phase = .exhale
            runExhale()
        }
    }

    private func runExhale() {
        HapticEngine.play(.heartbeat)
        withAnimation(.easeInOut(duration: 4.0)) {
            coreScale = 0.6
            coreOpacity = 0.7
            glowRadius = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            breathCount += 1
            if breathCount >= totalBreaths {
                phase = .done
                HapticEngine.play(.success)
            } else {
                phase = .inhale
                runInhale()
            }
        }
    }

    private func endSession() {
        sessionsDone += 1
        StorageKit.save(sessionsDone, key: "karate.sessions")
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            coreScale = 0.6
            glowRadius = 0
        }
        phase = .idle
    }
}

// MARK: - Color from hex
private extension Color {
    init?(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: h).scanHexInt64(&int) else { return nil }
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
