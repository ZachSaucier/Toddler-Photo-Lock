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
                navigationActionTitle: "Choose more"
            )
        }

        switch status {
        case .authorized, .limited:
            if libraryAssetCount > 0 {
                return GalleryPresentationModel(
                    contentSource: .photoLibrary,
                    message: nil,
                    actionTitle: nil,
                    navigationActionTitle: status == .limited ? "Add photos" : nil
                )
            }

            if status == .limited {
                return GalleryPresentationModel(
                    contentSource: .none,
                    message: "No shared photos yet. Tap Add photos to expand your limited selection.",
                    actionTitle: "Add photos",
                    navigationActionTitle: "Add photos"
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
                message: "Choose how to share photos with Toddler Photo Lock by selecting specific photos.",
                actionTitle: "Choose photos",
                navigationActionTitle: nil
            )

        case .denied:
            return GalleryPresentationModel(
                contentSource: .none,
                message: "",
                actionTitle: "Choose photos",
                navigationActionTitle: nil
            )

        case .restricted:
            return GalleryPresentationModel(
                contentSource: .none,
                message: "Photo access is restricted on this device. If iOS allows it, you can still try choosing specific photos.",
                actionTitle: "Choose photos",
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