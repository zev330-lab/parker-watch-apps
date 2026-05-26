import SwiftUI
import AVFoundation
import HeroKit

private let defaultHappyThings: [String] = [
    "Mom's hugs 🤗", "Dad's hugs 🤗",
    "My dog 🐶", "Superheroes 🦸",
    "Ben 10 👽", "Karate class 🥋",
    "Pizza 🍕", "Minecraft ⛏️",
    "Swimming 🏊", "Silly jokes 😂",
    "Snuggling in bed 😴", "Being brave 💪",
]

private let defaultDadMessages: [String] = [
    "I love you, Parker.",
    "You are so brave.",
    "I am thinking of you right now.",
    "You make me so proud.",
    "Have the best day ever!",
    "You are strong and kind.",
    "I will be home soon.",
    "You are my favorite Parker.",
]

// MARK: - Root

struct ContentView: View {
    var body: some View {
        TabView {
            HappyPage().tag(0)
            DadPage().tag(1)
            SuperpowersPage().tag(2)
        }
        .tabViewStyle(.page)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Happy Things

struct HappyPage: View {
    @State private var items: [String] = StorageKit.load([String].self, key: "heart.happy", default: defaultHappyThings)
    @State private var current = "Tap for something happy!"
    @State private var scale: CGFloat = 1.0
    @State private var bgColor: Color = .purple
    private let colors: [Color] = [.purple, .pink, .orange, .blue, .green, .teal, .indigo]
    @State private var colorIdx = 0

    var body: some View {
        ZStack {
            bgColor.opacity(0.18).ignoresSafeArea()
            VStack(spacing: 6) {
                Text("HAPPY THINGS")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.4)).kerning(1)
                Text("💛")
                    .font(.system(size: 28)).scaleEffect(scale)
                Text(current)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center).foregroundColor(.white)
                    .scaleEffect(scale).padding(.horizontal, 6)
            }
        }
        .onTapGesture {
            guard !items.isEmpty else { return }
            HapticEngine.play(.surge)
            colorIdx = (colorIdx + 1) % colors.count
            bgColor = colors[colorIdx]
            current = items.randomElement()!
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { scale = 1.3 }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15)) { scale = 1.0 }
        }
    }
}

// MARK: - Dad Messages (CloudKit + speech)

struct DadPage: View {
    @AppStorage("heart.dad.idx") private var msgIdx: Int = 0
    @State private var messages: [String] = []
    @State private var isSyncing = false
    @State private var scale: CGFloat = 1.0
    @State private var heartPop = false
    @State private var isSpeaking = false

    // Retain synthesizer — must be held strongly or speech stops mid-sentence
    @State private var synth = AVSpeechSynthesizer()

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.12).ignoresSafeArea()

            VStack(spacing: 5) {
                // Header + sync indicator
                HStack(spacing: 4) {
                    Text("FROM DAD")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.35)).kerning(1)
                    if isSyncing {
                        ProgressView()
                            .scaleEffect(0.5)
                            .tint(.white.opacity(0.4))
                    }
                }

                // Envelope with floating heart
                Text("💌")
                    .font(.system(size: 26))
                    .overlay(
                        Text("💛").font(.system(size: 12))
                            .offset(x: 13, y: -13)
                            .scaleEffect(heartPop ? 1.5 : 0)
                            .opacity(heartPop ? 0 : 1)
                            .animation(.spring(response: 0.35, dampingFraction: 0.5), value: heartPop)
                    )

                // Message text
                Text(currentMessage)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .padding(.horizontal, 4)

                // Hint
                HStack(spacing: 6) {
                    Text(isSpeaking ? "🔊 speaking…" : "tap to hear it")
                        .font(.system(size: 8))
                        .foregroundColor(isSpeaking ? .white.opacity(0.6) : .white.opacity(0.25))
                    if messages.count > 1 {
                        Text("· swipe for next")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.2))
                    }
                }
            }
        }
        .onTapGesture { handleTap() }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { g in
                    // Horizontal swipe → next/prev message
                    guard abs(g.translation.width) > abs(g.translation.height) else { return }
                    stopSpeaking()
                    if g.translation.width < 0 {
                        advance(by: 1)
                    } else {
                        advance(by: -1)
                    }
                }
        )
        .onAppear { loadAndSync() }
        .onDisappear { stopSpeaking() }
    }

    private var currentMessage: String {
        guard !messages.isEmpty else { return "Dad's sending love… 💛" }
        return messages[safe: msgIdx] ?? messages[0]
    }

    private func handleTap() {
        guard !messages.isEmpty else { return }
        HapticEngine.play(.notification)

        // Heart pop
        heartPop = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { heartPop = false }

        // Scale bounce
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { scale = 1.1 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.15)) { scale = 1.0 }

        // Speak the message
        speakCurrent()
    }

    private func speakCurrent() {
        stopSpeaking()
        let text = currentMessage
        // Strip emoji before speaking — AVSpeechSynthesizer handles some but not all well
        let clean = text.unicodeScalars
            .filter { !$0.properties.isEmojiPresentation && !$0.properties.isEmoji || $0.value < 128 }
            .reduce("") { $0 + String($1) }
            .trimmingCharacters(in: .whitespaces)

        let utterance = AVSpeechUtterance(string: clean.isEmpty ? text : clean)
        utterance.rate = 0.42          // warm, slightly slower than default
        utterance.pitchMultiplier = 1.08
        utterance.volume = 1.0
        // Pick the best available English voice
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        isSpeaking = true
        synth.speak(utterance)

        // Clear speaking flag after estimated duration
        let duration = Double(clean.count) * 0.065 + 0.8
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            isSpeaking = false
        }
    }

    private func stopSpeaking() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        isSpeaking = false
    }

    private func advance(by delta: Int) {
        guard !messages.isEmpty else { return }
        HapticEngine.play(.click)
        msgIdx = ((msgIdx + delta) % messages.count + messages.count) % messages.count
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { scale = 1.08 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1)) { scale = 1.0 }
    }

    private func loadAndSync() {
        // Show cached immediately
        let cached = CloudKitMessageStore.loadCache()
        messages = cached.isEmpty ? defaultDadMessages : cached

        // Fetch fresh from CloudKit in background
        isSyncing = true
        Task {
            if let fresh = await CloudKitMessageStore.fetch(), !fresh.isEmpty {
                CloudKitMessageStore.cache(fresh)
                await MainActor.run {
                    messages = fresh
                    // Keep index valid
                    if msgIdx >= messages.count { msgIdx = 0 }
                }
            }
            await MainActor.run { isSyncing = false }
        }
    }
}

// MARK: - My Superpowers (affirmations)

struct SuperpowersPage: View {
    @State private var myPowers: [String] = StorageKit.load([String].self, key: "heart.superpowers", default: heroAffirmations)
    @State private var crownVal: Double = 0
    @State private var currentIdx: Int = 0
    @State private var lastIdx: Int = 0
    @State private var glowScale: CGFloat = 1.0
    private let gold = Color(red: 1, green: 0.85, blue: 0.2)

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.05, blue: 0.02).ignoresSafeArea()
            VStack(spacing: 4) {
                Text("MY SUPERPOWERS")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(gold.opacity(0.6)).kerning(1)
                Text("💛")
                    .font(.system(size: 22)).scaleEffect(glowScale)
                Text(myPowers.isEmpty ? "You have so many!" : myPowers[currentIdx])
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center).foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentIdx)
                Text("say it out loud ✨")
                    .font(.system(size: 8)).foregroundColor(.white.opacity(0.3))
                Text("▲▼ Crown to browse")
                    .font(.system(size: 7)).foregroundColor(.white.opacity(0.2))
            }
        }
        .focusable(true)
        .digitalCrownRotation($crownVal,
                               from: 0, through: Double(max(myPowers.count - 1, 0)),
                               by: 1, sensitivity: .medium,
                               isContinuous: true, isHapticFeedbackEnabled: true)
        .onChange(of: crownVal) { val in
            guard !myPowers.isEmpty else { return }
            let idx = ((Int(val.rounded()) % myPowers.count) + myPowers.count) % myPowers.count
            guard idx != lastIdx else { return }
            lastIdx = idx; currentIdx = idx
            HapticEngine.play(.click)
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { glowScale = 1.2 }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.1)) { glowScale = 1.0 }
        }
        .onTapGesture {
            HapticEngine.play(.surge)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.3)) { glowScale = 1.5 }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.15)) { glowScale = 1.0 }
        }
    }
}

// MARK: - Helpers

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
