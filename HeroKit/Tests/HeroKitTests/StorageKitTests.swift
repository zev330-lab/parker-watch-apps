import XCTest
@testable import HeroKit

final class StorageKitTests: XCTestCase {
    func testRoundTrip() {
        let key = "test.roundtrip"
        StorageKit.save([1, 2, 3], key: key)
        let loaded = StorageKit.load([Int].self, key: key, default: [])
        XCTAssertEqual(loaded, [1, 2, 3])
        StorageKit.clear(key: key)
    }

    func testDefaultWhenAbsent() {
        let val = StorageKit.load(String.self, key: "nonexistent.key", default: "hello")
        XCTAssertEqual(val, "hello")
    }

    func testClear() {
        let key = "test.clear"
        StorageKit.save("parker", key: key)
        StorageKit.clear(key: key)
        let val = StorageKit.load(String.self, key: key, default: "default")
        XCTAssertEqual(val, "default")
    }
}
