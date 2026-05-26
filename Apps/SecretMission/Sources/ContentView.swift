import SwiftUI
import HeroKit

private enum MissionState { case pick, running, complete }

private let missionNames: [String] = [
    "Get dressed 🕵️",
    "Brush teeth 🦷",
    "Put on shoes 👟",
    "Clean up toys 🧸",
    "Eat breakfast 🥣",
    "Pack your bag 🎒",
    "Super mission ⚡",
]

struct ContentView: View {
    @State private var state: MissionState = .pick
    @State private var missionIdx: Int = 0
    @State private var crownValue: Double = 0
    @State private var secondsLeft: Int = 0
    @State private var timer: Timer? = nil
    @State private var ringProgress: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    // Mission durations (minutes): 1, 2, 3, 5
    private let durations = [60, 120, 180, 300]
    @State private var durationIdx: Int = 1  // default 2 min

    private var totalSeconds: Int { durations[durationIdx] }
    private var progress: Double { Double(totalSeconds - secondsLeft) / Double(totalSeconds) }
    private var minutesLeft: Int { secondsLeft / 60 }
    private var secsDisplay: Int { secondsLeft % 60 }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch state {
            case .pick:   pickView
            case .running: runningView
            case .complete: completeView
            }
        }
        .focusable(state == .pick)
        .digitalCrownRotation(
            $crownValue,
            from: 0, through: Double(missionNames.count - 1), by: 1,
            sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true
        )
        .onChange(of: crownValue) { newVal in
            guard state == .pick else { return }
            missionIdx = Int(newVal.rounded())
            HapticEngine.play(.click)
        }
        .onDisappear { timer?.invalidate() }
    }

    private var pickView: some View {
        VStack(spacing: 6) {
            Text("🕵️ MISSION")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.green.opacity(0.7))
                .kerning(2)

            Text(missionNames[missionIdx])
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Duration picker
            HStack(spacing: 8) {
                ForEach(0..<durations.count, id: \.self) { i in
                    Text("\(durations[i]/60)m")
                        .font(.system(size: 10, weight: durationIdx == i ? .black : .light))
                        .foregroundColor(durationIdx == i ? .green : .white.opacity(0.3))
                        .onTapGesture {
                            durationIdx = i
                            HapticEngine.play(.tap)
                        }
                }
            }

            Button(action: startMission) {
                Text("START MISSION")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
    }

    private var runningView: some View {
        ZStack {
            // Progress ring
            Circle()
                .stroke(Color.green.opacity(0.15), lineWidth: 6)
                .frame(width: 100, height: 100)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: ringProgress)

            // Countdown
            VStack(spacing: 2) {
                Text(String(format: "%d:%02d", minutesLeft, secsDisplay))
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .scaleEffect(pulseScale)

                Text(missionNames[missionIdx])
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.green.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: 80)

                Button("ABORT") {
                    cancelMission()
                }
                .font(.system(size: 8))
                .foregroundColor(.red.opacity(0.6))
                .buttonStyle(.plain)
            }
        }
    }

    private var completeView: some View {
        VStack(spacing: 6) {
            Text("✅")
                .font(.system(size: 36))
                .scaleEffect(pulseScale)

            Text("MISSION\nCOMPLETE!")
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundColor(.green)
                .multilineTextAlignment(.center)

            Button("NEW MISSION") {
                state = .pick
                HapticEngine.play(.tap)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.black)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.green)
            .cornerRadius(6)
            .buttonStyle(.plain)
        }
    }

    private func startMission() {
        secondsLeft = totalSeconds
        ringProgress = 0
        state = .running
        HapticEngine.play(.surge)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            secondsLeft -= 1
            ringProgress = progress

            // Pulse on each 15-second mark
            if secondsLeft % 15 == 0 && secondsLeft > 0 {
                HapticEngine.play(.heartbeat)
                withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { pulseScale = 1.15 }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1)) { pulseScale = 1.0 }
            }

            if secondsLeft <= 0 {
                missionComplete()
            }
        }
    }

    private func missionComplete() {
        timer?.invalidate()
        timer = nil
        state = .complete
        HapticEngine.play(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { HapticEngine.play(.success) }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) { pulseScale = 1.5 }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2)) { pulseScale = 1.0 }
    }

    private func cancelMission() {
        timer?.invalidate()
        timer = nil
        state = .pick
        HapticEngine.play(.retry)
    }
}
