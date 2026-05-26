// Alien.swift
// Model + Color palette for the Omnitrix app

import SwiftUI

// MARK: - Color Palette

extension Color {
    /// Omnitrix signature green #00FF40
    static let omnitrixGreen = Color(red: 0.0,  green: 1.0,  blue: 0.25)
    /// Deep near-black background
    static let deepBlack     = Color(red: 0.04, green: 0.04, blue: 0.06)
    /// Inactive / metadata grey
    static let metalGrey     = Color(red: 0.25, green: 0.25, blue: 0.28)
}

// MARK: - Alien Model

struct Alien: Identifiable, Hashable {
    let id: Int
    let name: String
    let emoji: String
    let power: String
}

extension Alien {
    static let all: [Alien] = [
        Alien(id: 0, name: "Heatblast",    emoji: "🔥", power: "Fire & Heat Control"),
        Alien(id: 1, name: "Wildmutt",     emoji: "🐾", power: "Super Senses & Strength"),
        Alien(id: 2, name: "Diamondhead",  emoji: "💎", power: "Crystal Armor & Blasts"),
        Alien(id: 3, name: "XLR8",         emoji: "⚡", power: "Extreme Super Speed"),
        Alien(id: 4, name: "Grey Matter",  emoji: "🧠", power: "Super Intelligence"),
        Alien(id: 5, name: "Four Arms",    emoji: "💪", power: "Mega Strength & Power"),
        Alien(id: 6, name: "Stinkfly",     emoji: "🦟", power: "Flight & Slime Attack"),
        Alien(id: 7, name: "Ripjaws",      emoji: "🦈", power: "Deep Sea Jaw Power"),
        Alien(id: 8, name: "Upgrade",      emoji: "🤖", power: "Tech Control & Laser"),
        Alien(id: 9,  name: "Ghostfreak",    emoji: "👻", power: "Ghost Phasing & Invisibility"),
        Alien(id: 10, name: "Overflow",      emoji: "💧", power: "Twin water cannons!"),
        Alien(id: 11, name: "Humungousaur",  emoji: "🦖", power: "Grows huge & SMASHES!"),
    ]
}
