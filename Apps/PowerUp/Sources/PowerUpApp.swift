import SwiftUI
import HeroKit

@main
struct PowerUpApp: App {
    var body: some Scene {
        WindowGroup {
            // The gate IS a breath — one centering breath unlocks the whole power suite
            HeroGate(appKey: "powerup", challenge: .deepBreath, accentColor: .cyan) {
                ContentView()
            }
        }
    }
}
