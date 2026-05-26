import SwiftUI
import HeroKit

@main
struct ParkersHeartApp: App {
    var body: some Scene {
        WindowGroup {
            HeroGate(appKey: "parkersheart", challenge: .selfAffirmation) {
                ContentView()
            }
        }
    }
}
