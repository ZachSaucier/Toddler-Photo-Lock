import UIKit

/// A navigation controller that delegates orientation support to its top view controller.
/// This allows individual view controllers to lock or unlock rotation independently.
final class OrientationAwareNavigationController: UINavigationController {
    override var shouldAutorotate: Bool {
        topViewController?.shouldAutorotate ?? super.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        topViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }
}
