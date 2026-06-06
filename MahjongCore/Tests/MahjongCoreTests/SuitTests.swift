import XCTest
@testable import MahjongCore

final class SuitTests: XCTestCase {
    func testAllCases() {
        XCTAssertEqual(Suit.allCases.count, 4)
        XCTAssertEqual(Suit.m.rawValue, "m")
        XCTAssertEqual(Suit.p.rawValue, "p")
        XCTAssertEqual(Suit.s.rawValue, "s")
        XCTAssertEqual(Suit.z.rawValue, "z")
    }

    func testIsNumberSuit() {
        XCTAssertTrue(Suit.m.isNumberSuit)
        XCTAssertTrue(Suit.p.isNumberSuit)
        XCTAssertTrue(Suit.s.isNumberSuit)
        XCTAssertFalse(Suit.z.isNumberSuit)
    }

    func testCodableRoundTrip() throws {
        for suit in Suit.allCases {
            let data = try JSONEncoder().encode(suit)
            let decoded = try JSONDecoder().decode(Suit.self, from: data)
            XCTAssertEqual(decoded, suit)
        }
    }
}
