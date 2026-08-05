import SwiftUI

// MARK: - Affirmations (public so ParkersHeart can display them too)

public let heroAffirmations: [String] = [
    "I am brave.",
    "I am kind.",
    "I am a good friend.",
    "I am smart.",
    "I am strong.",
    "I try my best.",
    "I am funny.",
    "I make people happy.",
    "I am loved.",
    "I can do hard things.",
    "I am special.",
    "I am enough.",
]

// MARK: - Challenge Type

public enum HeroChallenge: String, Codable, CaseIterable {
    case countToTen      = "count_to_ten"
    case jumpingJacks    = "jumping_jacks"
    case giveCompliment  = "give_compliment"
    case sayILoveYou     = "say_i_love_you"
    case putToyAway      = "put_toy_away"
    case forgiveSomeone  = "forgive_someone"
    case selfAffirmation = "self_affirmation"
    case deepBreath      = "deep_breath"

    public var title: String {
        switch self {
        case .countToTen:     return "Count to 10"
        case .jumpingJacks:   return "10 Jumping Jacks"
        case .giveCompliment: return "Give a Compliment"
        case .sayILoveYou:    return "Say 'I Love You'"
        case .putToyAway:     return "Put a Toy Away"
        case .forgiveSomeone: return "Forgive Someone"
        case .selfAffirmation:return "Say Something Great About You"
        case .deepBreath:     return "Take a Deep Breath"
        }
    }

    public var emoji: String {
        switch self {
        case .countToTen:     return "🔢"
        case .jumpingJacks:   return "🏃"
        case .giveCompliment: return "🌟"
        case .sayILoveYou:    return "❤️"
        case .putToyAway:     return "🧸"
        case .forgiveSomeone: return "🕊️"
        case .selfAffirmation:return "💛"
        case .deepBreath:     return "🌬️"
        }
    }

    public var tapCount: Int {
        switch self {
        case .countToTen, .jumpingJacks: return 10
        default:                         return 1
        }
    }

    public var accentColor: Color {
        switch self {
        case .countToTen:     return .green
        case .jumpingJacks:   return .orange
        case .giveCompliment: return .yellow
        case .sayILoveYou:    return .pink
        case .putToyAway:     return .teal
        case .forgiveSomeone: return .white
        case .selfAffirmation:return Color(red: 1, green: 0.85, blue: 0.2)
        case .deepBreath:     return .cyan
        }
    }
}

// MARK: - HeroGate View

public struct HeroGate<Content: View>: View {
    let appKey: String
    let challengePool: [HeroChallenge]
    let accentColorOverride: Color?
    @ViewBuilder let content: () -> Content

    @Environment(\.scenePhase) private var scenePhase

    @State private var unlocked = false
    @State private var activeChallenge: HeroChallenge = .giveCompliment
    @State private var tapsDone = 0
    @State private var phase: GatePhase = .challenge
    @State private var coreScale: CGFloat = 1.0
    @State private var celebrateScale: CGFloat = 1.0
    @State private var bgPulse: CGFloat = 1.0

    // Affirmation gate state
    @State private var affirmationIndex: Int = 0
    @State private var affirmationCrown: Double = 0

    // Deep breath gate state
    @State private var breathPhase: BreathPhase = .ready
    @State private var breathScale: CGFloat = 0.55
    @State private var breathOpacity: Double = 0.6
    @State private var breathId = UUID()

    private enum GatePhase { case challenge, celebrating }
    private enum BreathPhase { case ready, inhale, hold, exhale, done }

    private var accent: Color { accentColorOverride ?? activeChallenge.accentColor }
    private var randomChallengeIndex: Int { Int.random(in: 0..<challengePool.count) }
    private var randomAffirmationIndex: Int { Int.random(in: 0..<heroAffirmations.count) }

    // Single fixed challenge (backwards compatibility)
    public init(appKey: String, challenge: HeroChallenge, accentColor: Color? = nil,
                @ViewBuilder content: @escaping () -> Content) {
        self.appKey = appKey
        self.challengePool = [challenge]
        self.accentColorOverride = accentColor
        self.content = content
    }

    // Random challenge pool — picks a new one every foreground activation
    public init(appKey: String, challenges: [HeroChallenge], accentColor: Color? = nil,
                @ViewBuilder content: @escaping () -> Content) {
        self.appKey = appKey
        self.challengePool = challenges.isEmpty ? [.giveCompliment] : challenges
        self.accentColorOverride = accentColor
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
        .onAppear {
            resetGate()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active && !unlocked {
                resetGate()
            }
        }
    }

    // MARK: - Reset (called on every foreground)

    private func resetGate() {
        unlocked = false
        tapsDone = 0
        phase = .challenge
        activeChallenge = challengePool[randomChallengeIndex]
        affirmationIndex = randomAffirmationIndex
        affirmationCrown = Double(affirmationIndex)
        breathPhase = .ready
        breathScale = 0.55
        breathOpacity = 0.6
        breathId = UUID()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SpeechEngine.shared.speak(instructionText)
        }
    }

    // MARK: - Gate root

    private var gateView: some View {
        ZStack {
            // Colored background matching the challenge
            accent.opacity(0.18).ignoresSafeArea()
            Color.black.opacity(0.55).ignoresSafeArea()

            if phase == .celebrating {
                celebration
            } else {
                switch activeChallenge {
                case .selfAffirmation: affirmationGate
                case .deepBreath:      breathGate.id(breathId)
                default:               standardGate
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: activeChallenge.rawValue)
    }

    // MARK: - Standard tap gate

    private var standardGate: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.25))
                    .frame(width: 80, height: 80)
                Text(activeChallenge.emoji)
                    .font(.system(size: 44))
                    .scaleEffect(coreScale)
            }

            Text(instructionText)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 8)

            if activeChallenge.tapCount > 1 {
                tapDots
            }

            Button(action: handleStandardTap) {
                Text(buttonLabel)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(tapsDone >= activeChallenge.tapCount ? accent : accent.opacity(0.75))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }

    private var tapDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<activeChallenge.tapCount, id: \.self) { i in
                Circle()
                    .fill(i < tapsDone ? accent : Color.white.opacity(0.2))
                    .frame(width: 7, height: 7)
            }
        }
    }

    private var instructionText: String {
        switch activeChallenge {
        case .giveCompliment: return "Say something nice to someone! 🌟"
        case .sayILoveYou:    return "Say I love you to someone! ❤️"
        case .putToyAway:     return "Put one toy away! 🧸"
        case .forgiveSomeone: return "Let go of any anger. 🕊️"
        case .countToTen:     return "Tap 10 times!"
        case .jumpingJacks:   return "Do 10 jumping jacks!"
        default:              return activeChallenge.title
        }
    }

    private var buttonLabel: String {
        if activeChallenge.tapCount == 1 { return "Done! ✓" }
        if tapsDone >= activeChallenge.tapCount { return "Unlock! ⚡" }
        return tapsDone == 0 ? "Tap — go!" : "\(tapsDone) / \(activeChallenge.tapCount)"
    }

    private func handleStandardTap() {
        HapticEngine.play(.click)
        bump()
        if activeChallenge.tapCount == 1 {
            complete()
        } else {
            tapsDone += 1
            if tapsDone >= activeChallenge.tapCount {
                HapticEngine.play(.success)
                complete()
            }
        }
    }

    // MARK: - Self-affirmation gate

    private var affirmationGate: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.25))
                    .frame(width: 70, height: 70)
                Text(activeChallenge.emoji)
                    .font(.system(size: 38))
                    .scaleEffect(coreScale)
            }

            Text("Say this out loud:")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            Text(heroAffirmations[affirmationIndex])
                .font(.system(size: 18, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: affirmationIndex)

            Text("▲▼ Crown to change")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.3))

            Button(action: { HapticEngine.play(.surge); complete() }) {
                Text("I believe it! ✓")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(accent)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .focusable(true)
        .digitalCrownRotation($affirmationCrown,
                               from: 0, through: Double(heroAffirmations.count - 1),
                               by: 1, sensitivity: .medium,
                               isContinuous: true, isHapticFeedbackEnabled: true)
        .onChange(of: affirmationCrown) { val in
            let idx = Int(val.rounded()) % heroAffirmations.count
            let wrapped = (idx + heroAffirmations.count) % heroAffirmations.count
            if wrapped != affirmationIndex {
                affirmationIndex = wrapped
                HapticEngine.play(.click)
                bump()
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Deep breath gate (auto-completes after 1 cycle)

    private var breathGate: some View {
        ZStack {
            Circle()
                .fill(Color.cyan.opacity(0.12))
                .frame(width: 110, height: 110)
                .blur(radius: breathPhase == .inhale ? 18 : 0)
                .animation(.easeInOut(duration: 1), value: breathPhase)

            Circle()
                .fill(RadialGradient(
                    colors: [Color.cyan.opacity(0.85), Color.cyan.opacity(0.25)],
                    center: .center, startRadius: 4, endRadius: 40))
                .frame(width: 75, height: 75)
                .scaleEffect(breathScale)
                .opacity(breathOpacity)

            VStack(spacing: 0) {
                Spacer()
                breathLabel
                    .padding(.bottom, 8)
            }
        }
        .onAppear { startBreathGate() }
    }

    @ViewBuilder
    private var breathLabel: some View {
        switch breathPhase {
        case .ready:
            Text("One breath\nto unlock… 🌬️")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.7))
        case .inhale:
            Text("Breathe in…")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.cyan)
        case .hold:
            Text("Hold…")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        case .exhale:
            Text("Breathe out…")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.cyan.opacity(0.7))
        case .done:
            Text("✓")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.cyan)
        }
    }

    private func startBreathGate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard breathPhase == .ready else { return }
            breathPhase = .inhale
            HapticEngine.play(.heartbeat)
            withAnimation(.easeInOut(duration: 3.5)) {
                breathScale = 1.0
                breathOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                guard breathPhase == .inhale else { return }
                breathPhase = .hold
                HapticEngine.play(.click)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    guard breathPhase == .hold else { return }
                    breathPhase = .exhale
                    HapticEngine.play(.heartbeat)
                    withAnimation(.easeInOut(duration: 4.0)) {
                        breathScale = 0.55
                        breathOpacity = 0.6
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        guard breathPhase == .exhale else { return }
                        breathPhase = .done
                        complete()
                    }
                }
            }
        }
    }

    // MARK: - Celebration

    private var celebration: some View {
        VStack(spacing: 8) {
            Text("⚡")
                .font(.system(size: 48))
                .scaleEffect(celebrateScale)
            Text("POWERED UP!")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(accent)
            Text("You earned it! 🎉")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    // MARK: - Shared helpers

    private func bump() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { coreScale = 1.2 }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) { coreScale = 1.0 }
    }

    private func complete() {
        phase = .celebrating
        HapticEngine.play(.surge)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) { celebrateScale = 1.5 }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2)) { celebrateScale = 1.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { HapticEngine.play(.success) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeIn(duration: 0.2)) { unlocked = true }
        }
    }
}
