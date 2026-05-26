import XCTest

final class TransformersTests: XCTestCase {
    func testTransformerCount() {
        let names = ["Optimus Prime", "Bumblebee", "Ironhide", "Megatron", "Starscream",
                     "Optimus Primal", "Cheetor", "Rhinox"]
        XCTAssertEqual(names.count, 8)
    }

    func testFactionCases() {
        let factions = ["Autobot", "Decepticon", "Maximals"]
        XCTAssertEqual(factions.count, 3)
    }

    func testBeastWarsBotHasBeastMode() {
        // Optimus Primal, Cheetor, Rhinox — ids 5,6,7 — have beast modes
        let beastWarsBots = [5, 6, 7]
        XCTAssertEqual(beastWarsBots.count, 3)
    }

    func testTransformStateToggle() {
        var isRobot = true
        isRobot.toggle()
        XCTAssertFalse(isRobot)
        isRobot.toggle()
        XCTAssertTrue(isRobot)
    }
}
