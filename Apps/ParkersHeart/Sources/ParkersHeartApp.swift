import SwiftUI
import HeroKit

@main
struct ParkersHeartApp: App {
    var body: some Scene {
        WindowGroup {
            HeroGate(appKey: "parkersheart",
                     challenges: [.giveCompliment, .putToyAway, .countToTen, .jumpingJacks]) {
                ContentView()
            }
        }
    }
}
