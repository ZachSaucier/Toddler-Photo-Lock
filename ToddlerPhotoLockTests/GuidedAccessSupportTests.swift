import Photos
import XCTest
@testable import ToddlerPhotoLock

final class GuidedAccessSupportTests: XCTestCase {
    func testPinnedAlbumIdentifiersPersistAsUniqueOrderedValues() {
        let suiteName = "GuidedAccessSupportTests.pinnedAlbums"
        let userDefaults = try! XCTUnwrap(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        AppPreferences.setPinnedAlbumIdentifiers([" favorites ", "album-1", "favorites", "", "album-1"], in: userDefaults)

        XCTAssertEqual(AppPreferences.pinnedAlbumIdentifiers(in: userDefaults), ["favorites", "album-1"])
    }

    func testDismissBuyMeACoffeePersistsHiddenState() {
        let suiteName = "GuidedAccessSupportTests.buyMeACoffee"
        let userDefaults = try! XCTUnwrap(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        XCTAssertFalse(GuidedAccessSupport.isBuyMeACoffeeDismissed(in: userDefaults))

        GuidedAccessSupport.dismissBuyMeACoffee(in: userDefaults)

        XCTAssertTrue(GuidedAccessSupport.isBuyMeACoffeeDismissed(in: userDefaults))
    }

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