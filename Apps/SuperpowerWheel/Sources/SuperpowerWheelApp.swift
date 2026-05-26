import SwiftUI
import HeroKit

@main
struct SuperpowerWheelApp: App {
    var body: some Scene {
        WindowGroup {
            HeroGate(appKey: "superpowers", challenge: .putToyAway) {
                ContentView()
            }
        }
    }
}
