import SwiftUI
import HeroKit

// PowerUp — three pages: Center · Superpower · Mission
// Swipe between pages. Crown used within each page.

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

// MARK: - Center (Karate breathing)

private enum BreathPhase { case idle, inhale, hold, exhale, done }

struct CenterPage: View {
    @State private var phase: BreathPhase = .idle
    @State private var breathCount = 0
    @State private var sessions: Int = StorageKit.load(Int.self, key: "powerup.sessions", default: 0)
    @State private var coreScale: CGFloat = 0.58
    @State private var coreOpacity: Double = 0.65
    @State private var glowR: CGFloat = 0

    private let beltColors: [Color] = [.white, .yellow, .orange, .green, .blue, .purple, .brown, Color(red:0.1,green:0.1,blue:0.1)]
    private var beltColor: Color { beltColors[min(sessions / 25, beltColors.count - 1)] }
    private var beltName: String { ["White","Yellow","Orange","Green","Blue","Purple","Brown","Black"][min(sessions/25, 7)] }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Circle().fill(beltColor.opacity(0.12)).frame(width: 110, height: 110).blur(radius: glowR)
            Circle()
                .fill(RadialGradient(colors:[beltColor.opacity(0.9),beltColor.opacity(0.25)], center:.center, startRadius:4, endRadius:40))
                .frame(width:78,height:78).scaleEffect(coreScale).opacity(coreOpacity)
            VStack {
                HStack { Spacer()
                    Text(beltName).font(.system(size:8,weight:.bold)).padding(3)
                        .background(beltColor.opacity(0.25)).cornerRadius(4).padding(4)
                }
                Spacer()
                phaseLabel.padding(.bottom, 8)
            }
        }
        .onTapGesture { handleTap() }
    }

    @ViewBuilder private var phaseLabel: some View {
        switch phase {
        case .idle:
            VStack(spacing:1) {
                Text("CENTER").font(.system(size:10,weight:.bold)).foregroundColor(.white.opacity(0.7)).kerning(1.5)
                Text("Tap to start").font(.system(size:9)).foregroundColor(.white.opacity(0.35))
            }
        case .inhale: Text("Breathe in…").font(.system(size:11,weight:.semibold,design:.rounded)).foregroundColor(beltColor)
        case .hold:   Text("Hold…").font(.system(size:11,weight:.semibold,design:.rounded)).foregroundColor(.white.opacity(0.5))
        case .exhale: Text("Breathe out…").font(.system(size:11,weight:.semibold,design:.rounded)).foregroundColor(beltColor.opacity(0.7))
        case .done:
            VStack(spacing:1) {
                Text("Centered 💪").font(.system(size:11,weight:.bold,design:.rounded)).foregroundColor(.white)
                Text("Tap to finish").font(.system(size:9)).foregroundColor(.white.opacity(0.35))
            }
        }
    }

    private func handleTap() {
        switch phase {
        case .idle: startBreathing()
        case .done: finishSession()
        default: break
        }
    }

    private func startBreathing() {
        breathCount = 0; phase = .inhale
        HapticEngine.play(.heartbeat)
        withAnimation(.easeInOut(duration:3.5)) { coreScale=1.0; coreOpacity=1.0; glowR=20 }
        DispatchQueue.main.asyncAfter(deadline:.now()+3.5) {
            phase = .hold; HapticEngine.play(.click)
            DispatchQueue.main.asyncAfter(deadline:.now()+1.5) {
                phase = .exhale; HapticEngine.play(.heartbeat)
                withAnimation(.easeInOut(duration:4.0)) { coreScale=0.58; coreOpacity=0.65; glowR=0 }
                DispatchQueue.main.asyncAfter(deadline:.now()+4.0) {
                    breathCount += 1
                    if breathCount >= 5 { phase = .done; HapticEngine.play(.success) }
                    else { phase = .inhale; startBreathing() }
                }
            }
        }
    }

    private func finishSession() {
        sessions += 1; StorageKit.save(sessions, key:"powerup.sessions")
        withAnimation(.spring(response:0.4,dampingFraction:0.5)) { coreScale=0.58; glowR=0 }
        phase = .idle
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
            VStack(spacing: 5) {
                Text(activated ? "⚡ ACTIVATED ⚡" : "Spin the Crown")
                    .font(.system(size:9,weight:.bold)).foregroundColor(.white.opacity(0.45)).kerning(0.8)
                Text(superpowers[currentIdx])
                    .font(.system(size:12,weight:.black,design:.rounded))
                    .multilineTextAlignment(.center).foregroundColor(.white)
                    .scaleEffect(activScale).padding(.horizontal,4).minimumScaleFactor(0.6)
                if activated {
                    Text("tap again for another").font(.system(size:8)).foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .focusable(true)
        .digitalCrownRotation($crownVal, from:0, through:Double(superpowers.count-1), by:1,
                               sensitivity:.medium, isContinuous:true, isHapticFeedbackEnabled:true)
        .onChange(of: crownVal) { val in
            let idx = ((Int(val.rounded()) % superpowers.count) + superpowers.count) % superpowers.count
            guard idx != lastIdx else { return }
            lastIdx = idx; currentIdx = idx; activated = false
            HapticEngine.play(.click)
            withAnimation(.easeOut(duration:0.1)) { bgOpacity = 0.05 }
        }
        .onTapGesture {
            HapticEngine.play(.surge); activated = true
            withAnimation(.spring(response:0.2,dampingFraction:0.3)) { activScale=1.35; bgOpacity=0.28 }
            withAnimation(.spring(response:0.5,dampingFraction:0.6).delay(0.2)) { activScale=1.0 }
            withAnimation(.easeOut(duration:1.0).delay(0.5)) { bgOpacity=0.08 }
            DispatchQueue.main.asyncAfter(deadline:.now()+0.3) { HapticEngine.play(.success) }
        }
    }
}

// MARK: - Secret Mission Timer

private enum MissionState { case pick, running, complete }

private let missionNames: [String] = [
    "Get dressed 🕵️", "Brush teeth 🦷", "Put on shoes 👟",
    "Clean up toys 🧸", "Eat breakfast 🥣", "Pack your bag 🎒",
    "Super mission ⚡",
]

struct MissionPage: View {
    @State private var state: MissionState = .pick
    @State private var missionIdx = 0
    @State private var crownVal: Double = 0
    @State private var secondsLeft = 0
    @State private var ringProgress: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var timer: Timer? = nil
    @State private var durationIdx = 1

    private let durations = [60, 120, 180, 300]
    private var total: Int { durations[durationIdx] }
    private var progress: Double { Double(total - secondsLeft) / Double(total) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch state {
            case .pick:     pickView
            case .running:  runView
            case .complete: doneView
            }
        }
        .focusable(state == .pick)
        .digitalCrownRotation($crownVal, from:0, through:Double(missionNames.count-1),
                               by:1, sensitivity:.medium, isContinuous:false, isHapticFeedbackEnabled:true)
        .onChange(of: crownVal) { val in
            guard state == .pick else { return }
            missionIdx = Int(val.rounded())
            HapticEngine.play(.click)
        }
        .onDisappear { timer?.invalidate() }
    }

    private var pickView: some View {
        VStack(spacing: 5) {
            Text("🕵️ MISSION").font(.system(size:9,weight:.bold)).foregroundColor(.green.opacity(0.7)).kerning(2)
            Text(missionNames[missionIdx])
                .font(.system(size:12,weight:.black,design:.monospaced))
                .foregroundColor(.white).multilineTextAlignment(.center)
            HStack(spacing:6) {
                ForEach(0..<durations.count, id:\.self) { i in
                    Text("\(durations[i]/60)m")
                        .font(.system(size:10,weight:durationIdx==i ? .black:.light))
                        .foregroundColor(durationIdx==i ? .green:.white.opacity(0.3))
                        .onTapGesture { durationIdx=i; HapticEngine.play(.tap) }
                }
            }
            Button(action: startMission) {
                Text("GO").font(.system(size:11,weight:.bold)).foregroundColor(.black)
                    .padding(.horizontal,14).padding(.vertical,5)
                    .background(Color.green).cornerRadius(8)
            }.buttonStyle(.plain)
        }
    }

    private var runView: some View {
        ZStack {
            Circle().stroke(Color.green.opacity(0.15),lineWidth:6).frame(width:100,height:100)
            Circle().trim(from:0,to:ringProgress)
                .stroke(Color.green,style:StrokeStyle(lineWidth:6,lineCap:.round))
                .frame(width:100,height:100).rotationEffect(.degrees(-90))
                .animation(.linear(duration:1),value:ringProgress)
            VStack(spacing:2) {
                Text(String(format:"%d:%02d", secondsLeft/60, secondsLeft%60))
                    .font(.system(size:22,weight:.black,design:.monospaced)).foregroundColor(.white).scaleEffect(pulseScale)
                Text(missionNames[missionIdx])
                    .font(.system(size:8)).foregroundColor(.green.opacity(0.8))
                    .multilineTextAlignment(.center).lineLimit(2).frame(maxWidth:80)
                Button("ABORT") { cancel() }.font(.system(size:8)).foregroundColor(.red.opacity(0.55)).buttonStyle(.plain)
            }
        }
    }

    private var doneView: some View {
        VStack(spacing:5) {
            Text("✅").font(.system(size:34)).scaleEffect(pulseScale)
            Text("MISSION\nCOMPLETE!").font(.system(size:13,weight:.black,design:.monospaced)).foregroundColor(.green).multilineTextAlignment(.center)
            Button("NEW") { state = .pick; HapticEngine.play(.tap) }
                .font(.system(size:10,weight:.bold)).foregroundColor(.black)
                .padding(.horizontal,8).padding(.vertical,3)
                .background(Color.green).cornerRadius(6).buttonStyle(.plain)
        }
    }

    private func startMission() {
        secondsLeft = total; ringProgress = 0; state = .running; HapticEngine.play(.surge)
        timer = Timer.scheduledTimer(withTimeInterval:1, repeats:true) { _ in
            secondsLeft -= 1; ringProgress = progress
            if secondsLeft % 15 == 0 && secondsLeft > 0 {
                HapticEngine.play(.heartbeat)
                withAnimation(.spring(response:0.2,dampingFraction:0.4)) { pulseScale=1.15 }
                withAnimation(.spring(response:0.4,dampingFraction:0.6).delay(0.1)) { pulseScale=1.0 }
            }
            if secondsLeft <= 0 { missionDone() }
        }
    }

    private func missionDone() {
        timer?.invalidate(); timer=nil; state = .complete; HapticEngine.play(.success)
        DispatchQueue.main.asyncAfter(deadline:.now()+0.25) { HapticEngine.play(.success) }
        withAnimation(.spring(response:0.3,dampingFraction:0.3)) { pulseScale=1.5 }
        withAnimation(.spring(response:0.6,dampingFraction:0.5).delay(0.2)) { pulseScale=1.0 }
    }

    private func cancel() { timer?.invalidate(); timer=nil; state = .pick; HapticEngine.play(.retry) }
}
