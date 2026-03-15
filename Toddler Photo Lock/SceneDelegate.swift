import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let photoLibraryService = PhotoLibraryService()

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = makeInitialRootViewController()
        window.backgroundColor = .black
        window.makeKeyAndVisible()

        self.window = window
    }

    private func makeInitialRootViewController() -> UIViewController {
        let status = photoLibraryService.authorizationStatus()
        if PhotoLibraryService.hasAllowedPhotoAccess(status) {
            return makeGalleryNavigationController()
        }

        return PhotoAccessIntroViewController { [weak self] in
            self?.showGallery(promptForPhotoAccess: true, animated: true)
        }
    }

    private func makeGalleryNavigationController(promptForPhotoAccess: Bool = false) -> UINavigationController {
        let navigationController = UINavigationController(
            rootViewController: GalleryViewController(
                shouldPresentPhotoAccessOptionsOnFirstAppearance: promptForPhotoAccess
            )
        )
        navigationController.view.backgroundColor = .black
        return navigationController
    }

    private func showGallery(promptForPhotoAccess: Bool, animated: Bool) {
        guard let window else { return }
        let galleryNavigationController = makeGalleryNavigationController(
            promptForPhotoAccess: promptForPhotoAccess
        )

        guard animated else {
            window.rootViewController = galleryNavigationController
            return
        }

        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) {
            window.rootViewController = galleryNavigationController
        }
    }
}
