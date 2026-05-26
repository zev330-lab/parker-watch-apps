import XCTest

final class HappyThingsTests: XCTestCase {
    func testDefaultListNonEmpty() {
        // Default list of 12 items
        let defaults = [
            "Mom's hugs 🤗", "Dad's hugs 🤗", "My dog 🐶",
            "Superheroes 🦸", "Ben 10 👽", "Karate class 🥋",
            "Pizza 🍕", "Minecraft ⛏️", "Swimming 🏊",
            "Silly jokes 😂", "Snuggling in bed 😴", "Being brave 💪",
        ]
        XCTAssertEqual(defaults.count, 12)
        XCTAssertFalse(defaults.isEmpty)
    }

    func testRandomElementNeverCrashesOnNonEmptyList() {
        let list = ["a", "b", "c"]
        let pick = list.randomElement()
        XCTAssertNotNil(pick)
    }
}
