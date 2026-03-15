import XCTest
@testable import ToddlerPhotoLock

final class OrderedUniqueMergerTests: XCTestCase {
    private struct Item: Equatable {
        let id: String
        let value: String
    }

    func testMergePreservesExistingOrderAndAppendsNewItems() {
        let existing = [Item(id: "a", value: "first"), Item(id: "b", value: "second")]
        let incoming = [Item(id: "c", value: "third"), Item(id: "d", value: "fourth")]

        let merged = OrderedUniqueMerger.merge(existing: existing, incoming: incoming) { $0.id }

        XCTAssertEqual(merged, existing + incoming)
    }

    func testMergeUpdatesDuplicateItemsWithoutDroppingExistingOnes() {
        let existing = [Item(id: "a", value: "old-a"), Item(id: "b", value: "old-b")]
        let incoming = [Item(id: "b", value: "new-b"), Item(id: "c", value: "new-c")]

        let merged = OrderedUniqueMerger.merge(existing: existing, incoming: incoming) { $0.id }

        XCTAssertEqual(
            merged,
            [
                Item(id: "a", value: "old-a"),
                Item(id: "b", value: "new-b"),
                Item(id: "c", value: "new-c")
            ]
        )
    }
}