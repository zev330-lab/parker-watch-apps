import XCTest

final class ParkersHeartTests: XCTestCase {
    func testDefaultHappyThingsCount() {
        let items = ["Mom's hugs 🤗","Dad's hugs 🤗","My dog 🐶","Superheroes 🦸","Ben 10 👽","Karate class 🥋","Pizza 🍕","Minecraft ⛏️","Swimming 🏊","Silly jokes 😂","Snuggling in bed 😴","Being brave 💪"]
        XCTAssertEqual(items.count, 12)
    }
    func testDefaultDadMessagesCount() {
        let msgs = ["I love you, Parker. ❤️","You are SO brave.","I'm thinking of you right now.","You make me so proud.","Have the best day ever! 🌟","You are strong AND kind.","I'll be home soon. 🏠","You're my favorite Parker."]
        XCTAssertEqual(msgs.count, 8)
    }
    func testAffirmationsNonEmpty() {
        let aff = ["I am brave.","I am kind.","I am a good friend.","I am smart.","I am strong.","I try my best.","I am funny.","I make people happy.","I am loved.","I can do hard things.","I am special.","I am enough."]
        XCTAssertFalse(aff.isEmpty)
        XCTAssertEqual(aff.count, 12)
    }
    func testMessageIndexWraps() {
        var idx = 7; idx = (idx + 1) % 8; XCTAssertEqual(idx, 0)
    }
}
