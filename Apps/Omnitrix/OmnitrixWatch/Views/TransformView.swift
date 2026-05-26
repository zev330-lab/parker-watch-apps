// TransformView.swift
// Transformation animation sequence + 10-second countdown + timeout

import SwiftUI
import WatchKit

// MARK: - Phase Enum

private enum TransformPhase: Equatable {
    case flashing       // rapid white/green flashes
    case vortex         // angular gradient spinning
    case heroTime       // "IT'S HERO TIME!" slam
    case alienReveal    // alien emoji + name bounce in
    case countdown      // 10-second ring countdown
    case timeout        // timeout flash + red shake
    case recharging     // pulsing "RECHARGING..." text
}

// MARK: - Transform View

struct TransformView: View {

    let alien: Alien
    let onComplete: () -> Void

    // Phase control
    @State private var phase: TransformPhase = .flashing

    // Flash overlay
    @State private var flashColor: Color   = .white
    @State private var flashOpacity: Double = 0

    // Vortex
    @State private var spiralRotation: Double = 0

    // Hero time text
    @State private var heroScale: CGFloat      = 0
    @State private var heroGlowRadius: CGFloat = 0

    // Alien reveal
    @State private var emojiScale: CGFloat     = 0
    @State private var nameOffset: CGFloat     = 60

    // Countdown ring
    @State private var ringProgress: Double    = 1.0
    @State private var countdownSeconds: Int   = 10

    // Timeout
    @State private var shakeOffset: CGFloat    = 0
    @State private var hourglassColor: Color   = .omnitrixGreen

    // Recharging
    @State private var rechargeOpacity: Double = 0

    private let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.deepBlack.ignoresSafeArea()

                // Flash overlay (used in flash + timeout phases)
                flashColor
                    .opacity(flashOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // Phase-specific content
                phaseContent(geo: geo)
            }
        }
        .onAppear { beginSequence() }
        .onReceive(countdownTimer) { _ in
            guard phase == .countdown else { return }
            if countdownSeconds > 1 {
                countdownSeconds -= 1
            } else if countdownSeconds == 1 {
                countdownSeconds = 0
                triggerTimeout()
            }
        }
    }

    // MARK: - Phase Content

    @ViewBuilder
    private func phaseContent(geo: GeometryProxy) -> some View {
        switch phase {

        // ── Nothing yet during pure flash ───────────────────────────────────
        case .flashing:
            EmptyView()

        // ── Spinning angular vortex ──────────────────────────────────────────
        case .vortex:
            vortexView
                .transition(.opacity)

        // ── "IT'S HERO TIME!" over the vortex ───────────────────────────────
        case .heroTime:
            ZStack {
                vortexView
                heroTimeText
                    .scaleEffect(heroScale)
            }
            .transition(.opacity)

        // ── Large emoji + name bounce in ─────────────────────────────────────
        case .alienReveal:
            VStack(spacing: 8) {
                Text(alien.emoji)
                    .font(.system(size: 56))
                    .scaleEffect(emojiScale)
                    .shadow(color: Color.omnitrixGreen.opacity(0.65), radius: 12)

                Text(alien.name.uppercased())
                    .font(.system(.headline, design: .rounded, weight: .black))
                    .foregroundColor(.omnitrixGreen)
                    .offset(y: nameOffset)
                    .opacity(nameOffset < 20 ? 1 : 0)
            }
            .transition(.opacity)

        // ── Circular countdown ring ──────────────────────────────────────────
        case .countdown:
            ZStack {
                // Countdown ring around screen edge
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        Color.omnitrixGreen,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(2)

                // Alien + name + timer number
                VStack(spacing: 4) {
                    Text(alien.emoji)
                        .font(.system(size: 36))

                    Text(alien.name.uppercased())
                        .font(.system(.caption2, design: .rounded, weight: .black))
                        .foregroundColor(.omnitrixGreen)

                    Text("\(countdownSeconds)")
                        .font(.system(.title2, design: .monospaced, weight: .bold))
                        .foregroundColor(.omnitrixGreen)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            .transition(.opacity)

        // ── Timeout ──────────────────────────────────────────────────────────
        case .timeout:
            VStack(spacing: 10) {
                OmnitrixHourglass()
                    .fill(hourglassColor)
                    .frame(width: 44, height: 44)
                    .shadow(color: .red.opacity(0.9), radius: 8)

                Text("TIME OUT!")
                    .font(.system(.headline, design: .monospaced, weight: .black))
                    .foregroundColor(.red)
                    .shadow(color: .red.opacity(0.8), radius: 10)
                    .offset(x: shakeOffset)
            }
            .transition(.opacity)

        // ── Recharging ────────────────────────────────────────────────────────
        case .recharging:
            VStack(spacing: 10) {
                OmnitrixHourglass()
                    .fill(hourglassColor)
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.omnitrixGreen.opacity(0.6), radius: 8)

                Text("RECHARGING...")
                    .font(.system(.caption, design: .monospaced, weight: .semibold))
                    .foregroundColor(.omnitrixGreen)
                    .opacity(rechargeOpacity)
            }
            .transition(.opacity)
        }
    }

    // MARK: - Vortex view

    private var vortexView: some View {
        AngularGradient(
            colors: [
                .clear,
                Color.omnitrixGreen.opacity(0.65),
                .clear,
                Color.omnitrixGreen.opacity(0.30),
                .clear,
            ],
            center: .center
        )
        .rotationEffect(.degrees(spiralRotation))
        .ignoresSafeArea()
    }

    // MARK: - Hero time text

    private var heroTimeText: some View {
        VStack(spacing: 4) {
            Text("IT'S")
                .font(.system(.headline, design: .monospaced, weight: .black))
                .foregroundColor(.white)

            Text("HERO TIME!")
                .font(.system(.title3, design: .monospaced, weight: .black))
                .foregroundColor(.omnitrixGreen)
                .shadow(color: Color.omnitrixGreen.opacity(0.9), radius: heroGlowRadius)
        }
    }

    // MARK: - Animation Sequence

    private func beginSequence() {

        // ── Phase 1: Flash — white/green × 3 ─────────────────────────────────
        let flashStep = 0.10
        var t = 0.0

        for _ in 0..<3 {
            // White
            DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                withAnimation(.linear(duration: flashStep)) {
                    flashColor   = .white
                    flashOpacity = 0.88
                }
            }
            t += flashStep

            // Green
            DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                withAnimation(.linear(duration: flashStep)) {
                    flashColor   = .omnitrixGreen
                    flashOpacity = 0.65
                }
            }
            t += flashStep

            // Fade
            DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                withAnimation(.linear(duration: flashStep)) {
                    flashOpacity = 0
                }
            }
            t += flashStep
        }

        // ── Phase 2: Vortex ───────────────────────────────────────────────────
        t += 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + t) {
            withAnimation(.easeIn(duration: 0.2)) { phase = .vortex }
            withAnimation(
                .linear(duration: 1.4)
                .repeatForever(autoreverses: false)
            ) {
                spiralRotation = 360
            }
        }

        // ── Phase 3: "IT'S HERO TIME!" ────────────────────────────────────────
        t += 0.45
        DispatchQueue.main.asyncAfter(deadline: .now() + t) {
            withAnimation(.easeIn(duration: 0.1)) { phase = .heroTime }

            // Spring slam in
            withAnimation(.spring(response: 0.38, dampingFraction: 0.45)) {
                heroScale      = 1.3
                heroGlowRadius = 14
            }
            // Settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    heroScale = 1.0
                }
            }
        }

        // ── Phase 4: Alien reveal ─────────────────────────────────────────────
        t += 0.85
        DispatchQueue.main.asyncAfter(deadline: .now() + t) {
            withAnimation(.easeOut(duration: 0.15)) { phase = .alienReveal }

            // Emoji bounce
            withAnimation(.spring(response: 0.35, dampingFraction: 0.42)) {
                emojiScale = 1.0
            }
            // Name slide up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                    nameOffset = 0
                }
            }
        }

        // ── Phase 5: Countdown ────────────────────────────────────────────────
        t += 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + t) {
            WKInterfaceDevice.current().play(.success)
            withAnimation(.easeInOut(duration: 0.3)) { phase = .countdown }

            // Animate ring 1.0 → 0.0 over exactly 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.linear(duration: 10)) {
                    ringProgress = 0
                }
            }
        }
    }

    // MARK: - Timeout Sequence

    private func triggerTimeout() {
        WKInterfaceDevice.current().play(.failure)

        // Red flashes × 3
        let step = 0.15
        var t = 0.0
        for _ in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                withAnimation(.linear(duration: 0.10)) {
                    flashColor   = .red
                    flashOpacity = 0.72
                }
            }
            t += 0.10
            DispatchQueue.main.asyncAfter(deadline: .now() + t) {
                withAnimation(.linear(duration: 0.10)) { flashOpacity = 0 }
            }
            t += step
        }

        // Show timeout screen
        DispatchQueue.main.asyncAfter(deadline: .now() + t + 0.05) {
            withAnimation(.easeInOut(duration: 0.2)) {
                phase         = .timeout
                hourglassColor = .red
            }
            shakeText()
        }

        // Transition to recharging
        DispatchQueue.main.asyncAfter(deadline: .now() + t + 1.6) {
            withAnimation(.easeInOut(duration: 0.3)) { phase = .recharging }

            // Pulse hourglass back to green over 1.5s
            withAnimation(.easeInOut(duration: 1.5)) {
                hourglassColor = .omnitrixGreen
            }
            // Pulsing "RECHARGING..." text
            withAnimation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
            ) {
                rechargeOpacity = 1.0
            }
        }

        // Return to watch face
        DispatchQueue.main.asyncAfter(deadline: .now() + t + 4.8) {
            WKInterfaceDevice.current().play(.notification)
            onComplete()
        }
    }

    // MARK: - Shake Text

    private func shakeText() {
        let keyframes: [CGFloat] = [10, -10, 8, -8, 5, -5, 3, -3, 0]
        for (i, offset) in keyframes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                withAnimation(.linear(duration: 0.06)) {
                    shakeOffset = offset
                }
            }
        }
    }
}
