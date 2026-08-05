import CloudKit
import Foundation

private let containerID = "iCloud.com.zevgt.parkersheart"
private let recordType  = "HappyThings"
private let recordName  = "happy-things-v1"

struct HappyThingsCloudKitStore {

    static func fetch() async -> [String]? {
        let db = CKContainer(identifier: containerID).privateCloudDatabase
        let id = CKRecord.ID(recordName: recordName)
        do {
            let record = try await db.record(for: id)
            return decode(record)
        } catch let err as CKError where err.code == .unknownItem {
            return nil
        } catch {
            return nil
        }
    }

    static func save(_ items: [String]) async throws {
        let db = CKContainer(identifier: containerID).privateCloudDatabase
        let id = CKRecord.ID(recordName: recordName)

        let record: CKRecord
        do {
            record = try await db.record(for: id)
        } catch let err as CKError where err.code == .unknownItem {
            record = CKRecord(recordType: recordType, recordID: id)
        }

        let json = String(data: try JSONEncoder().encode(items), encoding: .utf8)!
        record["items"] = json
        try await db.save(record)
    }

    private static func decode(_ record: CKRecord) -> [String]? {
        guard let json = record["items"] as? String,
              let data = json.data(using: .utf8),
              let items = try? JSONDecoder().decode([String].self, from: data)
        else { return nil }
        return items
    }
}
