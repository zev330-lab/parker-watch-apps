import SwiftUI
import HeroKit

// MARK: - Chaos Emerald

struct ChaosEmerald: Identifiable, Codable {
    let id: Int
    var collected: Bool = false
    let color: String
    let emoji: String

    static let all: [ChaosEmerald] = [
        ChaosEmerald(id: 0, color: "#00BFFF", emoji: "💠"),
        ChaosEmerald(id: 1, color: "#FF4500", emoji: "🔴"),
        ChaosEmerald(id: 2, color: "#9400D3", emoji: "🟣"),
        ChaosEmerald(id: 3, color: "#FFD700", emoji: "🟡"),
        ChaosEmerald(id: 4, color: "#32CD32", emoji: "🟢"),
        ChaosEmerald(id: 5, color: "#FF69B4", emoji: "🩷"),
        ChaosEmerald(id: 6, color: "#FFFFFF", emoji: "🤍"),
    ]
}

// MARK: - Sonic Form

struct SonicForm: Identifiable {
    let id: Int
    let name: String
    let tagline: String
    let emoji: String
    let color: Color
    let haptic: HapticPattern
    let crownMove: String
    let isLocked: Bool

    static var all: [SonicForm] = [
        SonicForm(id: 0, name: "Sonic",       tagline: "Gotta go fast!",         emoji: "💨", color: .blue,   haptic: .surge,    crownMove: "SPIN DASH", isLocked: false),
        SonicForm(id: 1, name: "Tails",        tagline: "I can fly!",             emoji: "✈️", color: .yellow, haptic: .click,    crownMove: "PROPELLER", isLocked: false),
        SonicForm(id: 2, name: "Knuckles",     tagline: "Digging deep!",          emoji: "⛏️", color: .red,    haptic: .doubleTap,crownMove: "GROUND POUND", isLocked: false),
        SonicForm(id: 3, name: "Shadow",       tagline: "Chaos Control!",         emoji: "🌑", color: Color(red:0.1,green:0.1,blue:0.1), haptic: .tap, crownMove: "TELEPORT", isLocked: false),
        SonicForm(id: 4, name: "Super Sonic",  tagline: "UNLIMITED POWER! ⭐",    emoji: "⭐", color: .yellow, haptic: .success,  crownMove: "HYPER DASH", isLocked: true),
    ]
}
