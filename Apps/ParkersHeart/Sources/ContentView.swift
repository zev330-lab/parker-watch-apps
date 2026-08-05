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
    "I love you, Parker! 💛",
    "You are so brave!",
    "I am thinking of you right now.",
    "You make me so proud!",
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
    @State private var items: [String] = defaultHappyThings
    @State private var current = "Tap me! 💛"
    @State private var scale: CGFloat = 1.0
    @State private var bgColor: Color = .purple
    private let colors: [Color] = [.purple, .pink, .orange, .blue, .green, .teal, .indigo]
    @State private var colorIdx = 0

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            Text(current)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .scaleEffect(scale)
                .padding(12)
        }
        .onTapGesture {
            guard !items.isEmpty else { return }
            HapticEngine.play(.surge)
            colorIdx = (colorIdx + 1) % colors.count
            bgColor = colors[colorIdx]
            current = items.randomElement()!
            SpeechEngine.shared.speak(current)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) { scale = 1.25 }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15)) { scale = 1.0 }
        }
        .onAppear { syncHappyThings() }
    }

    private func syncHappyThings() {
        Task {
            if let fresh = await HappyThingsCloudKitStore.fetch(), !fresh.isEmpty {
                await MainActor.run { items = fresh }
            }
        }
    }
}

// MARK: - Dad Messages (CloudKit + speech)

struct DadPage: View {
    @AppStorage("heart.dad.idx") private var msgIdx: Int = 0
    @State private var messages: [String] = []
    @State private var isSyncing = false
    @State private var scale: CGFloat = 1.0
    @State private var isSpeaking = false
    @State private var synth = AVSpeechSynthesizer()

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.18).ignoresSafeArea()
            VStack(spacing: 10) {
                if isSyncing {
                    ProgressView().tint(.white.opacity(0.4)).scaleEffect(0.7)
                }
                Text("💌")
                    .font(.system(size: 44))
                Text(currentMessage)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .padding(.horizontal, 8)
                Text(isSpeaking ? "🔊 speaking…" : "tap to hear it")
                    .font(.system(size: 15))
                    .foregroundColor(isSpeaking ? .white.opacity(0.7) : .white.opacity(0.35))
            }
        }
        .onTapGesture { handleTap() }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { g in
                    guard abs(g.translation.width) > abs(g.translation.height) else { return }
                    stopSpeaking()
                    advance(by: g.translation.width < 0 ? 1 : -1)
                }
        )
        .onAppear { loadAndSync() }
        .onDisappear { stopSpeaking() }
    }

    private var currentMessage: String {
        guard !messages.isEmpty else { return "💛 Dad loves you!" }
        return messages[safe: msgIdx] ?? messages[0]
    }

    private func handleTap() {
        guard !messages.isEmpty else { speakCurrent(); return }
        // Advance to next message, then speak it
        msgIdx = (msgIdx + 1) % messages.count
        HapticEngine.play(.notification)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { scale = 1.12 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.15)) { scale = 1.0 }
        speakCurrent()
    }

    private func speakCurrent() {
        stopSpeaking()

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        try? session.setActive(true)

        let text = currentMessage
        let clean = text.unicodeScalars
            .filter { !$0.properties.isEmojiPresentation && !$0.properties.isEmoji || $0.value < 128 }
            .reduce("") { $0 + String($1) }
            .trimmingCharacters(in: .whitespaces)

        let utterance = AVSpeechUtterance(string: clean.isEmpty ? text : clean)
        utterance.rate = 0.42
        utterance.pitchMultiplier = 1.08
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        isSpeaking = true
        synth.speak(utterance)

        let duration = Double(clean.count) * 0.065 + 0.8
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { isSpeaking = false }
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
        let cached = CloudKitMessageStore.loadCache()
        messages = cached.isEmpty ? defaultDadMessages : cached
        isSyncing = true
        Task {
            if let fresh = await CloudKitMessageStore.fetch(), !fresh.isEmpty {
                CloudKitMessageStore.cache(fresh)
                await MainActor.run {
                    messages = fresh
                    if msgIdx >= messages.count { msgIdx = 0 }
                }
            }
            await MainActor.run { isSyncing = false }
        }
    }
}

// MARK: - My Superpowers (tap to advance)

struct SuperpowersPage: View {
    @State private var powers: [String] = heroAffirmations
    @State private var currentIdx: Int = 0
    @State private var glowScale: CGFloat = 1.0
    @State private var bgColor: Color = .indigo

    private let bgColors: [Color] = [.indigo, .purple, .blue, .teal, .green, .pink]

    var body: some View {
        ZStack {
            bgColor.opacity(0.25).ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: currentIdx)
            VStack(spacing: 10) {
                Text("⭐️")
                    .font(.system(size: 44)).scaleEffect(glowScale)
                Text(powers.isEmpty ? "You are amazing!" : powers[currentIdx])
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentIdx)
                Text("tap to change")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .onTapGesture {
            guard !powers.isEmpty else { return }
            currentIdx = (currentIdx + 1) % powers.count
            bgColor = bgColors[currentIdx % bgColors.count]
            HapticEngine.play(.click)
            let text = powers[currentIdx]
            SpeechEngine.shared.speak(text)
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { glowScale = 1.5 }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1)) { glowScale = 1.0 }
        }
        .onAppear { syncSuperpowers() }
    }

    private func syncSuperpowers() {
        Task {
            if let fresh = await SuperpowersCloudKitStore.fetch(), !fresh.isEmpty {
                await MainActor.run {
                    powers = fresh
                    if currentIdx >= powers.count { currentIdx = 0 }
                }
            }
        }
    }
}

// MARK: - Helpers

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
