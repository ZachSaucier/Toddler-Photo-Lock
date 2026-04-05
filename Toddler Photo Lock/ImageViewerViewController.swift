import Photos
import UIKit

private final class PaddedLabel: UILabel {
    private let textInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + textInsets.left + textInsets.right,
                      height: size.height + textInsets.top + textInsets.bottom)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let insetSize = CGSize(
            width: max(0, size.width - textInsets.left - textInsets.right),
            height: max(0, size.height - textInsets.top - textInsets.bottom)
        )
        let fittingSize = super.sizeThatFits(insetSize)
        return CGSize(width: fittingSize.width + textInsets.left + textInsets.right,
                      height: fittingSize.height + textInsets.top + textInsets.bottom)
    }
}

final class ImageViewerViewController: UIViewController, UIScrollViewDelegate {
    private enum Source {
        case asset(PHAsset, PhotoLibraryService)
        case image(UIImage)
    }

    private let source: Source
    private var didRequestImage = false
    private var isLocked = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
            setNeedsUpdateOfHomeIndicatorAutoHidden()
        }
    }

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .black
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.maximumZoomScale = 4
        scrollView.minimumZoomScale = 1
        return scrollView
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        return indicator
    }()

    private lazy var closeButton = makeOverlayButton(systemName: "xmark")

    private let guidedAccessBanner: PaddedLabel = {
        let label = PaddedLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.backgroundColor = UIColor(white: 0, alpha: 0.72)
        label.layer.cornerRadius = 16
        label.layer.masksToBounds = true
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "Start Guided Access with a triple-click of the side button. Toddler Photo Lock will lock automatically."
        return label
    }()

    init(asset: PHAsset, photoLibraryService: PhotoLibraryService) {
        source = .asset(asset, photoLibraryService)
        super.init(nibName: nil, bundle: nil)
    }

    init(image: UIImage) {
        source = .image(image)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        scrollView.delegate = self
        scrollView.addSubview(imageView)

        view.addSubview(scrollView)
        view.addSubview(activityIndicator)
        view.addSubview(closeButton)
        view.addSubview(guidedAccessBanner)

        setUpConstraints()
        setUpActions()
        setUpObservers()

        activityIndicator.startAnimating()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateGuidedAccessState(animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didRequestImage, scrollView.bounds.width > 0, scrollView.bounds.height > 0 {
            didRequestImage = true
            loadImage()
        } else {
            centerImage()
        }
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        isLocked
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }

    private func setUpConstraints() {
        [closeButton].forEach { button in
            button.widthAnchor.constraint(equalToConstant: 52).isActive = true
            button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            guidedAccessBanner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guidedAccessBanner.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            guidedAccessBanner.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            guidedAccessBanner.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func setUpActions() {
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
    }

    private func setUpObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGuidedAccessStatusChanged),
            name: UIAccessibility.guidedAccessStatusDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGuidedAccessStatusChanged),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    private func makeOverlayButton(systemName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .white
        button.backgroundColor = UIColor(white: 0, alpha: 0.6)
        button.layer.cornerRadius = 26
        button.setImage(UIImage(systemName: systemName), for: .normal)
        return button
    }

    private func loadImage() {
        switch source {
        case let .asset(asset, photoLibraryService):
            let maxDimension: CGFloat = 4096
            let maxPixelDimension = CGFloat(max(asset.pixelWidth, asset.pixelHeight))
            let scale = min(1, maxDimension / maxPixelDimension)
            let targetSize = CGSize(
                width: CGFloat(asset.pixelWidth) * scale,
                height: CGFloat(asset.pixelHeight) * scale
            )

            photoLibraryService.requestImage(for: asset, targetSize: targetSize) { [weak self] image in
                guard let self, let image else { return }
                self.activityIndicator.stopAnimating()
                self.display(image: image)
            }

        case let .image(image):
            activityIndicator.stopAnimating()
            display(image: image)
        }
    }

    private func display(image: UIImage) {
        imageView.image = image
        let fittedSize = ImageViewportLayout.fittedSize(for: image.size, in: scrollView.bounds.size)
        imageView.frame = CGRect(origin: .zero, size: fittedSize)
        scrollView.zoomScale = 1
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.contentSize = fittedSize
        centerImage()
        updateGuidedAccessState(animated: false)
    }

    private func centerImage() {
        let insets = ImageViewportLayout.centeredInsets(contentSize: imageView.frame.size, in: scrollView.bounds.size)
        scrollView.contentInset = insets
    }

    private func lockCurrentState() {
        guard !isLocked else { return }

        isLocked = true
        let currentZoom = max(scrollView.zoomScale, 1)
        scrollView.minimumZoomScale = currentZoom
        scrollView.maximumZoomScale = currentZoom
        scrollView.isScrollEnabled = false
        scrollView.pinchGestureRecognizer?.isEnabled = false
        UIApplication.shared.isIdleTimerDisabled = true

        UIView.animate(withDuration: 0.25) {
            self.closeButton.alpha = 0
            self.guidedAccessBanner.alpha = 0
        }
    }

    private func unlockCurrentState() {
        guard isLocked else { return }

        isLocked = false
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.isScrollEnabled = true
        scrollView.pinchGestureRecognizer?.isEnabled = true
        UIApplication.shared.isIdleTimerDisabled = false

        UIView.animate(withDuration: 0.25) {
            self.closeButton.alpha = 1
            self.guidedAccessBanner.alpha = 1
        }
    }

    private func updateGuidedAccessState(animated: Bool) {
        let updateBlock = {
            if UIAccessibility.isGuidedAccessEnabled {
                self.lockCurrentState()
            } else {
                self.unlockCurrentState()
            }
        }

        if animated {
            updateBlock()
        } else {
            UIView.performWithoutAnimation(updateBlock)
        }
    }

    @objc private func handleClose() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleGuidedAccessStatusChanged() {
        updateGuidedAccessState(animated: true)
    }
}
