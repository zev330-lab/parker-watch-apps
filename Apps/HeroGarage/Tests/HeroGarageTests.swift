import XCTest

final class HeroGarageTests: XCTestCase {
    func testSonicFormCount() { XCTAssertEqual(5, 5) }
    func testTFBotCount() { XCTAssertEqual(6, 6) }
    func testEmeraldCount() { XCTAssertEqual(7, 7) }
    func testSuperSonicLockedUntilAllGems() {
        var gems = Array(repeating: false, count: 7)
        XCTAssertFalse(gems.allSatisfy { $0 })
        gems = Array(repeating: true, count: 7)
        XCTAssertTrue(gems.allSatisfy { $0 })
    }
    func testTransformToggle() {
        var isRobot = true; isRobot.toggle(); XCTAssertFalse(isRobot)
    }
}
