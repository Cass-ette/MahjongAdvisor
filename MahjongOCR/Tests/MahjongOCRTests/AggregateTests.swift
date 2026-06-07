import XCTest
@testable import MahjongOCR
import MahjongCore

final class AggregateTests: XCTestCase {

    func testAggregate_AllAgree_Confirm() {
        let passes: [[HandTileCandidate]] = [
            [HandTileCandidate(tile: Tile(suit: .m, rank: 5), confidence: 0.9)],
            [HandTileCandidate(tile: Tile(suit: .m, rank: 5), confidence: 0.8)],
            [HandTileCandidate(tile: Tile(suit: .m, rank: 5), confidence: 0.7)],
        ]
        let result = Aggregate.aggregateSlot(passes: passes, threshold: 0.6)
        XCTAssertNotNil(result.confirmed)
        XCTAssertEqual(result.confirmed?.tile, Tile(suit: .m, rank: 5))
        XCTAssertEqual(result.confirmed?.confidence ?? 0, 0.8, accuracy: 0.01)  // avg
    }

    func testAggregate_AllDisagree_Top3() {
        let passes: [[HandTileCandidate]] = [
            [HandTileCandidate(tile: Tile(suit: .m, rank: 5), confidence: 0.9)],
            [HandTileCandidate(tile: Tile(suit: .m, rank: 6), confidence: 0.8)],
            [HandTileCandidate(tile: Tile(suit: .m, rank: 7), confidence: 0.7)],
        ]
        let result = Aggregate.aggregateSlot(passes: passes, threshold: 0.6)
        XCTAssertNil(result.confirmed)
        XCTAssertEqual(result.candidates.count, 3)
        XCTAssertEqual(result.candidates[0].tile, Tile(suit: .m, rank: 5))
    }

    func testAggregate_TwoAgree_Confirm() {
        let passes: [[HandTileCandidate]] = [
            [HandTileCandidate(tile: Tile(suit: .p, rank: 3), confidence: 0.85)],
            [HandTileCandidate(tile: Tile(suit: .p, rank: 3), confidence: 0.75)],
            [HandTileCandidate(tile: Tile(suit: .p, rank: 7), confidence: 0.4)],  // below threshold
        ]
        let result = Aggregate.aggregateSlot(passes: passes, threshold: 0.6)
        XCTAssertNotNil(result.confirmed)
        XCTAssertEqual(result.confirmed?.tile, Tile(suit: .p, rank: 3))
    }

    func testAggregate_EmptyInput() {
        let passes: [[HandTileCandidate]] = [[], [], []]
        let result = Aggregate.aggregateSlot(passes: passes, threshold: 0.6)
        XCTAssertNil(result.confirmed)
        XCTAssertTrue(result.candidates.isEmpty)
    }

    func testAggregate_OnePass_OneCandidate() {
        // Only one pass contributed a candidate (others empty)
        let passes: [[HandTileCandidate]] = [
            [HandTileCandidate(tile: Tile(suit: .s, rank: 9), confidence: 0.75)],
            [],
            [],
        ]
        let result = Aggregate.aggregateSlot(passes: passes, threshold: 0.6)
        XCTAssertNil(result.confirmed, "Single candidate should not be confirmed")
        XCTAssertEqual(result.candidates.count, 1)
        XCTAssertEqual(result.candidates[0].tile, Tile(suit: .s, rank: 9))
    }

    func testAggregateHand_MultiSlot() {
        // Test aggregateHand with multiple slots
        let slots: [[[HandTileCandidate]]] = [
            // Slot 0: 3 agree on 1m
            [
                [HandTileCandidate(tile: Tile(suit: .m, rank: 1), confidence: 0.9)],
                [HandTileCandidate(tile: Tile(suit: .m, rank: 1), confidence: 0.8)],
                [HandTileCandidate(tile: Tile(suit: .m, rank: 1), confidence: 0.7)],
            ],
            // Slot 1: all disagree
            [
                [HandTileCandidate(tile: Tile(suit: .p, rank: 5), confidence: 0.9)],
                [HandTileCandidate(tile: Tile(suit: .p, rank: 6), confidence: 0.8)],
                [HandTileCandidate(tile: Tile(suit: .p, rank: 7), confidence: 0.7)],
            ],
        ]
        let results = Aggregate.aggregateHand(slots: slots, threshold: 0.6)
        XCTAssertEqual(results.count, 2)
        XCTAssertNotNil(results[0].confirmed, "Slot 0 should be confirmed")
        XCTAssertNil(results[1].confirmed, "Slot 1 should not be confirmed")
        XCTAssertEqual(results[0].confirmed?.tile, Tile(suit: .m, rank: 1))
    }
}
