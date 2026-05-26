// BattlePickView.swift
// Alien picker for battle mode — Digital Crown scroll, tap to lock in

import SwiftUI
import WatchKit

struct BattlePickView: View {

    let onPick:   (String) -> Void
    let onCancel: () -> Void

    @State private var crownValue:     Double = 0
    @State private var selectedIndex:  Int    = 0
    @State private var locked:         Bool   = false
    @State private var slideDir:       Int    = 1

    private let aliens = Alien.all

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Subtle red glow background
            RadialGradient(
                colors: [Color.red.opacity(0.18), .clear],
                center: .center, startRadius: 0, endRadius: 80
            )

            if locked {
                lockedView
            } else {
                pickingView
            }
        }
        // Digital Crown wiring (same pattern as AlienSelectorView)
        .focusable()
        .digitalCrownRotation(
            $crownValue,
            from: 0, through: Double(aliens.count - 1),
            by: 1, sensitivity: .medium,
            isContinuous: false, isHapticFeedbackEnabled: true
        )
        .onChange(of: crownValue) { newVal in
            let newIdx = min(max(Int(newVal.rounded()), 0), aliens.count - 1)
            guard newIdx != selectedIndex else { return }
            slideDir = newIdx > selectedIndex ? 1 : -1
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedIndex = newIdx
            }
            WKInterfaceDevice.current().play(.click)
        }
        // Swipe support
        .gesture(
            DragGesture(minimumDistance: 18)
                .onEnded { v in
                    if v.translation.width < -18 { advance(by: 1) }
                    else if v.translation.width > 18 { advance(by: -1) }
                }
        )
    }

    // MARK: - Picking

    private var pickingView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onCancel) {
                    Text("✕")
                        .font(.system(.caption2, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                Spacer()
                Text("BATTLE")
                    .font(.system(.caption2, design: .monospaced, weight: .black))
                    .foregroundColor(.red)
                    .tracking(2)
                Spacer()
                Color.clear.frame(width: 28, height: 28)
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)

            Spacer()

            // Alien card
            VStack(spacing: 3) {
                Text(aliens[selectedIndex].emoji)
                    .font(.system(size: 42))
                    .transition(
                        .asymmetric(
                            insertion:  .offset(x: CGFloat(slideDir) * 30).combined(with: .opacity),
                            removal:    .offset(x: CGFloat(slideDir) * -30).combined(with: .opacity)
                        )
                    )
                    .id(selectedIndex)
                    .animation(.spring(response: 0.25, dampingFraction: 0.75), value: selectedIndex)

                Text(aliens[selectedIndex].name.uppercased())
                    .font(.system(.caption2, design: .monospaced, weight: .black))
                    .foregroundColor(.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            // Dots
            HStack(spacing: 3) {
                ForEach(0..<aliens.count, id: \.self) { i in
                    Circle()
                        .fill(i == selectedIndex ? Color.red : Color.gray.opacity(0.35))
                        .frame(width: i == selectedIndex ? 5 : 3,
                               height: i == selectedIndex ? 5 : 3)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIndex)
                }
            }
            .padding(.vertical, 5)

            // Lock In button
            Button {
                WKInterfaceDevice.current().play(.success)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { locked = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onPick(aliens[selectedIndex].name)
                }
            } label: {
                Text("⚔️ LOCK IN")
                    .font(.system(.caption2, design: .monospaced, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.red)
                    .cornerRadius(8)
                    .shadow(color: .red.opacity(0.6), radius: 6)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 6)
        }
    }

    // MARK: - Locked

    private var lockedView: some View {
        VStack(spacing: 6) {
            Text("LOCKED IN")
                .font(.system(.caption2, design: .monospaced, weight: .black))
                .foregroundColor(.red)
                .tracking(2)
            Text(aliens[selectedIndex].emoji)
                .font(.system(size: 44))
            Text(aliens[selectedIndex].name.uppercased())
                .font(.system(.caption2, design: .monospaced, weight: .bold))
                .foregroundColor(.red)
        }
        .transition(.scale(scale: 1.1).combined(with: .opacity))
    }

    // MARK: - Helpers

    private func advance(by delta: Int) {
        let newIdx = min(max(selectedIndex + delta, 0), aliens.count - 1)
        guard newIdx != selectedIndex else { return }
        slideDir = delta > 0 ? 1 : -1
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selectedIndex = newIdx }
        crownValue = Double(newIdx)
        WKInterfaceDevice.current().play(.click)
    }
}
