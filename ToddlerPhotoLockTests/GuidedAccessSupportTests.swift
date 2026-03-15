import Photos
import XCTest
@testable import ToddlerPhotoLock

final class GuidedAccessSupportTests: XCTestCase {
    func testPresentsEducationWhenLibraryAccessIsNewAndGuidedAccessIsOff() {
        XCTAssertTrue(
            GuidedAccessSupport.shouldPresentEducation(
                previousStatus: .notDetermined,
                currentStatus: .authorized,
                isGuidedAccessEnabled: false
            )
        )
        XCTAssertTrue(
            GuidedAccessSupport.shouldPresentEducation(
                previousStatus: .denied,
                currentStatus: .limited,
                isGuidedAccessEnabled: false
            )
        )
    }

    func testDoesNotPresentEducationWhenGuidedAccessIsAlreadyEnabled() {
        XCTAssertFalse(
            GuidedAccessSupport.shouldPresentEducation(
                previousStatus: .notDetermined,
                currentStatus: .authorized,
                isGuidedAccessEnabled: true
            )
        )
    }

    func testDoesNotPresentEducationWhenLibraryAccessWasAlreadyAvailable() {
        XCTAssertFalse(
            GuidedAccessSupport.shouldPresentEducation(
                previousStatus: .limited,
                currentStatus: .authorized,
                isGuidedAccessEnabled: false
            )
        )
    }

    func testGuidedAccessSettingsURLsIncludeSupportFallback() {
        let urls = GuidedAccessSupport.guidedAccessSettingsURLs.map(\.absoluteString)

        XCTAssertEqual(urls.last, "https://support.apple.com/111795")
        XCTAssertTrue(urls.contains("prefs:root=ACCESSIBILITY&path=GUIDED_ACCESS_TITLE"))
    }
}