// ContentView.swift
// Root navigator — owns AppScreen state, routes between all views

import SwiftUI
import WatchKit

// MARK: - App Screen

enum AppScreen: Equatable {
    case watchFace
    case alienSelector
    case transform(Int)
    case battle

    static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
        switch (lhs, rhs) {
        case (.watchFace,     .watchFace):     return true
        case (.alienSelector, .alienSelector): return true
        case (.transform(let a), .transform(let b)): return a == b
        case (.battle,        .battle):        return true
        default: return false
        }
    }
}

// MARK: - Root View

struct ContentView: View {

    @State private var screen:            AppScreen = .watchFace
    @State private var selectedAlienIndex: Int      = 0

    var body: some View {
        ZStack {
            Color.deepBlack.ignoresSafeArea()

            Group {
                switch screen {

                case .watchFace:
                    WatchFaceView(
                        onActivate: activateSelector,
                        onBattle:   activateBattle
                    )
                    .transition(.opacity)

                case .alienSelector:
                    AlienSelectorView(
                        selectedIndex: $selectedAlienIndex,
                        onTransform:   triggerTransform,
                        onBack:        returnToWatchFace
                    )
                    .transition(
                        .scale(scale: 0.1, anchor: .center)
                        .combined(with: .opacity)
                    )

                case .transform(let index):
                    TransformView(
                        alien: Alien.all[index],
                        onComplete: returnToWatchFace
                    )
                    .transition(.opacity)

                case .battle:
                    BattleView(onDismiss: returnToWatchFace)
                        .transition(.asymmetric(
                            insertion:  .move(edge: .bottom).combined(with: .opacity),
                            removal:    .move(edge: .bottom).combined(with: .opacity)
                        ))
                }
            }
        }
    }

    // MARK: - Navigation

    private func activateSelector() {
        WKInterfaceDevice.current().play(.click)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            screen = .alienSelector
        }
    }

    private func triggerTransform() {
        WKInterfaceDevice.current().play(.directionUp)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            screen = .transform(selectedAlienIndex)
        }
    }

    private func activateBattle() {
        WKInterfaceDevice.current().play(.directionUp)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            screen = .battle
        }
    }

    private func returnToWatchFace() {
        withAnimation(.easeInOut(duration: 0.5)) {
            screen = .watchFace
        }
    }
}
