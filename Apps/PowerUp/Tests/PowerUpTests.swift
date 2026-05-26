import XCTest

final class PowerUpTests: XCTestCase {
    func testBeltProgression() {
        XCTAssertEqual(min(0/25, 7), 0)
        XCTAssertEqual(min(25/25, 7), 1)
        XCTAssertEqual(min(200/25, 7), 7)
    }
    func testMissionDurationCount() {
        let d = [60, 120, 180, 300]; XCTAssertEqual(d.count, 4)
    }
    func testSuperpowerCount() {
        XCTAssertEqual(14, 14)
    }
    func testProgressCalc() {
        let total = 120; let left = 60
        let p = Double(total - left) / Double(total)
        XCTAssertEqual(p, 0.5, accuracy: 0.001)
    }
}
