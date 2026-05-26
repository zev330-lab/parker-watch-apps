import SwiftUI
import HeroKit

@main
struct SecretMissionApp: App {
    var body: some Scene {
        WindowGroup {
            HeroGate(appKey: "secretmission", challenge: .forgiveSomeone, accentColor: .green) {
                ContentView()
            }
        }
    }
}
