import SwiftUI

// MARK: - Challenge Type

public enum HeroChallenge: String, Codable, CaseIterable {
    case countToTen      = "count_to_ten"       // tap 10 times
    case jumpingJacks    = "jumping_jacks"       // tap 10 times (physical)
    case sayABCs         = "say_abcs"            // tap A–Z (26 taps)
    case giveCompliment  = "give_compliment"     // confirm tap
    case sayILoveYou     = "say_i_love_you"      // confirm tap
    case putToyAway      = "put_toy_away"        // confirm tap
    case sayPlease       = "say_please"          // confirm tap
    case forgiveSomeone  = "forgive_someone"     // confirm tap
    case deepBreath      = "deep_breath"         // 1 breath cycle

    public var title: String {
        switch self {
        case .countToTen:     return "Count to 10"
        case .jumpingJacks:   return "10 Jumping Jacks"
        case .sayABCs:        return "Say your ABCs"
        case .giveCompliment: return "Give a Compliment"
        case .sayILoveYou:    return "Say 'I Love You'"
        case .putToyAway:     return "Put a Toy Away"
        case .sayPlease:      return "Use the Word Please"
        case .forgiveSomeone: return "Forgive Someone"
        case .deepBreath:     return "Take a Deep Breath"
        }
    }

    public var instruction: String {
        switch self {
        case .countToTen:     return "Tap the button\n10 times!"
        case .jumpingJacks:   return "Do 10 jumping jacks,\nthen tap!"
        case .sayABCs:        return "Say the ABCs out loud.\nTap each letter!"
        case .giveCompliment: return "Tell someone\nsomething nice about them."
        case .sayILoveYou:    return "Say 'I love you'\nto someone!"
        case .putToyAway:     return "Put one toy\nwhere it belongs."
        case .sayPlease:      return "Say 'please'\nto someone."
        case .forgiveSomeone: return "If you're mad at anyone,\nlet it go. 💛"
        case .deepBreath:     return "Breathe in slowly…\nthen all the way out."
        }
    }

    public var emoji: String {
        switch self {
        case .countToTen:     return "🔢"
        case .jumpingJacks:   return "🏃"
        case .sayABCs:        return "🔡"
        case .giveCompliment: return "🌟"
        case .sayILoveYou:    return "❤️"
        case .putToyAway:     return "🧸"
        case .sayPlease:      return "🤝"
        case .forgiveSomeone: return "🕊️"
        case .deepBreath:     return "🌬️"
        }
    }

    /// Tap count required (0 = confirm tap; 10 = count challenges; 26 = ABCs)
    public var tapCount: Int {
        switch self {
        case .countToTen, .jumpingJacks: return 10
        case .sayABCs:                   return 26
        default:                         return 1
        }
    }

    public var accentColor: Color {
        switch self {
        case .countToTen:     return .green
        case .jumpingJacks:   return .orange
        case .sayABCs:        return .blue
        case .giveCompliment: return .yellow
        case .sayILoveYou:    return .pink
        case .putToyAway:     return .teal
        case .sayPlease:      return .purple
        case .forgiveSomeone: return .white
        case .deepBreath:     return .cyan
        }
    }
}

// MARK: - HeroGate View

/// Wraps any app content behind a daily good-deed challenge.
/// Usage: HeroGate(appKey: "omnitrix", challenge: .countToTen) { mainContent }
public struct HeroGate<Content: View>: View {
    let appKey: String
    let challenge: HeroChallenge
    let accentColor: Color
    @ViewBuilder let content: () -> Content

    @State private var unlocked: Bool = false
    @State private var tapsDone: Int = 0
    @State private var phase: GatePhase = .locked
    @State private var coreScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0
    @State private var celebrateScale: CGFloat = 1.0
    @State private var currentLetter: Int = 0  // for ABCs

    private enum GatePhase { case locked, inProgress, unlocking, done }

    private var storageKey: String { "herogate.unlock.\(appKey)" }
    private var todayString: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date())
    }

    public init(appKey: String, challenge: HeroChallenge, accentColor: Color? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.appKey = appKey
        self.challenge = challenge
        self.accentColor = accentColor ?? challenge.accentColor
        self.content = content
    }

    public var body: some View {
        Group {
            if unlocked {
                content()
            } else {
                gateView
            }
        }
        .onAppear { checkUnlock() }
    }

    // MARK: Gate UI

    private var gateView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if phase == .done {
                unlockCelebration
            } else {
                challengeUI
            }
        }
    }

    private var challengeUI: some View {
        VStack(spacing: 6) {
            // Header
            Text("⚡ POWER UP")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(accentColor.opacity(0.7))
                .kerning(1.5)

            Text(challenge.emoji)
                .font(.system(size: 28))
                .scaleEffect(coreScale)

            Text(challenge.instruction)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal, 4)

            // Progress indicator for tap challenges
            if challenge.tapCount > 1 {
                progressDots
            }

            // Action button
            actionButton
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var progressDots: some View {
        let total = challenge.tapCount
        let done = tapsDone
        // For ABCs show letter; for counts show dots
        if challenge == .sayABCs {
            Text(done < 26 ? String(UnicodeScalar(65 + done)!) : "✓")
                .font(.system(size: 22, weight: .black, design: .monospaced))
                .foregroundColor(accentColor)
        } else {
            HStack(spacing: 4) {
                ForEach(0..<min(total, 10), id: \.self) { i in
                    Circle()
                        .fill(i < done ? accentColor : Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }

    private var actionButton: some View {
        let label: String = {
            if challenge.tapCount == 1 {
                return "Done! ✓"
            } else if tapsDone >= challenge.tapCount {
                return "Unlock! ⚡"
            } else if challenge == .sayABCs {
                return tapsDone == 0 ? "Start — tap A" : "Tap \(String(UnicodeScalar(65 + tapsDone)!))"
            } else {
                return tapsDone == 0 ? "Start — tap!" : "Tap! (\(tapsDone)/\(challenge.tapCount))"
            }
        }()

        return Button(action: handleTap) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(tapsDone >= challenge.tapCount ? accentColor : accentColor.opacity(0.7))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var unlockCelebration: some View {
        VStack(spacing: 6) {
            Text("⚡")
                .font(.system(size: 36))
                .scaleEffect(celebrateScale)

            Text("POWERED UP!")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(accentColor)

            Text("You earned it! 🎉")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: Logic

    private func checkUnlock() {
        let saved = UserDefaults.standard.string(forKey: storageKey) ?? ""
        unlocked = (saved == todayString)
    }

    private func handleTap() {
        HapticEngine.play(.tap)
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { coreScale = 1.2 }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) { coreScale = 1.0 }

        if challenge.tapCount == 1 {
            // Single-confirm challenges
            completeChallenge()
        } else {
            tapsDone += 1
            if tapsDone >= challenge.tapCount {
                HapticEngine.play(.success)
                completeChallenge()
            } else {
                HapticEngine.play(.click)
            }
        }
    }

    private func completeChallenge() {
        phase = .done
        HapticEngine.play(.surge)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
            celebrateScale = 1.5
            glowOpacity = 1
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2)) {
            celebrateScale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            HapticEngine.play(.success)
        }

        // Persist unlock for today
        UserDefaults.standard.set(todayString, forKey: storageKey)

        // Wait for celebration then open app
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeIn(duration: 0.2)) { unlocked = true }
        }
    }
}
