import Photos
import UIKit

enum GuidedAccessSupport {
    static let buyMeACoffeeURL = URL(string: "https://buymeacoffee.com/zachsaucier")!
    static let buyMeACoffeeDismissedKey = "ToddlerPhotoLock.didTapBuyMeACoffee"

    static func shouldPresentEducation(
        previousStatus: PHAuthorizationStatus,
        currentStatus: PHAuthorizationStatus,
        isGuidedAccessEnabled: Bool
    ) -> Bool {
        let hadLibraryAccess = previousStatus == .authorized || previousStatus == .limited
        let hasLibraryAccess = currentStatus == .authorized || currentStatus == .limited
        return !hadLibraryAccess && hasLibraryAccess && !isGuidedAccessEnabled
    }

    static var guidedAccessSettingsURLs: [URL] {
        [
            "App-Prefs:root=ACCESSIBILITY&path=GUIDED_ACCESS_TITLE",
            "prefs:root=ACCESSIBILITY&path=GUIDED_ACCESS_TITLE",
            "https://support.apple.com/111795"
        ].compactMap(URL.init(string:))
    }

    static func openGuidedAccessSettings(using application: UIApplication = .shared) {
        openFirstAvailableURL(in: guidedAccessSettingsURLs, using: application)
    }

    private static func openFirstAvailableURL(in urls: [URL], using application: UIApplication) {
        guard let url = urls.first else { return }

        application.open(url, options: [:]) { success in
            guard !success else { return }
            openFirstAvailableURL(in: Array(urls.dropFirst()), using: application)
        }
    }
}