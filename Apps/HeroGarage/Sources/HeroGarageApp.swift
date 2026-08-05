import SwiftUI
import HeroKit

@main
struct HeroGarageApp: App {
    var body: some Scene {
        WindowGroup {
            HeroGate(appKey: "herogarage",
                     challenges: [.giveCompliment, .putToyAway, .jumpingJacks, .countToTen]) {
                ContentView()
            }
        }
    }
}
