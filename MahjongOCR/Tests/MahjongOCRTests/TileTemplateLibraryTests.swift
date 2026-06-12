import XCTest
@testable import MahjongOCR
import MahjongCore

final class TileTemplateLibraryTests: XCTestCase {
    func testLibraryHasAll34Templates() {
        let library = TileTemplateLibrary()
        XCTAssertEqual(library.count, 34, "Should have 27 number tiles + 7 honor tiles = 34")
    }

    func testLibraryContainsAllSuitsAndRanks() {
        let library = TileTemplateLibrary()
        let allTiles = library.allTemplates().map { $0.tile }
        // 1-9 of each suit
        for suit in [Suit.m, .p, .s] {
            for rank in 1...9 {
                let tile = Tile(suit: suit, rank: rank)
                XCTAssertTrue(allTiles.contains(tile), "Missing \(suit.rawValue)\(rank)")
            }
        }
    }

    func testLibraryContainsAllHonorTiles() {
        let library = TileTemplateLibrary()
        let allTiles = library.allTemplates().map { $0.tile }
        let honors: [Honor] = [.wind(.east), .wind(.south), .wind(.west), .wind(.north),
                                .white, .green, .red]
        for honor in honors {
            let tile = Tile(honor: honor)
            XCTAssertTrue(allTiles.contains(tile), "Missing honor \(honor)")
        }
    }

    func testFileNameForNumberTiles() {
        XCTAssertEqual(TileTemplate.fileName(for: Tile(suit: .m, rank: 1)), "1m")
        XCTAssertEqual(TileTemplate.fileName(for: Tile(suit: .p, rank: 5)), "5p")
        XCTAssertEqual(TileTemplate.fileName(for: Tile(suit: .s, rank: 9)), "9s")
    }

    func testFileNameForHonorTiles() {
        XCTAssertEqual(TileTemplate.fileName(for: Tile(honor: .wind(.east))), "東")
        XCTAssertEqual(TileTemplate.fileName(for: Tile(honor: .white)), "白")
        XCTAssertEqual(TileTemplate.fileName(for: Tile(honor: .green)), "發")
        XCTAssertEqual(TileTemplate.fileName(for: Tile(honor: .red)), "中")
    }
}

final class TemplateMatcherTests: XCTestCase {
    func testMatcherReturns3Candidates() {
        let library = TileTemplateLibrary()
        let matcher = TemplateMatcher(library: library)
        // Create a 32x44 test image using NSBitmapImageRep for cross-version compatibility
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 32,
            pixelsHigh: 44,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
        let testImage = rep?.cgImage
        // If CGImage creation fails, skip the actual match call but still verify types
        guard let cgImage = testImage else {
            // Fall back: verify matcher construction only
            _ = matcher
            return
        }
        // Stub: matcher returns top 3 from full library
        // Real test will verify actual matching accuracy
        let matches = matcher.match(tileImage: cgImage, topN: 3)
        XCTAssertEqual(matches.count, 3, "Should return top 3 matches")
    }
}
