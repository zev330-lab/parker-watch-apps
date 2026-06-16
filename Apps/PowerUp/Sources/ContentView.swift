import SwiftUI
import HeroKit

// PowerUp — three pages: Breathing · Superpower · Mission

struct ContentView: View {
    var body: some View {
        TabView {
            CenterPage().tag(0)
            SuperpowerPage().tag(1)
            MissionPage().tag(2)
        }
        .tabViewStyle(.page)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Breathing

private enum BreathPhase { case idle, inhale, hold, exhale, done }

private let inhaleDur: Double = 4.0
private let holdDur:   Double = 3.5
private let exhaleDur: Double = 5.0
private let totalRounds = 3

struct CenterPage: View {
    @State private var phase: BreathPhase = .idle
    @State private var round = 0
    @State private var circleScale: CGFloat = 0.45
    @State private var bgColor: Color = .blue
    // Token approach: changing this UUID cancels any in-flight DispatchQueue chain
    @State private var cycleToken = UUID()

    var body: some View {
        ZStack {
            bgColor.opacity(0.18).ignoresSafeArea()
                .animation(.easeInOut(duration: 1), value: bgColor)

            Circle()
                .fill(bgColor.opacity(0.35))
                .frame(width: 130, height: 130)
                .scaleEffect(circleScale)
                .animation(.easeInOut(duration: phase == .inhale ? inhaleDur : phase == .exhale ? exhaleDur : 0.3), value: circleScale)

            VStack(spacing: 10) {
                phaseEmoji
                    .font(.system(size: 36))
                phaseText
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                roundDots
            }
        }
        .onTapGesture {
            if phase == .idle { startCycle(round: 0, token: newToken()) }
            else if phase == .done { reset() }
        }
        .onDisappear {
            // Cancel any in-flight breathing chain when user swipes away
            cycleToken = UUID()
            SpeechEngine.shared.stop()
            if phase != .done { reset() }
        }
    }

    @ViewBuilder private var phaseEmoji: some View {
        switch phase {
        case .idle:   Text("🌬️")
        case .inhale: Text("⬆️")
        case .hold:   Text("⏸️")
        case .exhale: Text("⬇️")
        case .done:   Text("💪")
        }
    }

    @ViewBuilder private var phaseText: some View {
        switch phase {
        case .idle:
            VStack(spacing: 4) {
                Text("Breathing").foregroundColor(.white.opacity(0.8))
                Text("Tap to start").font(.system(size: 16)).foregroundColor(.white.opacity(0.4))
            }
        case .inhale: Text("Breathe IN").foregroundColor(.blue)
        case .hold:   Text("Hold it").foregroundColor(.white.opacity(0.7))
        case .exhale: Text("Breathe OUT").foregroundColor(.teal)
        case .done:   Text("Great job!").foregroundColor(.green)
        }
    }

    private var roundDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalRounds, id: \.self) { i in
                Circle()
                    .fill(i < round ? Color.white : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private func newToken() -> UUID {
        let t = UUID(); cycleToken = t; return t
    }

    private func startCycle(round r: Int, token: UUID) {
        guard cycleToken == token else { return }
        round = r
        phase = .inhale; bgColor = .blue
        circleScale = 1.0
        HapticEngine.play(.heartbeat)
        SpeechEngine.shared.speak("Breathe in")

        DispatchQueue.main.asyncAfter(deadline: .now() + inhaleDur) {
            guard self.cycleToken == token else { return }
            self.phase = .hold; self.bgColor = .white
            HapticEngine.play(.click)
            SpeechEngine.shared.speak("Hold it")

            DispatchQueue.main.asyncAfter(deadline: .now() + holdDur) {
                guard self.cycleToken == token else { return }
                self.phase = .exhale; self.bgColor = .teal
                self.circleScale = 0.45
                HapticEngine.play(.heartbeat)
                SpeechEngine.shared.speak("Breathe out")

                DispatchQueue.main.asyncAfter(deadline: .now() + exhaleDur) {
                    guard self.cycleToken == token else { return }
                    let nextRound = r + 1
                    if nextRound < totalRounds {
                        self.startCycle(round: nextRound, token: token)
                    } else {
                        self.phase = .done; self.bgColor = .green
                        self.round = totalRounds
                        HapticEngine.play(.success)
                        SpeechEngine.shared.speak("Great job! You did it!")
                    }
                }
            }
        }
    }

    private func reset() {
        phase = .idle; bgColor = .blue; circleScale = 0.45; round = 0
    }
}

// MARK: - Superpower Wheel

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
]

private let wheelColors: [Color] = [.blue, .purple, .red, .orange, .green, .yellow, .pink, .teal]

struct SuperpowerPage: View {
    @State private var crownVal: Double = 0
    @State private var lastIdx = 0
    @State private var currentIdx = 0
    @State private var activated = false
    @State private var activScale: CGFloat = 1.0
    @State private var bgOpacity: Double = 0.08

    var body: some View {
        ZStack {
            wheelColors[currentIdx % wheelColors.count].opacity(bgOpacity).ignoresSafeArea()
            VStack(spacing: 8) {
                Text(activated ? "⚡ ACTIVATED ⚡" : "Spin the Crown")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                Text(superpowers[currentIdx])
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .scaleEffect(activScale)
                    .padding(.horizontal, 6)
                    .minimumScaleFactor(0.7)
            }
        }
        .focusable(true)
        .digitalCrownRotation($crownVal, from: 0, through: Double(superpowers.count - 1), by: 1,
                               sensitivity: .medium, isContinuous: true, isHapticFeedbackEnabled: true)
        .onChange(of: crownVal) { val in
            let idx = ((Int(val.rounded()) % superpowers.count) + superpowers.count) % superpowers.count
            guard idx != lastIdx else { return }
            lastIdx = idx; currentIdx = idx; activated = false
            HapticEngine.play(.click)
            withAnimation(.easeOut(duration: 0.1)) { bgOpacity = 0.05 }
        }
        .onTapGesture {
            HapticEngine.play(.surge); activated = true
            SpeechEngine.shared.speak(superpowers[currentIdx])
            withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) { activScale = 1.35; bgOpacity = 0.28 }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) { activScale = 1.0 }
            withAnimation(.easeOut(duration: 1.0).delay(0.5)) { bgOpacity = 0.08 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { HapticEngine.play(.success) }
        }
    }
}

// MARK: - Mission

private let missions: [String] = [
    "Do 5 star jumps! ⭐",
    "Roar like a T-Rex! 🦖",
    "Spin around 3 times! 🌀",
    "Do 10 hops! 🦘",
    "Strike a superhero pose! 🦸",
    "Flex those muscles! 💪",
    "Do 5 push-ups! 🏋️",
    "Jump as high as you can! 🚀",
    "Make your best battle cry! ⚡",
    "Do the silliest dance! 🕺",
    "Run in place for 10 seconds! 🏃",
    "Give someone a big hug! 🤗",
    "Pretend you can fly! ✈️",
    "Do 10 jumping jacks! 🏅",
    "Balance on one foot! 🧘",
]

private let missionColors: [Color] = [.orange, .red, .purple, .green, .blue, .pink, .teal, .yellow]

private enum MissionState { case idle, doing, done }

struct MissionPage: View {
    @State private var missionIdx: Int = Int.random(in: 0..<missions.count)
    @State private var colorIdx: Int = Int.random(in: 0..<missionColors.count)
    @State private var state: MissionState = .idle
    @State private var missionScale: CGFloat = 1.0
    @State private var buttonScale: CGFloat = 1.0

    private var accent: Color { missionColors[colorIdx % missionColors.count] }

    var body: some View {
        ZStack {
            accent.opacity(state == .doing ? 0.22 : 0.10).ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: state)

            VStack(spacing: 12) {
                switch state {
                case .idle, .doing:
                    Text("⚡")
                        .font(.system(size: 32))

                    Text(missions[missionIdx])
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .scaleEffect(missionScale)
                        .padding(.horizontal, 6)
                        .minimumScaleFactor(0.7)

                    if state == .idle {
                        HStack(spacing: 8) {
                            Button(action: nextMission) {
                                Text("Skip ▶")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)

                            Button(action: startMission) {
                                Text("DO IT! ⚡")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(accent)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(buttonScale)
                        }
                    } else {
                        Button(action: completeMission) {
                            Text("DONE! ✓")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(accent)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }

                case .done:
                    Text("🏆")
                        .font(.system(size: 44))
                        .scaleEffect(missionScale)
                    Text("MISSION\nCOMPLETE!")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(accent)
                    Button(action: resetMission) {
                        Text("Next Mission ▶")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(accent)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear { SpeechEngine.shared.speak(missions[missionIdx]) }
    }

    private func nextMission() {
        HapticEngine.play(.click)
        missionIdx = (missionIdx + 1) % missions.count
        colorIdx = (colorIdx + 1) % missionColors.count
        SpeechEngine.shared.speak(missions[missionIdx])
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { missionScale = 1.15 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1)) { missionScale = 1.0 }
    }

    private func startMission() {
        HapticEngine.play(.surge)
        state = .doing
        SpeechEngine.shared.speak(missions[missionIdx])
        withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) { buttonScale = 1.2 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1)) { buttonScale = 1.0 }
    }

    private func completeMission() {
        state = .done
        HapticEngine.play(.success)
        SpeechEngine.shared.speak("Mission complete! You crushed it!")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) { missionScale = 1.4 }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2)) { missionScale = 1.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { HapticEngine.play(.heartbeat) }
    }

    private func resetMission() {
        HapticEngine.play(.click)
        missionIdx = (missionIdx + 1) % missions.count
        colorIdx = (colorIdx + 1) % missionColors.count
        state = .idle
    }
}
