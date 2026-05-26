import CloudKit
import Foundation

private let containerID = "iCloud.com.zevgt.parkersheart"
private let recordType  = "DadMessages"
private let recordName  = "dad-messages-v1"

struct DadCloudKitStore {

    static func fetch() async throws -> [String] {
        let db = CKContainer(identifier: containerID).privateCloudDatabase
        let id = CKRecord.ID(recordName: recordName)
        do {
            let record = try await db.record(for: id)
            return decode(record) ?? []
        } catch let err as CKError where err.code == .unknownItem {
            return [] // no record yet — first launch
        }
    }

    static func save(_ messages: [String]) async throws {
        let db = CKContainer(identifier: containerID).privateCloudDatabase
        let id = CKRecord.ID(recordName: recordName)

        let record: CKRecord
        do {
            record = try await db.record(for: id)
        } catch let err as CKError where err.code == .unknownItem {
            record = CKRecord(recordType: recordType, recordID: id)
        }

        let json = String(data: try JSONEncoder().encode(messages), encoding: .utf8)!
        record["messages"] = json
        try await db.save(record)
    }

    private static func decode(_ record: CKRecord) -> [String]? {
        guard let json = record["messages"] as? String,
              let data = json.data(using: .utf8),
              let msgs = try? JSONDecoder().decode([String].self, from: data)
        else { return nil }
        return msgs
    }
}
