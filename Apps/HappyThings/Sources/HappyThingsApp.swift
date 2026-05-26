import SwiftUI
import HeroKit

@main
struct HappyThingsApp: App {
    var body: some Scene {
        WindowGroup {
            HeroGate(appKey: "happythings", challenge: .giveCompliment) {
                ContentView()
            }
        }
    }
}
