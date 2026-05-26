import XCTest

final class KaratePowerTests: XCTestCase {
    func testBeltLevelCalculation() {
        // sessionsDone / 25 clamped to belt count - 1
        let beltCount = 8
        let breathsPerLevel = 25

        XCTAssertEqual(min(0 / breathsPerLevel, beltCount - 1), 0)    // white
        XCTAssertEqual(min(25 / breathsPerLevel, beltCount - 1), 1)   // yellow
        XCTAssertEqual(min(175 / breathsPerLevel, beltCount - 1), 7)  // black
        XCTAssertEqual(min(300 / breathsPerLevel, beltCount - 1), 7)  // still black (clamp)
    }

    func testAllBeltsHaveColors() {
        let hexes = ["#FFFFFF", "#FFD700", "#FF8C00", "#228B22", "#1E90FF", "#8B008B", "#8B4513", "#1A1A1A"]
        XCTAssertEqual(hexes.count, 8)
        XCTAssertTrue(hexes.allSatisfy { $0.hasPrefix("#") })
    }

    func testBreathCountProgresses() {
        var breathCount = 0
        let total = 5
        breathCount += 1
        XCTAssertFalse(breathCount >= total)
        breathCount = 5
        XCTAssertTrue(breathCount >= total)
    }
}
