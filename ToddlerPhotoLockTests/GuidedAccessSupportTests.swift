import Photos
import UIKit
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

    @MainActor
    func testOpenGuidedAccessSettingsButtonPresentsParentalGateFirst() throws {
        var didPresentGate = false
        var didOpenSettings = false
        var onGateSuccess: (() -> Void)?

        let viewController = GuidedAccessEducationViewController(
            isGuidedAccessEnabled: { false },
            openGuidedAccessSettings: { didOpenSettings = true },
            presentParentalGate: { _, onSuccess in
                didPresentGate = true
                onGateSuccess = onSuccess
            }
        )

        viewController.loadViewIfNeeded()

        let button = try XCTUnwrap(
            viewController.view.allSubviews()
                .compactMap { $0 as? UIButton }
                .first { $0.currentTitle == "Open Guided Access settings" }
        )

        button.sendActions(for: .touchUpInside)

        XCTAssertTrue(didPresentGate)
        XCTAssertFalse(didOpenSettings)

        onGateSuccess?()

        XCTAssertTrue(didOpenSettings)
    }
}

private extension UIView {
    func allSubviews() -> [UIView] {
        [self] + subviews.flatMap { $0.allSubviews() }
    }
}