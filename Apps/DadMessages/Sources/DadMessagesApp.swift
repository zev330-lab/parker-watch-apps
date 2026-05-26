import SwiftUI
import HeroKit

@main
struct DadMessagesApp: App {
    var body: some Scene {
        WindowGroup {
            HeroGate(appKey: "dadmessages", challenge: .sayPlease) {
                ContentView()
            }
        }
    }
}
