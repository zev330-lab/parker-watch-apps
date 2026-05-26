import WatchKit

/// Named haptic patterns for all Parker apps.
public enum HapticPattern {
    case tap           // single confirmation
    case doubleTap     // selection / pick
    case surge         // power-up / transform
    case click         // mechanical / precise
    case success       // mission complete / unlock
    case heartbeat     // calm inhale pulse
    case directionUp   // Crown scroll up cue
    case directionDown // Crown scroll down cue
    case retry         // try again
    case notification  // incoming message
}

public struct HapticEngine {
    public static func play(_ pattern: HapticPattern) {
        let device = WKInterfaceDevice.current()
        switch pattern {
        case .tap:           device.play(.click)
        case .doubleTap:     device.play(.success)
        case .surge:         device.play(.start)
        case .click:         device.play(.click)
        case .success:       device.play(.success)
        case .heartbeat:     device.play(.click)
        case .directionUp:   device.play(.directionUp)
        case .directionDown: device.play(.directionDown)
        case .retry:         device.play(.retry)
        case .notification:  device.play(.notification)
        }
    }
}
