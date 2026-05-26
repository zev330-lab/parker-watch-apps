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
    case countToTen      = "count_to_ten"       // tap 10 times
    case jumpingJacks    = "jumping_jacks"       // tap 10 times (physical)
    case giveCompliment  = "give_compliment"     // confirm tap
    case sayILoveYou     = "say_i_love_you"      // confirm tap
    case putToyAway      = "put_toy_away"        // confirm tap
    case forgiveSomeone  = "forgive_someone"     // confirm tap
    case selfAffirmation = "self_affirmation"    // say something great about yourself
    case deepBreath      = "deep_breath"         // 1 guided breath cycle (auto-completes)

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
        case .selfAffirmation:return Color(red: 1, green: 0.85, blue: 0.2) // warm gold
        case .deepBreath:     return .cyan
        }
    }
}

// MARK: - HeroGate View

public struct HeroGate<Content: View>: View {
    let appKey: String
    let challenge: HeroChallenge
    let accentColor: Color
    @ViewBuilder let content: () -> Content

    @State private var unlocked = false
    @State private var tapsDone = 0
    @State private var phase: GatePhase = .challenge
    @State private var coreScale: CGFloat = 1.0
    @State private var celebrateScale: CGFloat = 1.0

    // Affirmation gate state
    @State private var affirmationIndex: Int = 0
    @State private var affirmationCrown: Double = 0

    // Deep breath gate state
    @State private var breathPhase: BreathPhase = .ready
    @State private var breathScale: CGFloat = 0.55
    @State private var breathOpacity: Double = 0.6

    private enum GatePhase { case challenge, celebrating }
    private enum BreathPhase { case ready, inhale, hold, exhale, done }

    private var storageKey: String { "herogate.unlock.\(appKey)" }
    private var todayString: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date())
    }
    private var todayAffirmationIndex: Int {
        let cal = Calendar.current
        return cal.ordinality(of: .day, in: .year, for: Date())! % heroAffirmations.count
    }

    public init(appKey: String, challenge: HeroChallenge, accentColor: Color? = nil,
                @ViewBuilder content: @escaping () -> Content) {
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
        .onAppear {
            let saved = UserDefaults.standard.string(forKey: storageKey) ?? ""
            unlocked = (saved == todayString)
            affirmationIndex = todayAffirmationIndex
            affirmationCrown = Double(affirmationIndex)
        }
    }

    // MARK: - Gate root

    private var gateView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if phase == .celebrating {
                celebration
            } else {
                switch challenge {
                case .selfAffirmation: affirmationGate
                case .deepBreath:      breathGate
                default:               standardGate
                }
            }
        }
    }

    // MARK: - Standard tap gate

    private var standardGate: some View {
        VStack(spacing: 5) {
            Text("⚡ POWER UP")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(accentColor.opacity(0.7))
                .kerning(1.5)

            Text(challenge.emoji)
                .font(.system(size: 28))
                .scaleEffect(coreScale)

            Text(instructionText)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal, 4)

            if challenge.tapCount > 1 {
                tapDots
            }

            Button(action: handleStandardTap) {
                Text(buttonLabel)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(tapsDone >= challenge.tapCount ? accentColor : accentColor.opacity(0.75))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var tapDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<challenge.tapCount, id: \.self) { i in
                Circle()
                    .fill(i < tapsDone ? accentColor : Color.white.opacity(0.2))
                    .frame(width: 7, height: 7)
            }
        }
    }

    private var instructionText: String {
        switch challenge {
        case .giveCompliment: return "Tell someone\nsomething nice about them."
        case .sayILoveYou:    return "Say 'I love you'\nto someone!"
        case .putToyAway:     return "Put one toy\nwhere it belongs."
        case .forgiveSomeone: return "If you're mad at anyone,\nlet it go. 💛"
        case .countToTen:     return "Tap the button\n10 times!"
        case .jumpingJacks:   return "Do 10 jumping jacks —\ntap each one!"
        default:              return challenge.title
        }
    }

    private var buttonLabel: String {
        if challenge.tapCount == 1 { return "Done! ✓" }
        if tapsDone >= challenge.tapCount { return "Unlock! ⚡" }
        return tapsDone == 0 ? "Tap — go!" : "\(tapsDone) / \(challenge.tapCount)"
    }

    private func handleStandardTap() {
        HapticEngine.play(.click)
        bump()
        if challenge.tapCount == 1 {
            complete()
        } else {
            tapsDone += 1
            if tapsDone >= challenge.tapCount {
                HapticEngine.play(.success)
                complete()
            }
        }
    }

    // MARK: - Self-affirmation gate

    private var affirmationGate: some View {
        VStack(spacing: 5) {
            Text("Before you power up —")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            Text("Say this\nout loud: 💛")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(accentColor.opacity(0.8))
                .multilineTextAlignment(.center)

            Text(heroAffirmations[affirmationIndex])
                .font(.system(size: 14, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .scaleEffect(coreScale)
                .padding(.horizontal, 4)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: affirmationIndex)

            Text("▲▼ Crown to change")
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.3))

            Button(action: { HapticEngine.play(.surge); complete() }) {
                Text("I believe it! ✓")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(accentColor)
                    .cornerRadius(8)
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
            breathPhase = .inhale
            HapticEngine.play(.heartbeat)
            withAnimation(.easeInOut(duration: 3.5)) {
                breathScale = 1.0
                breathOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                breathPhase = .hold
                HapticEngine.play(.click)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    breathPhase = .exhale
                    HapticEngine.play(.heartbeat)
                    withAnimation(.easeInOut(duration: 4.0)) {
                        breathScale = 0.55
                        breathOpacity = 0.6
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        breathPhase = .done
                        complete()
                    }
                }
            }
        }
    }

    // MARK: - Celebration

    private var celebration: some View {
        VStack(spacing: 6) {
            Text("⚡")
                .font(.system(size: 36))
                .scaleEffect(celebrateScale)
            Text("POWERED UP!")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(accentColor)
            Text("You earned it! 🎉")
                .font(.system(size: 10))
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
        UserDefaults.standard.set(todayString, forKey: storageKey)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeIn(duration: 0.2)) { unlocked = true }
        }
    }
}
