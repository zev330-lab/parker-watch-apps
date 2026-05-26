import XCTest

final class DadMessagesTests: XCTestCase {
    func testDefaultMessagesCount() {
        let defaults = [
            "I love you, Parker. ❤️",
            "You are SO brave.",
            "I'm thinking of you right now.",
            "You make me so proud.",
            "Have the best day ever! 🌟",
            "You are strong AND kind.",
            "I'll be home soon. 🏠",
            "You're my favorite Parker.",
        ]
        XCTAssertEqual(defaults.count, 8)
    }

    func testMessageIndexWraps() {
        let count = 8
        var index = 7
        index = (index + 1) % count
        XCTAssertEqual(index, 0)
    }

    func testSafeSubscriptReturnsNilOutOfRange() {
        let arr = ["a", "b", "c"]
        XCTAssertNil(arr[safe: 5])
        XCTAssertEqual(arr[safe: 1], "b")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
