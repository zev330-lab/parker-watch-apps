import SwiftUI

enum Faction: String, Codable, CaseIterable {
    case autobot   = "Autobot"
    case decepticon = "Decepticon"
    case maximals  = "Maximals"

    var emblem: String {
        switch self {
        case .autobot:    return "🔵"
        case .decepticon: return "🟣"
        case .maximals:   return "🦁"
        }
    }
    var color: Color {
        switch self {
        case .autobot:    return .blue
        case .decepticon: return .purple
        case .maximals:   return .orange
        }
    }
}

struct Transformer: Identifiable {
    let id: Int
    let name: String
    let vehicleMode: String   // robot → vehicle label
    let beastMode: String?    // Beast Wars only
    let faction: Faction
    let emblem: String
    let color: Color

    static let all: [Transformer] = [
        Transformer(id: 0, name: "Optimus Prime",  vehicleMode: "Semi Truck 🚛",    beastMode: nil,         faction: .autobot,    emblem: "🔵", color: .blue),
        Transformer(id: 1, name: "Bumblebee",       vehicleMode: "Sports Car 🏎",    beastMode: nil,         faction: .autobot,    emblem: "🟡", color: .yellow),
        Transformer(id: 2, name: "Ironhide",        vehicleMode: "Pickup Truck 🛻",  beastMode: nil,         faction: .autobot,    emblem: "⚫", color: .gray),
        Transformer(id: 3, name: "Megatron",        vehicleMode: "Jet Fighter ✈️",   beastMode: nil,         faction: .decepticon, emblem: "🟣", color: .purple),
        Transformer(id: 4, name: "Starscream",      vehicleMode: "F-15 Jet ✈️",      beastMode: nil,         faction: .decepticon, emblem: "🔴", color: .red),
        Transformer(id: 5, name: "Optimus Primal",  vehicleMode: "Mighty Gorilla 🦍", beastMode: "Gorilla 🦍", faction: .maximals,   emblem: "🦁", color: .orange),
        Transformer(id: 6, name: "Cheetor",         vehicleMode: "Cheetah 🐆",        beastMode: "Cheetah 🐆", faction: .maximals,   emblem: "🟡", color: .yellow),
        Transformer(id: 7, name: "Rhinox",          vehicleMode: "Rhino 🦏",           beastMode: "Rhino 🦏",   faction: .maximals,   emblem: "🟤", color: .brown),
    ]
}
