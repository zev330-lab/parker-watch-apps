// BattleView.swift
// Battle mode container — picking → waiting → result → next round

import SwiftUI
import WatchKit

// MARK: - Phase

private enum BattlePhase: Equatable {
    case picking, waiting, result
}

// MARK: - BattleView

struct BattleView: View {

    let onDismiss: () -> Void

    @State private var phase:       BattlePhase = .picking
    @State private var room:        BattleRoom  = BattleRoom(parker: nil, havi: nil, round: 1, parker_score: 0, havi_score: 0)
    @State private var pollTimer:   Timer?      = nil
    @State private var pulseScale:  CGFloat     = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                switch phase {

                case .picking:
                    BattlePickView(onPick: submitPick, onCancel: { endBattle() })
                        .transition(.asymmetric(
                            insertion:  .scale(scale: 0.9).combined(with: .opacity),
                            removal:    .opacity
                        ))

                case .waiting:
                    waitingView
                        .transition(.opacity)

                case .result:
                    BattleResultView(
                        room: room,
                        onNextRound: nextRound,
                        onEndBattle: { endBattle() }
                    )
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: phase)
        .onAppear(perform: resetAndStart)
        .onDisappear { stopPolling() }
    }

    // MARK: - Waiting Screen

    private var waitingView: some View {
        VStack(spacing: 8) {
            if let name = room.parker,
               let alien = Alien.all.first(where: { $0.name == name }) {
                Text(alien.emoji)
                    .font(.system(size: 34))
                Text(name.uppercased())
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundColor(.red)
            }

            VStack(spacing: 2) {
                Text("WAITING FOR")
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundColor(.gray)
                Text("HAVI...")
                    .font(.system(.caption, design: .monospaced, weight: .black))
                    .foregroundColor(.red)
            }
            .scaleEffect(pulseScale)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulseScale = 1.12
                }
            }
            .onDisappear { pulseScale = 1.0 }

            Button(action: { endBattle() }) {
                Text("CANCEL")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .onAppear(perform: startPolling)
        .onDisappear(perform: stopPolling)
    }

    // MARK: - Lifecycle

    private func resetAndStart() {
        let fresh = BattleRoom(parker: nil, havi: nil, round: 1, parker_score: 0, havi_score: 0)
        room = fresh
        Task {
            try? await BattleService.shared.writeRoom(fresh)
        }
    }

    // MARK: - Submit Pick (read-modify-write, only sets parker field)

    private func submitPick(_ alienName: String) {
        Task {
            do {
                let updated = try await BattleService.shared.updateRoom { room in
                    room.parker = alienName
                    // Do NOT touch room.havi — Havi may have already locked in
                }
                await MainActor.run {
                    room = updated
                    withAnimation { phase = .waiting }
                }
            } catch {
                // silently retry next time
            }
        }
    }

    // MARK: - Polling

    private func startPolling() {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                guard let fetched = try? await BattleService.shared.fetchRoom() else { return }
                await MainActor.run {
                    guard fetched.havi != nil, fetched.parker != nil else { return }
                    stopPolling()
                    // Tally the score for this round
                    var scored = fetched
                    let r = BattleService.shared.computeResult(parker: fetched.parker!, havi: fetched.havi!)
                    switch r {
                    case .parkerWins: scored.parker_score += 1
                    case .haviWins:   scored.havi_score   += 1
                    case .tie:        break
                    }
                    room = scored
                    // Write the scored state so both sides see the same scores
                    Task { try? await BattleService.shared.writeRoom(scored) }
                    withAnimation { phase = .result }
                }
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - Round Actions

    private func nextRound() {
        stopPolling()
        var next = room
        next.parker = nil
        next.havi   = nil
        next.round  += 1
        room = next
        // Parker owns round resets — write the clean slate
        Task {
            try? await BattleService.shared.writeRoom(next)
        }
        withAnimation {
            phase = .picking
        }
    }

    private func endBattle() {
        stopPolling()
        Task {
            let fresh = BattleRoom(parker: nil, havi: nil, round: 1, parker_score: 0, havi_score: 0)
            try? await BattleService.shared.writeRoom(fresh)
        }
        onDismiss()
    }
}
