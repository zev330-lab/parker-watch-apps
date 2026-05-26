import SwiftUI
import HeroKit

@main
struct SonicFormsApp: App {
    var body: some Scene {
        WindowGroup {
            HeroGate(appKey: "sonic", challenge: .jumpingJacks, accentColor: .blue) {
                ContentView()
            }
        }
    }
}
