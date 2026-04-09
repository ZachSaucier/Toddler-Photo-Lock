import Photos
import UIKit

enum AppPreferences {
    static let pinnedAlbumIdentifiersKey = "ToddlerPhotoLock.pinnedAlbumIdentifiers"

    static func pinnedAlbumIdentifiers(in userDefaults: UserDefaults = .standard) -> [String] {
        let identifiers = userDefaults.array(forKey: pinnedAlbumIdentifiersKey) as? [String] ?? []
        return normalizedIdentifiers(identifiers)
    }

    static func setPinnedAlbumIdentifiers(_ identifiers: [String], in userDefaults: UserDefaults = .standard) {
        userDefaults.set(normalizedIdentifiers(identifiers), forKey: pinnedAlbumIdentifiersKey)
    }

    static func normalizedIdentifiers(_ identifiers: [String]) -> [String] {
        var seen: Set<String> = []

        return identifiers.compactMap { identifier in
            let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed).inserted else { return nil }
            return trimmed
        }
    }
}

enum GuidedAccessSupport {
    static func shouldPresentEducation(
        previousStatus: PHAuthorizationStatus,
        currentStatus: PHAuthorizationStatus,
        isGuidedAccessEnabled: Bool
    ) -> Bool {
        // iOS only exposes whether Guided Access is currently active, not whether the
        // user has already configured it for future use in Settings.
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