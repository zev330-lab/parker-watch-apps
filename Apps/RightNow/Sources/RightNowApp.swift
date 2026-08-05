import SwiftUI
import HeroKit

@main
struct RightNowApp: App {
    var body: some Scene {
        WindowGroup {
            HeroGate(appKey: "rightnow",
                     challenges: [.giveCompliment, .putToyAway, .countToTen, .selfAffirmation]) {
                ContentView()
            }
        }
    }
}
