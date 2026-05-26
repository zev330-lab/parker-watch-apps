// BattleService.swift
// Backend: Firebase Realtime Database REST API + battle matrix + result logic

import Foundation

// MARK: - Shared Data Model

struct BattleRoom: Equatable {
    var parker: String?
    var havi:   String?
    var round:        Int
    var parker_score: Int
    var havi_score:   Int
}

// Custom Codable so nil is encoded as JSON null (not omitted)
extension BattleRoom: Codable {
    enum CodingKeys: String, CodingKey {
        case parker, havi, round, parker_score, havi_score
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        parker       = try c.decodeIfPresent(String.self, forKey: .parker)
        havi         = try c.decodeIfPresent(String.self, forKey: .havi)
        round        = (try? c.decode(Int.self, forKey: .round)) ?? 1
        parker_score = (try? c.decode(Int.self, forKey: .parker_score)) ?? 0
        havi_score   = (try? c.decode(Int.self, forKey: .havi_score)) ?? 0
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(parker, forKey: .parker)
        try c.encode(havi,   forKey: .havi)
        try c.encode(round,        forKey: .round)
        try c.encode(parker_score, forKey: .parker_score)
        try c.encode(havi_score,   forKey: .havi_score)
    }
}

// MARK: - Battle Result

enum BattleResult {
    case parkerWins, haviWins, tie

    var label: String {
        switch self {
        case .parkerWins: return "PARKER WINS!"
        case .haviWins:   return "HAVI WINS!"
        case .tie:        return "TIE!"
        }
    }
}

// MARK: - Service

final class BattleService {

    static let shared = BattleService()
    private init() {}

    private let baseURL = "https://omnitrix-battle-default-rtdb.firebaseio.com/game.json"

    // MARK: - Battle Matrix
    // Result from Parker's perspective: W = Parker wins, L = Parker loses, T = Tie
    private let matrix: [String: [String: String]] = [
        "Heatblast":   ["Lightning":"L","Ocean":"L","Fire":"T","Wind":"W","Earth":"W","Sun":"W","Ice":"W","Bloom":"L","Moon":"L","Volcano":"W"],
        "XLR8":        ["Lightning":"W","Ocean":"W","Fire":"L","Wind":"W","Earth":"L","Sun":"L","Ice":"W","Bloom":"L","Moon":"W","Volcano":"L"],
        "Diamondhead": ["Lightning":"L","Ocean":"W","Fire":"W","Wind":"L","Earth":"W","Sun":"W","Ice":"W","Bloom":"L","Moon":"L","Volcano":"L"],
        "Four Arms":   ["Lightning":"L","Ocean":"W","Fire":"W","Wind":"L","Earth":"W","Sun":"L","Ice":"W","Bloom":"L","Moon":"L","Volcano":"L"],
        "Wildmutt":    ["Lightning":"W","Ocean":"L","Fire":"L","Wind":"W","Earth":"W","Sun":"L","Ice":"L","Bloom":"W","Moon":"W","Volcano":"L"],
        "Grey Matter": ["Lightning":"W","Ocean":"L","Fire":"W","Wind":"L","Earth":"L","Sun":"W","Ice":"L","Bloom":"W","Moon":"W","Volcano":"L"],
        "Stinkfly":    ["Lightning":"L","Ocean":"L","Fire":"L","Wind":"W","Earth":"W","Sun":"W","Ice":"L","Bloom":"W","Moon":"W","Volcano":"W"],
        "Ripjaws":     ["Lightning":"L","Ocean":"W","Fire":"L","Wind":"L","Earth":"L","Sun":"W","Ice":"W","Bloom":"W","Moon":"W","Volcano":"W"],
        "Upgrade":     ["Lightning":"W","Ocean":"W","Fire":"L","Wind":"W","Earth":"L","Sun":"L","Ice":"L","Bloom":"L","Moon":"W","Volcano":"W"],
        "Ghostfreak":  ["Lightning":"W","Ocean":"L","Fire":"W","Wind":"W","Earth":"L","Sun":"L","Ice":"L","Bloom":"W","Moon":"W","Volcano":"L"],
    ]

    // MARK: - Network

    func fetchRoom() async throws -> BattleRoom {
        var req = URLRequest(url: URL(string: baseURL)!)
        req.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(BattleRoom.self, from: data)
    }

    func writeRoom(_ room: BattleRoom) async throws {
        var req = URLRequest(url: URL(string: baseURL)!)
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(room)
        _ = try await URLSession.shared.data(for: req)
    }

    /// Atomic read-modify-write: fetches current room, applies a mutation, writes back.
    func updateRoom(_ mutate: (inout BattleRoom) -> Void) async throws -> BattleRoom {
        var room = try await fetchRoom()
        mutate(&room)
        try await writeRoom(room)
        return room
    }

    // MARK: - Logic

    func computeResult(parker: String, havi: String) -> BattleResult {
        switch matrix[parker]?[havi] {
        case "W": return .parkerWins
        case "L": return .haviWins
        default:  return .tie
        }
    }
}
