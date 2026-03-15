import Photos

enum GalleryContentSource: Equatable {
    case none
    case photoLibrary
    case pickedImages
}

struct GalleryPresentationModel {
    let contentSource: GalleryContentSource
    let message: String?
    let actionTitle: String?
    let navigationActionTitle: String?

    var showsCollectionView: Bool {
        contentSource != .none
    }

    static func make(status: PHAuthorizationStatus, libraryAssetCount: Int, pickedImageCount: Int) -> GalleryPresentationModel {
        if pickedImageCount > 0, [.notDetermined, .denied, .restricted].contains(status) {
            return GalleryPresentationModel(
                contentSource: .pickedImages,
                message: nil,
                actionTitle: nil,
                navigationActionTitle: "Choose More"
            )
        }

        switch status {
        case .authorized, .limited:
            if libraryAssetCount > 0 {
                return GalleryPresentationModel(
                    contentSource: .photoLibrary,
                    message: nil,
                    actionTitle: nil,
                    navigationActionTitle: status == .limited ? "Add Photos" : nil
                )
            }

            if status == .limited {
                return GalleryPresentationModel(
                    contentSource: .none,
                    message: "No shared photos yet. Tap Add Photos to expand your limited selection.",
                    actionTitle: "Add Photos",
                    navigationActionTitle: "Add Photos"
                )
            }

            return GalleryPresentationModel(
                contentSource: .none,
                message: "No images were found in your photo library.",
                actionTitle: nil,
                navigationActionTitle: nil
            )

        case .notDetermined:
            return GalleryPresentationModel(
                contentSource: .none,
                message: "Choose how to share photos with Toddler Photo Lock. You can grant full library access or just pick specific photos.",
                actionTitle: "Choose Photos",
                navigationActionTitle: nil
            )

        case .denied:
            return GalleryPresentationModel(
                contentSource: .none,
                message: "Full library access is off. You can still choose specific photos here, or open Settings if you want the whole camera roll.",
                actionTitle: "Choose Photos",
                navigationActionTitle: nil
            )

        case .restricted:
            return GalleryPresentationModel(
                contentSource: .none,
                message: "Photo access is restricted on this device. If iOS allows it, you can still try choosing specific photos.",
                actionTitle: "Choose Photos",
                navigationActionTitle: nil
            )

        @unknown default:
            return GalleryPresentationModel(
                contentSource: .none,
                message: "An unknown photo authorization state was encountered.",
                actionTitle: nil,
                navigationActionTitle: nil
            )
        }
    }
}