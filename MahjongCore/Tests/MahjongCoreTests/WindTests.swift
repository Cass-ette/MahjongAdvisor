import XCTest
@testable import MahjongCore

final class WindTests: XCTestCase {
    func testRawValues() {
        XCTAssertEqual(Wind.east.rawValue, 1)
        XCTAssertEqual(Wind.south.rawValue, 2)
        XCTAssertEqual(Wind.west.rawValue, 3)
        XCTAssertEqual(Wind.north.rawValue, 4)
    }

    func testAllCases() {
        XCTAssertEqual(Wind.allCases.count, 4)
    }

    func testCodableRoundTrip() throws {
        for wind in Wind.allCases {
            let data = try JSONEncoder().encode(wind)
            let decoded = try JSONDecoder().decode(Wind.self, from: data)
            XCTAssertEqual(decoded, wind)
        }
    }
}
