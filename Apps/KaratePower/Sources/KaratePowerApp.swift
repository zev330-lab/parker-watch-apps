import SwiftUI
import HeroKit

@main
struct KaratePowerApp: App {
    var body: some Scene {
        WindowGroup {
            // Karate gate: say something kind before centering yourself
            HeroGate(appKey: "karate", challenge: .sayILoveYou, accentColor: .white) {
                ContentView()
            }
        }
    }
}
