import SwiftUI
import HeroKit

// Parker's Heart — three pages: Happy Things · Dad Messages · My Superpowers
// Navigate by swiping left/right between the pages.

private let defaultHappyThings: [String] = [
    "Mom's hugs 🤗", "Dad's hugs 🤗",
    "My dog 🐶", "Superheroes 🦸",
    "Ben 10 👽", "Karate class 🥋",
    "Pizza 🍕", "Minecraft ⛏️",
    "Swimming 🏊", "Silly jokes 😂",
    "Snuggling in bed 😴", "Being brave 💪",
]

private let defaultDadMessages: [String] = [
    "I love you, Parker. ❤️",
    "You are SO brave.",
    "I'm thinking of you right now.",
    "You make me so proud.",
    "Have the best day ever! 🌟",
    "You are strong AND kind.",
    "I'll be home soon. 🏠",
    "You're my favorite Parker.",
]

struct ContentView: View {
    var body: some View {
        TabView {
            HappyPage()
                .tag(0)
            DadPage()
                .tag(1)
            SuperpowersPage()
                .tag(2)
        }
        .tabViewStyle(.page)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Happy Things

struct HappyPage: View {
    @State private var items: [String] = StorageKit.load([String].self, key: "heart.happy", default: defaultHappyThings)
    @State private var current = "Tap ❤️ for something happy!"
    @State private var scale: CGFloat = 1.0
    @State private var bgColor: Color = .purple
    private let colors: [Color] = [.purple, .pink, .orange, .blue, .green, .teal, .indigo]
    @State private var colorIdx = 0

    var body: some View {
        ZStack {
            bgColor.opacity(0.18).ignoresSafeArea()
            VStack(spacing: 6) {
                Text("HAPPY THINGS")
                    .font(.system(size: 8, weight: .bold)).foregroundColor(.white.opacity(0.4)).kerning(1)
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

// MARK: - Dad Messages

struct DadPage: View {
    @AppStorage("heart.dad.data") private var messagesData: Data = Data()
    @AppStorage("heart.dad.idx") private var msgIdx: Int = 0
    @State private var messages: [String] = []
    @State private var scale: CGFloat = 1.0
    @State private var heartPop = false
    @State private var isEditing = false

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.12).ignoresSafeArea()
            if isEditing {
                DadEditView(messages: $messages, onDone: {
                    messagesData = (try? JSONEncoder().encode(messages)) ?? Data()
                    isEditing = false
                })
            } else {
                VStack(spacing: 5) {
                    Text("FROM DAD")
                        .font(.system(size: 8, weight: .bold)).foregroundColor(.white.opacity(0.35)).kerning(1)
                    Text("💌")
                        .font(.system(size: 26))
                        .overlay(
                            Text("💛").font(.system(size: 12))
                                .offset(x: 13, y: -13)
                                .scaleEffect(heartPop ? 1.5 : 0)
                                .opacity(heartPop ? 0 : 1)
                                .animation(.spring(response: 0.35, dampingFraction: 0.5), value: heartPop)
                        )
                    Text(messages.isEmpty ? "No messages yet" : messages[safe: msgIdx] ?? messages[0])
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center).foregroundColor(.white)
                        .scaleEffect(scale).padding(.horizontal, 4)
                    Text("tap for next")
                        .font(.system(size: 8)).foregroundColor(.white.opacity(0.25))
                }
                .onTapGesture { nextMsg() }
                .onLongPressGesture(minimumDuration: 2.0) { HapticEngine.play(.success); isEditing = true }
            }
        }
        .onAppear { loadMessages() }
    }

    private func nextMsg() {
        guard !messages.isEmpty else { return }
        HapticEngine.play(.notification)
        heartPop = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { heartPop = false }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { scale = 1.1 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.15)) { scale = 1.0 }
        msgIdx = (msgIdx + 1) % messages.count
    }

    private func loadMessages() {
        if let loaded = try? JSONDecoder().decode([String].self, from: messagesData), !loaded.isEmpty {
            messages = loaded
        } else {
            messages = defaultDadMessages
        }
    }
}

struct DadEditView: View {
    @Binding var messages: [String]
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 5) {
                Text("Dad's Messages").font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.6))
                ForEach(messages.indices, id: \.self) { i in
                    Text(messages[i]).font(.system(size: 10)).foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(4).background(Color.white.opacity(0.07)).cornerRadius(5)
                }
                Button("Done ✓") { onDone() }
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(.green)
            }
            .padding(5)
        }
    }
}

// MARK: - My Superpowers (affirmations)

struct SuperpowersPage: View {
    // Parker's own list — seeded from heroAffirmations, grows as he adds his own
    @State private var myPowers: [String] = StorageKit.load([String].self, key: "heart.superpowers", default: heroAffirmations)
    @State private var crownVal: Double = 0
    @State private var currentIdx: Int = 0
    @State private var lastIdx: Int = 0
    @State private var glowScale: CGFloat = 1.0
    @State private var isAdding = false

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.05, blue: 0.02).ignoresSafeArea()
            VStack(spacing: 4) {
                Text("MY SUPERPOWERS")
                    .font(.system(size: 8, weight: .bold)).foregroundColor(Color(red:1,green:0.85,blue:0.2).opacity(0.6)).kerning(1)
                Text("💛")
                    .font(.system(size: 22)).scaleEffect(glowScale)
                Text(myPowers.isEmpty ? "Add a superpower!" : myPowers[currentIdx])
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center).foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentIdx)
                Text("say it out loud ✨")
                    .font(.system(size: 8)).foregroundColor(.white.opacity(0.3))
                Text("▲▼ Crown to scroll")
                    .font(.system(size: 7)).foregroundColor(.white.opacity(0.2))
            }
        }
        .focusable(true)
        .digitalCrownRotation($crownVal, from: 0, through: Double(max(myPowers.count - 1, 0)),
                               by: 1, sensitivity: .medium, isContinuous: true, isHapticFeedbackEnabled: true)
        .onChange(of: crownVal) { val in
            guard !myPowers.isEmpty else { return }
            let idx = ((Int(val.rounded()) % myPowers.count) + myPowers.count) % myPowers.count
            guard idx != lastIdx else { return }
            lastIdx = idx
            currentIdx = idx
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
