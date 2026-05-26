// WatchFaceView.swift
// Idle home screen — hourglass, glow, scanlines, stars, breathing, clock, battle button

import SwiftUI
import WatchKit

// MARK: - Omnitrix Hourglass Shape

struct OmnitrixHourglass: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx       = rect.midX
        let cy       = rect.midY
        let halfW    = rect.width  * 0.44
        let halfH    = rect.height * 0.44
        let neckHalf = rect.width  * 0.07

        path.move(to: CGPoint(x: cx - halfW,    y: cy - halfH))
        path.addLine(to: CGPoint(x: cx + halfW,    y: cy - halfH))
        path.addLine(to: CGPoint(x: cx + neckHalf, y: cy))
        path.addLine(to: CGPoint(x: cx - neckHalf, y: cy))
        path.closeSubpath()

        path.move(to: CGPoint(x: cx - neckHalf, y: cy))
        path.addLine(to: CGPoint(x: cx + neckHalf, y: cy))
        path.addLine(to: CGPoint(x: cx + halfW,    y: cy + halfH))
        path.addLine(to: CGPoint(x: cx - halfW,    y: cy + halfH))
        path.closeSubpath()

        return path
    }
}

// MARK: - Scanline Overlay

struct ScanlineOverlay: View {
    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let lineCount = Int(size.height / 3)
                for i in 0..<lineCount {
                    let y = CGFloat(i) * 3
                    context.fill(
                        Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                        with: .color(.black.opacity(0.08))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Star Data

private struct StarData {
    let xFrac: CGFloat
    let yFrac: CGFloat
    let baseOpacity: Double
    let duration: Double
}

private let starField: [StarData] = [
    StarData(xFrac: 0.12, yFrac: 0.08, baseOpacity: 0.30, duration: 2.1),
    StarData(xFrac: 0.88, yFrac: 0.15, baseOpacity: 0.20, duration: 1.8),
    StarData(xFrac: 0.25, yFrac: 0.22, baseOpacity: 0.40, duration: 2.5),
    StarData(xFrac: 0.75, yFrac: 0.28, baseOpacity: 0.25, duration: 1.6),
    StarData(xFrac: 0.05, yFrac: 0.42, baseOpacity: 0.35, duration: 2.3),
    StarData(xFrac: 0.95, yFrac: 0.38, baseOpacity: 0.20, duration: 1.9),
    StarData(xFrac: 0.15, yFrac: 0.55, baseOpacity: 0.30, duration: 2.7),
    StarData(xFrac: 0.85, yFrac: 0.62, baseOpacity: 0.40, duration: 2.0),
    StarData(xFrac: 0.30, yFrac: 0.78, baseOpacity: 0.25, duration: 1.7),
    StarData(xFrac: 0.70, yFrac: 0.72, baseOpacity: 0.35, duration: 2.4),
    StarData(xFrac: 0.50, yFrac: 0.12, baseOpacity: 0.30, duration: 1.5),
    StarData(xFrac: 0.45, yFrac: 0.88, baseOpacity: 0.20, duration: 2.6),
    StarData(xFrac: 0.60, yFrac: 0.35, baseOpacity: 0.40, duration: 2.2),
    StarData(xFrac: 0.20, yFrac: 0.65, baseOpacity: 0.30, duration: 1.8),
    StarData(xFrac: 0.80, yFrac: 0.85, baseOpacity: 0.25, duration: 2.0),
]

// MARK: - Twinkling Star

private struct TwinklingStar: View {
    let data: StarData
    @State private var opacity: Double

    init(data: StarData) {
        self.data = data
        _opacity = State(initialValue: data.baseOpacity)
    }

    var body: some View {
        GeometryReader { geo in
            Circle()
                .fill(Color.white)
                .frame(width: 2, height: 2)
                .opacity(opacity)
                .position(
                    x: geo.size.width  * data.xFrac,
                    y: geo.size.height * data.yFrac
                )
        }
        .allowsHitTesting(false)
        .onAppear {
            let target: Double = data.baseOpacity < 0.3 ? 0.85 : 0.10
            withAnimation(
                .easeInOut(duration: data.duration)
                .repeatForever(autoreverses: true)
            ) { opacity = target }
        }
    }
}

// MARK: - Watch Face View

struct WatchFaceView: View {

    let onActivate: () -> Void
    let onBattle:   () -> Void

    @State private var glowRadius:   CGFloat = 4
    @State private var breathScale:  CGFloat = 1.0
    @State private var currentTime:  String  = WatchFaceView.formattedTime()

    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.deepBlack

                ForEach(starField.indices, id: \.self) { i in
                    TwinklingStar(data: starField[i])
                }

                ScanlineOverlay()

                RadialGradient(
                    colors: [Color.omnitrixGreen.opacity(0.22), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: geo.size.width * 0.5
                )
                .scaleEffect(breathScale)

                VStack(spacing: 0) {
                    // Header
                    Text("BEN 10")
                        .font(.system(.caption2, design: .monospaced, weight: .semibold))
                        .tracking(4)
                        .foregroundColor(.metalGrey)
                        .padding(.top, 6)

                    Spacer()

                    // Hourglass
                    ZStack {
                        Circle()
                            .stroke(Color.omnitrixGreen.opacity(0.35), lineWidth: 2)
                            .frame(width: geo.size.width * 0.52, height: geo.size.width * 0.52)

                        OmnitrixHourglass()
                            .fill(Color.omnitrixGreen.opacity(0.35))
                            .frame(width: geo.size.width * 0.36, height: geo.size.width * 0.36)
                            .blur(radius: glowRadius)

                        OmnitrixHourglass()
                            .fill(Color.omnitrixGreen)
                            .frame(width: geo.size.width * 0.36, height: geo.size.width * 0.36)
                    }
                    .shadow(color: Color.omnitrixGreen.opacity(0.8), radius: glowRadius)

                    Spacer()

                    // Clock — long-press to enter battle mode
                    Text(currentTime)
                        .font(.system(.callout, design: .monospaced, weight: .bold))
                        .foregroundColor(.omnitrixGreen)
                        .monospacedDigit()
                        .padding(.bottom, 10)
                        .onLongPressGesture(minimumDuration: 0.6) {
                            onBattle()
                        }
                }
                .scaleEffect(breathScale)
            }
            .ignoresSafeArea()
        }
        .contentShape(Rectangle())
        .onTapGesture { onActivate() }
        .onAppear { startAnimations() }
        .onReceive(clockTimer) { _ in
            currentTime = WatchFaceView.formattedTime()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowRadius = 16
        }
        withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
            breathScale = 1.03
        }
    }

    private static func formattedTime() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: Date())
    }
}
