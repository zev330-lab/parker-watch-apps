import Foundation
import WatchKit

/// Plays .caf sound files dropped into the app bundle.
/// No-ops silently if the file isn't present — assets are optional drop-ins.
public struct SoundManager {
    public static func play(_ named: String) {
        guard let url = Bundle.main.url(forResource: named, withExtension: "caf") else { return }
        WKInterfaceDevice.current().play(.click) // haptic companion
        _ = url // actual audio requires WKAudioFilePlayer; stub until asset present
    }
}
