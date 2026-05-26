import CloudKit
import Foundation

// Shared container — both the iOS and watchOS apps point at the same one.
private let containerID = "iCloud.com.zevgt.parkersheart"
private let recordType  = "DadMessages"
private let recordName  = "dad-messages-v1"
private let cacheKey    = "heart.dad.ck.cache"

/// Lightweight async CloudKit store used by the watchOS DadPage.
struct CloudKitMessageStore {

    static func fetch() async -> [String]? {
        let db = CKContainer(identifier: containerID).privateCloudDatabase
        let id = CKRecord.ID(recordName: recordName)
        do {
            let record = try await db.record(for: id)
            return decode(record)
        } catch {
            return nil
        }
    }

    static func cache(_ messages: [String]) {
        let data = (try? JSONEncoder().encode(messages)) ?? Data()
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    static func loadCache() -> [String] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let msgs = try? JSONDecoder().decode([String].self, from: data),
              !msgs.isEmpty else { return [] }
        return msgs
    }

    private static func decode(_ record: CKRecord) -> [String]? {
        guard let json = record["messages"] as? String,
              let data = json.data(using: .utf8),
              let msgs = try? JSONDecoder().decode([String].self, from: data)
        else { return nil }
        return msgs
    }
}
