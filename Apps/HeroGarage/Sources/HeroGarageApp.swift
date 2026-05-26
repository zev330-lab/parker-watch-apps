import SwiftUI
import HeroKit

@main
struct HeroGarageApp: App {
    var body: some Scene {
        WindowGroup {
            HeroGate(appKey: "herogarage", challenge: .jumpingJacks, accentColor: .orange) {
                ContentView()
            }
        }
    }
}
