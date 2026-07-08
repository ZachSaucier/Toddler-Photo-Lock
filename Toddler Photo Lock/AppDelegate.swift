import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureAppearance()
        setUpGuidedAccessStartDetection()
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        application.isIdleTimerDisabled = false
    }

    private func configureAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = .black
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = .white
    }

    private func setUpGuidedAccessStartDetection() {
        recordGuidedAccessStartIfNeeded()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recordGuidedAccessStartIfNeeded),
            name: UIAccessibility.guidedAccessStatusDidChangeNotification,
            object: nil
        )
    }

    @objc private func recordGuidedAccessStartIfNeeded() {
        AppPreferences.recordGuidedAccessStartIfNeeded(
            isGuidedAccessEnabled: UIAccessibility.isGuidedAccessEnabled
        )
    }
}
