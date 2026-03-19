import Photos
import XCTest
@testable import ToddlerPhotoLock

final class GalleryPresentationModelTests: XCTestCase {
    func testNotDeterminedPromptsForPhotoChoice() {
        let model = GalleryPresentationModel.make(status: .notDetermined, libraryAssetCount: 0, pickedImageCount: 0)

        XCTAssertEqual(model.contentSource, .none)
        XCTAssertEqual(model.actionTitle, "Choose photos")
        XCTAssertNil(model.navigationActionTitle)
    }

    func testDeniedWithPickedImagesShowsPickedGallery() {
        let model = GalleryPresentationModel.make(status: .denied, libraryAssetCount: 0, pickedImageCount: 2)

        XCTAssertEqual(model.contentSource, .pickedImages)
        XCTAssertNil(model.actionTitle)
        XCTAssertEqual(model.navigationActionTitle, "Choose more")
    }

    func testLimitedWithoutAssetsKeepsAddPhotosActionsVisible() {
        let model = GalleryPresentationModel.make(status: .limited, libraryAssetCount: 0, pickedImageCount: 0)

        XCTAssertEqual(model.contentSource, .none)
        XCTAssertEqual(model.actionTitle, "Add photos")
        XCTAssertEqual(model.navigationActionTitle, "Add photos")
    }

    func testAuthorizedAssetsShowPhotoLibraryContent() {
        let model = GalleryPresentationModel.make(status: .authorized, libraryAssetCount: 3, pickedImageCount: 0)

        XCTAssertEqual(model.contentSource, .photoLibrary)
        XCTAssertNil(model.actionTitle)
        XCTAssertNil(model.navigationActionTitle)
    }
}