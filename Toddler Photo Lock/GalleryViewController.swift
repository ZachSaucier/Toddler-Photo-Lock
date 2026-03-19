import Photos
import PhotosUI
import UIKit

final class GalleryViewController: UIViewController {
    private let photoLibraryService = PhotoLibraryService()
    private var photoLibraryAssets = PHAsset.fetchAssets(with: PHFetchOptions())
    private var pickedImages: [PickedImage] = []
    private var lastAuthorizationStatus: PHAuthorizationStatus?
    private var shouldPresentGuidedAccessEducation = false
    private var shouldRequestPhotoAuthorizationOnFirstAppearance: Bool
    private var presentationModel = GalleryPresentationModel.make(
        status: .notDetermined,
        libraryAssetCount: 0,
        pickedImageCount: 0
    )

    init(shouldRequestPhotoAuthorizationOnFirstAppearance: Bool = false) {
        self.shouldRequestPhotoAuthorizationOnFirstAppearance = shouldRequestPhotoAuthorizationOnFirstAppearance
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var navigationActionButton = UIBarButtonItem(
        title: "",
        style: .plain,
        target: self,
        action: #selector(handlePrimaryAction)
    )

    private struct PickedImage {
        let identifier: String
        let assetIdentifier: String?
        let image: UIImage
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ThumbnailCell.self, forCellWithReuseIdentifier: ThumbnailCell.reuseIdentifier)
        return collectionView
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var actionButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = .white
        configuration.baseForegroundColor = .black
        configuration.cornerStyle = .capsule

        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handlePrimaryAction), for: .touchUpInside)
        return button
    }()

    private lazy var buyMeACoffeeButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = UIColor(red: 0.98, green: 0.83, blue: 0.26, alpha: 1)
        configuration.baseForegroundColor = .black
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        configuration.title = "Buy me a coffee"
        configuration.image = UIImage(systemName: "cup.and.saucer.fill")
        configuration.imagePadding = 6
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            return outgoing
        }

        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleBuyMeACoffee), for: .touchUpInside)
        return button
    }()

    private lazy var helpButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = UIColor(white: 0.16, alpha: 1)
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        configuration.title = "?"
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 20, weight: .bold)
            return outgoing
        }

        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "Help"
        button.addTarget(self, action: #selector(handleHelp), for: .touchUpInside)
        return button
    }()

    private lazy var stateStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [messageLabel, actionButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Toddler Photo Lock"
        view.backgroundColor = .black

        PHPhotoLibrary.shared().register(self)
        setUpHierarchy()
        refreshContent()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshContent()
        requestPhotoAuthorizationIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionLayout()
        updateBottomAccessoryInsets()
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    private func setUpHierarchy() {
        view.addSubview(collectionView)
        view.addSubview(stateStack)
        view.addSubview(buyMeACoffeeButton)
        view.addSubview(helpButton)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stateStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stateStack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stateStack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

            actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 160),

            helpButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            helpButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            buyMeACoffeeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            buyMeACoffeeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func refreshContent() {
        let status = photoLibraryService.authorizationStatus()
        let previousStatus = lastAuthorizationStatus ?? status
        let isGuidedAccessEnabled = UIAccessibility.isGuidedAccessEnabled

        if PhotoLibraryService.hasAllowedPhotoAccess(status) {
            photoLibraryAssets = fetchAssetsForCurrentSelection()
        } else {
            photoLibraryAssets = PHAsset.fetchAssets(withLocalIdentifiers: [], options: nil)
        }

        if GuidedAccessSupport.shouldPresentEducation(
            previousStatus: previousStatus,
            currentStatus: status,
            isGuidedAccessEnabled: isGuidedAccessEnabled
        ) {
            shouldPresentGuidedAccessEducation = true
        } else if isGuidedAccessEnabled {
            shouldPresentGuidedAccessEducation = false
        }
        lastAuthorizationStatus = status

        presentationModel = GalleryPresentationModel.make(
            status: status,
            libraryAssetCount: photoLibraryAssets.count,
            pickedImageCount: pickedImages.count
        )

        if let title = presentationModel.navigationActionTitle {
            navigationActionButton.title = title
            navigationItem.rightBarButtonItem = navigationActionButton
        } else {
            navigationItem.rightBarButtonItem = nil
        }

        collectionView.isHidden = !presentationModel.showsCollectionView
        stateStack.isHidden = presentationModel.showsCollectionView
        messageLabel.text = presentationModel.message

        if let actionTitle = presentationModel.actionTitle {
            actionButton.setTitle(actionTitle, for: .normal)
            actionButton.isHidden = false
        } else {
            actionButton.isHidden = true
        }

        collectionView.reloadData()
        refreshBuyMeACoffeeButton()
        presentGuidedAccessEducationIfNeeded()
    }

    private func fetchAssetsForCurrentSelection() -> PHFetchResult<PHAsset> {
        return photoLibraryService.fetchAssets()
    }

    private func requestAccess() {
        photoLibraryService.requestAuthorization { [weak self] _ in
            self?.refreshContent()
        }
    }

    private func presentPhotoAccessOptions() {
        let status = photoLibraryService.authorizationStatus()
        let alert: UIAlertController

        switch status {
        case .notDetermined:
            alert = UIAlertController(
                title: "Choose specific photos",
                message: "Select specific photos for Toddler Photo Lock.",
                preferredStyle: .actionSheet
            )
            alert.addAction(UIAlertAction(title: "Choose specific photos", style: .default) { [weak self] _ in
                self?.presentSpecificPhotoPicker()
            })

        case .denied:
            alert = UIAlertController(
                title: "Choose how to continue",
                message: "You can pick specific photos right now.",
                preferredStyle: .actionSheet
            )
            alert.addAction(UIAlertAction(title: "Choose specific photos", style: .default) { [weak self] _ in
                self?.presentSpecificPhotoPicker()
            })

        case .restricted:
            alert = UIAlertController(
                title: "Choose specific photos",
                message: "You can still select specific photos for Toddler Photo Lock.",
                preferredStyle: .actionSheet
            )
            alert.addAction(UIAlertAction(title: "Choose specific photos", style: .default) { [weak self] _ in
                self?.presentSpecificPhotoPicker()
            })

        default:
            return
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
            popover.sourceView = actionButton
            popover.sourceRect = actionButton.bounds
        }
        present(alert, animated: true)
    }

    private func presentSpecificPhotoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        configuration.filter = .images
        configuration.selectionLimit = 0
        configuration.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func loadPickedImages(from results: [PHPickerResult]) {
        guard !results.isEmpty else {
            refreshContent()
            return
        }

        collectionView.isHidden = true
        stateStack.isHidden = false
        messageLabel.text = "Loading selected photos…"
        actionButton.isHidden = true

        let lock = NSLock()
        let group = DispatchGroup()
        var loadedImages: [(Int, PickedImage)] = []

        for (index, result) in results.enumerated() where result.itemProvider.canLoadObject(ofClass: UIImage.self) {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                defer { group.leave() }
                guard let image = object as? UIImage else { return }

                let pickedImage = PickedImage(
                    identifier: result.assetIdentifier ?? UUID().uuidString,
                    assetIdentifier: result.assetIdentifier,
                    image: image.preparingForDisplay() ?? image
                )
                lock.lock()
                loadedImages.append((index, pickedImage))
                lock.unlock()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            let newImages = loadedImages.sorted { $0.0 < $1.0 }.map(\.1)
            self.pickedImages = OrderedUniqueMerger.merge(existing: self.pickedImages, incoming: newImages) {
                $0.identifier
            }
            self.refreshContent()
        }
    }

    private func updateCollectionLayout() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        let spacing: CGFloat = layout.minimumInteritemSpacing
        let columns: CGFloat = 3
        let totalSpacing = spacing * (columns - 1)
        let width = floor((view.bounds.width - totalSpacing) / columns)
        layout.itemSize = CGSize(width: width, height: width)
    }

    private func refreshBuyMeACoffeeButton() {
        let isHidden = GuidedAccessSupport.isBuyMeACoffeeDismissed()
        buyMeACoffeeButton.isHidden = isHidden
        updateBottomAccessoryInsets()
    }

    private func updateBottomAccessoryInsets() {
        let visibleButtonHeight = max(helpButton.bounds.height, buyMeACoffeeButton.isHidden ? 0 : buyMeACoffeeButton.bounds.height)
        let bottomInset: CGFloat = visibleButtonHeight > 0 ? visibleButtonHeight + 24 : 0
        collectionView.contentInset.bottom = bottomInset
        collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    private func presentHelp() {
        let helpViewController = HelpViewController()
        let navigationController = UINavigationController(rootViewController: helpViewController)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = .white
        navigationController.overrideUserInterfaceStyle = .dark

        present(navigationController, animated: true)
    }

    private func presentGuidedAccessEducationIfNeeded() {
        guard shouldPresentGuidedAccessEducation,
              presentedViewController == nil,
              viewIfLoaded?.window != nil else {
            return
        }

        guard !UIAccessibility.isGuidedAccessEnabled else {
            shouldPresentGuidedAccessEducation = false
            return
        }

        shouldPresentGuidedAccessEducation = false
        let educationViewController = GuidedAccessEducationViewController()
        educationViewController.modalPresentationStyle = .fullScreen
        present(educationViewController, animated: true)
    }

    private func requestPhotoAuthorizationIfNeeded() {
        guard shouldRequestPhotoAuthorizationOnFirstAppearance else { return }
        shouldRequestPhotoAuthorizationOnFirstAppearance = false

        let status = photoLibraryService.authorizationStatus()
        guard !PhotoLibraryService.hasAllowedPhotoAccess(status),
              presentedViewController == nil else {
            return
        }

        requestAccess()
    }

    @objc private func handlePrimaryAction() {
        if presentationModel.contentSource == .pickedImages {
            presentSpecificPhotoPicker()
            return
        }

        switch photoLibraryService.authorizationStatus() {
        case .notDetermined, .denied, .restricted:
            presentSpecificPhotoPicker()
        case .limited:
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
        case .authorized:
            // We respect existing authorization state but continue to operate with explicit selection intent.
            break
        @unknown default:
            break
        }
    }

    @objc private func handleBuyMeACoffee() {
        GuidedAccessSupport.dismissBuyMeACoffee()
        refreshBuyMeACoffeeButton()
        UIApplication.shared.open(GuidedAccessSupport.buyMeACoffeeURL)
    }

    @objc private func handleHelp() {
        presentHelp()
    }

}

extension GalleryViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch presentationModel.contentSource {
        case .photoLibrary:
            photoLibraryAssets.count
        case .pickedImages:
            pickedImages.count
        case .none:
            0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ThumbnailCell.reuseIdentifier,
            for: indexPath
        ) as? ThumbnailCell else {
            return UICollectionViewCell()
        }

        switch presentationModel.contentSource {
        case .photoLibrary:
            let asset = photoLibraryAssets.object(at: indexPath.item)
            cell.representedAssetIdentifier = asset.localIdentifier

            let scale = view.window?.screen.scale ?? UIScreen.main.scale
            let itemSize = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize ?? .zero
            let targetSize = CGSize(width: itemSize.width * scale, height: itemSize.height * scale)

            photoLibraryService.requestThumbnail(for: asset, targetSize: targetSize) { image in
                guard cell.representedAssetIdentifier == asset.localIdentifier else { return }
                cell.imageView.image = image
            }

        case .pickedImages:
            let image = pickedImages[indexPath.item]
            cell.representedAssetIdentifier = image.identifier
            cell.imageView.image = image.image

        case .none:
            cell.representedAssetIdentifier = nil
            cell.imageView.image = nil
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch presentationModel.contentSource {
        case .photoLibrary:
            let asset = photoLibraryAssets.object(at: indexPath.item)
            navigationController?.pushViewController(
                ImageViewerViewController(asset: asset, photoLibraryService: photoLibraryService),
                animated: true
            )

        case .pickedImages:
            let image = pickedImages[indexPath.item].image
            navigationController?.pushViewController(
                ImageViewerViewController(image: image),
                animated: true
            )

        case .none:
            break
        }
    }
}

extension GalleryViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in
            self?.refreshContent()
        }
    }
}

extension GalleryViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        loadPickedImages(from: results)
    }
}
