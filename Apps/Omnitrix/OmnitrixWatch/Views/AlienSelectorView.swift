// AlienSelectorView.swift
// Alien dial — Digital Crown + swipe + tap-to-transform

import SwiftUI
import WatchKit

struct AlienSelectorView: View {

    @Binding var selectedIndex: Int
    let onTransform: () -> Void
    let onBack: () -> Void

    @State private var crownValue: Double = 0
    @State private var slideDirection: Int = 1   // +1 = forward, -1 = backward

    private let aliens = Alien.all

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {

                // ── Background ────────────────────────────────────────────────
                Color.deepBlack

                // ── Scanlines ─────────────────────────────────────────────────
                ScanlineOverlay()

                // ── Watermark hourglass ───────────────────────────────────────
                OmnitrixHourglass()
                    .fill(Color.omnitrixGreen.opacity(0.10))
                    .frame(
                        width:  geo.size.width * 0.65,
                        height: geo.size.width * 0.65
                    )

                // ── Main content stack ────────────────────────────────────────
                VStack(spacing: 0) {

                    // Indicator dots
                    indicatorDots
                        .padding(.top, 4)

                    Spacer()

                    // Alien card — keyed on index so transition fires on change
                    alienCard(alien: aliens[selectedIndex])
                        .id(selectedIndex)
                        .transition(slideTransition)

                    Spacer()

                    // Navigation row
                    navRow
                        .padding(.horizontal, 6)
                        .padding(.bottom, 6)
                }
            }
            .ignoresSafeArea()
        }
        // Digital Crown wiring
        .focusable()
        .digitalCrownRotation(
            $crownValue,
            from: 0,
            through: Double(aliens.count - 1),
            by: 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: false
        )
        .onChange(of: crownValue) { newVal in
            let newIndex = Int(newVal.rounded())
                .clamped(to: 0...(aliens.count - 1))
            guard newIndex != selectedIndex else { return }
            slideDirection = newIndex > selectedIndex ? 1 : -1
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedIndex = newIndex
            }
            WKInterfaceDevice.current().play(.click)
        }
        // Swipe gesture
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.width < -20 { nextAlien() }
                    else if value.translation.width > 20 { previousAlien() }
                }
        )
        .onAppear {
            crownValue = Double(selectedIndex)
        }
    }

    // MARK: - Subviews

    private var indicatorDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<aliens.count, id: \.self) { i in
                let active = i == selectedIndex
                Circle()
                    .fill(active ? Color.omnitrixGreen : Color.metalGrey.opacity(0.5))
                    .frame(width: active ? 6 : 4, height: active ? 6 : 4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIndex)
            }
        }
    }

    @ViewBuilder
    private func alienCard(alien: Alien) -> some View {
        VStack(spacing: 5) {
            // Alien emoji
            Text(alien.emoji)
                .font(.system(size: 52))
                .shadow(color: Color.omnitrixGreen.opacity(0.55), radius: 8)

            // Alien name
            Text(alien.name.uppercased())
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundColor(.omnitrixGreen)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            // Power description
            Text(alien.power)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.metalGrey)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
        }
    }

    private var navRow: some View {
        HStack {
            // Prev
            Button(action: previousAlien) {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.omnitrixGreen)
            }
            .buttonStyle(.plain)

            Spacer()

            // Transform
            Button(action: onTransform) {
                Text("TRANSFORM")
                    .font(.system(.caption2, design: .monospaced, weight: .black))
                    .foregroundColor(.deepBlack)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.omnitrixGreen)
                    .cornerRadius(4)
                    .shadow(color: Color.omnitrixGreen.opacity(0.7), radius: 6)
            }
            .buttonStyle(.plain)

            Spacer()

            // Next
            Button(action: nextAlien) {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.omnitrixGreen)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Transitions

    private var slideTransition: AnyTransition {
        let insertEdge: Edge = slideDirection >= 0 ? .trailing : .leading
        let removeEdge: Edge = slideDirection >= 0 ? .leading  : .trailing
        return .asymmetric(
            insertion: .move(edge: insertEdge).combined(with: .opacity),
            removal:   .move(edge: removeEdge).combined(with: .opacity)
        )
    }

    // MARK: - Navigation

    private func nextAlien() {
        guard selectedIndex < aliens.count - 1 else { return }
        slideDirection = 1
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedIndex += 1
        }
        crownValue = Double(selectedIndex)
        WKInterfaceDevice.current().play(.click)
    }

    private func previousAlien() {
        guard selectedIndex > 0 else { return }
        slideDirection = -1
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedIndex -= 1
        }
        crownValue = Double(selectedIndex)
        WKInterfaceDevice.current().play(.click)
    }
}

// MARK: - Comparable clamped helper

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
