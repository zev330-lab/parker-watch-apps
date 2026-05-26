// BattleResultView.swift
// Dramatic battle result reveal — flash, winner, score, next round

import SwiftUI
import WatchKit

struct BattleResultView: View {

    let room:         BattleRoom
    let onNextRound:  () -> Void
    let onEndBattle:  () -> Void

    @State private var flashOpacity: Double  = 1.0
    @State private var showContent:  Bool    = false
    @State private var showButtons:  Bool    = false

    // MARK: - Computed

    private var result: BattleResult {
        guard let p = room.parker, let h = room.havi else { return .tie }
        return BattleService.shared.computeResult(parker: p, havi: h)
    }

    private var parkerEmoji: String {
        Alien.all.first { $0.name == room.parker }?.emoji ?? "❓"
    }

    private static let elementEmojis: [String: String] = [
        "Lightning":"⚡","Ocean":"🌊","Fire":"🔥","Wind":"🌪️",
        "Earth":"🌿","Sun":"☀️","Ice":"❄️","Bloom":"🌸",
        "Moon":"🌙","Volcano":"🌋"
    ]

    private var haviEmoji: String {
        Self.elementEmojis[room.havi ?? ""] ?? "❓"
    }

    private var winnerColor: Color {
        switch result {
        case .parkerWins: return .omnitrixGreen
        case .haviWins:   return .red
        case .tie:        return .yellow
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Flash overlay
            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if showContent {
                VStack(spacing: 3) {

                    // Winner banner
                    Text(result.label)
                        .font(.system(.caption2, design: .monospaced, weight: .black))
                        .foregroundColor(winnerColor)
                        .shadow(color: winnerColor.opacity(0.9), radius: 8)
                        .tracking(0.5)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    // Picks side-by-side
                    HStack(spacing: 10) {
                        VStack(spacing: 1) {
                            Text(parkerEmoji).font(.system(size: 26))
                            Text("PARKER")
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundColor(.metalGrey)
                        }
                        Text("VS")
                            .font(.system(.caption2, design: .monospaced, weight: .bold))
                            .foregroundColor(.gray)
                        VStack(spacing: 1) {
                            Text(haviEmoji).font(.system(size: 26))
                            Text("HAVI")
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundColor(.metalGrey)
                        }
                    }

                    // Score
                    Text("\(room.parker_score) — \(room.havi_score)")
                        .font(.system(.headline, design: .monospaced, weight: .black))
                        .foregroundColor(.white)

                    Text("RND \(room.round)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.gray)

                    // Buttons
                    if showButtons {
                        HStack(spacing: 5) {
                            Button(action: onNextRound) {
                                Text("NEXT")
                                    .font(.system(.caption2, design: .monospaced, weight: .black))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 6)
                                    .background(winnerColor)
                                    .cornerRadius(7)
                            }
                            .buttonStyle(.plain)

                            Button(action: onEndBattle) {
                                Text("END")
                                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 6)
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(7)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .onAppear {
            fireHaptic()
            runFlash()
        }
    }

    // MARK: - Animation

    private func runFlash() {
        let on: Double  = 1.0
        let off: Double = 0.0
        let q = DispatchQueue.main

        withAnimation(.linear(duration: 0.07)) { flashOpacity = off }
        q.asyncAfter(deadline: .now() + 0.10) { withAnimation(.linear(duration: 0.07)) { flashOpacity = on } }
        q.asyncAfter(deadline: .now() + 0.20) { withAnimation(.linear(duration: 0.07)) { flashOpacity = off } }
        q.asyncAfter(deadline: .now() + 0.30) { withAnimation(.linear(duration: 0.07)) { flashOpacity = on } }
        q.asyncAfter(deadline: .now() + 0.42) { withAnimation(.linear(duration: 0.12)) { flashOpacity = off } }
        q.asyncAfter(deadline: .now() + 0.60) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.68)) { showContent = true }
        }
        q.asyncAfter(deadline: .now() + 1.3) { withAnimation { showButtons = true } }
    }

    private func fireHaptic() {
        switch result {
        case .parkerWins: WKInterfaceDevice.current().play(.success)
        case .haviWins:   WKInterfaceDevice.current().play(.failure)
        case .tie:        WKInterfaceDevice.current().play(.notification)
        }
    }
}
