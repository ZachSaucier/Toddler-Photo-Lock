import XCTest
@testable import ToddlerPhotoLock

final class ImageViewportLayoutTests: XCTestCase {
    func testFittedSizePreservesAspectRatioWithinViewport() {
        let fittedSize = ImageViewportLayout.fittedSize(
            for: CGSize(width: 4000, height: 3000),
            in: CGSize(width: 300, height: 500)
        )

        XCTAssertEqual(fittedSize.width, 300, accuracy: 0.001)
        XCTAssertEqual(fittedSize.height, 225, accuracy: 0.001)
    }

    func testCenteredInsetsBalanceAvailableSpace() {
        let insets = ImageViewportLayout.centeredInsets(
            contentSize: CGSize(width: 300, height: 225),
            in: CGSize(width: 300, height: 500)
        )

        XCTAssertEqual(insets.top, 137.5, accuracy: 0.001)
        XCTAssertEqual(insets.bottom, 137.5, accuracy: 0.001)
        XCTAssertEqual(insets.left, 0, accuracy: 0.001)
        XCTAssertEqual(insets.right, 0, accuracy: 0.001)
    }

    func testCenteredInsetsClampToZeroWhenContentOverflows() {
        let insets = ImageViewportLayout.centeredInsets(
            contentSize: CGSize(width: 500, height: 800),
            in: CGSize(width: 300, height: 600)
        )

        XCTAssertEqual(insets.top, 0, accuracy: 0.001)
        XCTAssertEqual(insets.bottom, 0, accuracy: 0.001)
        XCTAssertEqual(insets.left, 0, accuracy: 0.001)
        XCTAssertEqual(insets.right, 0, accuracy: 0.001)
    }
}