import Photos
import XCTest
@testable import ToddlerPhotoLock

final class PhotoLibraryServiceTests: XCTestCase {
    func testHasAllowedPhotoAccessForAuthorizedStatuses() {
        XCTAssertTrue(PhotoLibraryService.hasAllowedPhotoAccess(.authorized))
        XCTAssertTrue(PhotoLibraryService.hasAllowedPhotoAccess(.limited))
    }

    func testHasAllowedPhotoAccessIsFalseWithoutLibraryAccess() {
        XCTAssertFalse(PhotoLibraryService.hasAllowedPhotoAccess(.notDetermined))
        XCTAssertFalse(PhotoLibraryService.hasAllowedPhotoAccess(.denied))
        XCTAssertFalse(PhotoLibraryService.hasAllowedPhotoAccess(.restricted))
    }
}