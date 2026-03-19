import Photos
import UIKit

final class PhotoLibraryService {
    struct Album: Equatable {
        let localIdentifier: String
        let title: String
        let isFavorite: Bool
    }

    private let imageManager = PHCachingImageManager()

    static func hasAllowedPhotoAccess(_ status: PHAuthorizationStatus) -> Bool {
        status == .authorized || status == .limited
    }

    func authorizationStatus() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization(completion: @escaping (PHAuthorizationStatus) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                completion(status)
            }
        }
    }

    func fetchAssets() -> PHFetchResult<PHAsset> {
        PHAsset.fetchAssets(with: assetFetchOptions())
    }

    func fetchAssets(inAlbumWithIdentifier identifier: String) -> PHFetchResult<PHAsset> {
        guard let collection = fetchAssetCollection(withLocalIdentifier: identifier) else {
            return PHAsset.fetchAssets(withLocalIdentifiers: [], options: nil)
        }

        return PHAsset.fetchAssets(in: collection, options: assetFetchOptions())
    }

    func fetchPinnedAlbums(withLocalIdentifiers identifiers: [String]) -> [Album] {
        identifiers.compactMap(fetchAlbum(withLocalIdentifier:))
    }

    func fetchAddableAlbums(excluding excludedIdentifiers: Set<String> = []) -> [Album] {
        var albumsByIdentifier: [String: Album] = [:]

        appendAlbums(
            from: PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: nil),
            excluding: excludedIdentifiers,
            into: &albumsByIdentifier
        )
        appendAlbums(
            from: PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil),
            excluding: excludedIdentifiers,
            into: &albumsByIdentifier
        )

        return albumsByIdentifier.values.sorted { lhs, rhs in
            if lhs.isFavorite != rhs.isFavorite {
                return lhs.isFavorite && !rhs.isFavorite
            }

            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    @discardableResult
    func requestThumbnail(
        for asset: PHAsset,
        targetSize: CGSize,
        completion: @escaping (UIImage?) -> Void
    ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        return imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    @discardableResult
    func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        completion: @escaping (UIImage?) -> Void
    ) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true

        return imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    private func assetFetchOptions() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        return options
    }

    private func appendAlbums(
        from collections: PHFetchResult<PHAssetCollection>,
        excluding excludedIdentifiers: Set<String>,
        into albumsByIdentifier: inout [String: Album]
    ) {
        for index in 0..<collections.count {
            let collection = collections.object(at: index)
            guard !excludedIdentifiers.contains(collection.localIdentifier),
                  let album = self.makeAlbum(from: collection) else {
                continue
            }

            albumsByIdentifier[album.localIdentifier] = album
        }
    }

    private func fetchAlbum(withLocalIdentifier identifier: String) -> Album? {
        guard let collection = fetchAssetCollection(withLocalIdentifier: identifier) else { return nil }
        return makeAlbum(from: collection)
    }

    private func fetchAssetCollection(withLocalIdentifier identifier: String) -> PHAssetCollection? {
        PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [identifier], options: nil).firstObject
    }

    private func makeAlbum(from collection: PHAssetCollection) -> Album? {
        guard let rawTitle = collection.localizedTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawTitle.isEmpty else {
            return nil
        }

        let assetCount = PHAsset.fetchAssets(in: collection, options: assetFetchOptions()).count
        guard assetCount > 0 else { return nil }

        return Album(
            localIdentifier: collection.localIdentifier,
            title: rawTitle,
            isFavorite: collection.assetCollectionSubtype == .smartAlbumFavorites
        )
    }
}
