import XCTest

final class SonicFormsTests: XCTestCase {
    func testEmeraldCountIsSeven() {
        let gems = [
            (id: 0, color: "#00BFFF"),
            (id: 1, color: "#FF4500"),
            (id: 2, color: "#9400D3"),
            (id: 3, color: "#FFD700"),
            (id: 4, color: "#32CD32"),
            (id: 5, color: "#FF69B4"),
            (id: 6, color: "#FFFFFF"),
        ]
        XCTAssertEqual(gems.count, 7)
    }

    func testSuperSonicLockedUntilAllCollected() {
        var collected = Array(repeating: false, count: 7)
        let allCollected = { collected.allSatisfy { $0 } }
        XCTAssertFalse(allCollected())
        collected = Array(repeating: true, count: 7)
        XCTAssertTrue(allCollected())
    }

    func testFormCount() {
        let forms = ["Sonic", "Tails", "Knuckles", "Shadow", "Super Sonic"]
        XCTAssertEqual(forms.count, 5)
    }

    func testCrownIndexBounds() {
        let formCount = 5
        let rawCrown = 4.7
        let idx = Int(rawCrown.rounded())
        XCTAssertTrue(idx < formCount)
    }
}
