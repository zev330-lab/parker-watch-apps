import SwiftUI
import HeroKit

@main
struct TransformersApp: App {
    var body: some Scene {
        WindowGroup {
            HeroGate(appKey: "transformers", challenge: .sayILoveYou, accentColor: .red) {
                ContentView()
            }
        }
    }
}
