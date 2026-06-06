import XCTest
@testable import MahjongCore

final class HonorTests: XCTestCase {
    func testWindHonor() {
        let h = Honor.wind(.east)
        if case .wind(let w) = h {
            XCTAssertEqual(w, .east)
        } else {
            XCTFail("Expected .wind case")
        }
    }

    func testDragonHonors() {
        XCTAssertNotEqual(Honor.white, Honor.green)
        XCTAssertNotEqual(Honor.green, Honor.red)
        XCTAssertNotEqual(Honor.white, Honor.red)
    }

    func testAllDragons() {
        let dragons: Set<Honor> = [.white, .green, .red]
        XCTAssertEqual(dragons.count, 3)
    }

    func testCodableRoundTrip() throws {
        let cases: [Honor] = [.wind(.north), .white, .green, .red]
        for honor in cases {
            let data = try JSONEncoder().encode(honor)
            let decoded = try JSONDecoder().decode(Honor.self, from: data)
            XCTAssertEqual(decoded, honor)
        }
    }
}
