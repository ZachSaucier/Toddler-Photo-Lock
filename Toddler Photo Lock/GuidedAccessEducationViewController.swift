import UIKit

final class GuidedAccessEducationViewController: UIViewController {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(white: 0.92, alpha: 1)
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let stepsLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private lazy var primaryButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = .white
        configuration.baseForegroundColor = .black
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handlePrimaryAction), for: .touchUpInside)
        return button
    }()

    private lazy var secondaryButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = .white
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel, stepsLabel, primaryButton, secondaryButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 18
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualTo: stackView.bottomAnchor, constant: 40)
        ])

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleApplicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        refreshContent()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleApplicationDidBecomeActive() {
        refreshContent()
    }

    private func refreshContent() {
        if UIAccessibility.isGuidedAccessEnabled {
            titleLabel.text = "Guided Access is on"
            bodyLabel.text = "Toddler Photo Lock works best when Guided Access keeps your child inside the photo and blocks accidental app switching or swipes."
            stepsLabel.text = "You’re ready to open a photo. Toddler Photo Lock will lock automatically while Guided Access is active."
            primaryButton.setTitle("Continue", for: .normal)
            secondaryButton.setTitle("Close", for: .normal)
        } else {
            titleLabel.text = "Use Guided Access before handing over your phone"
            bodyLabel.text = "Toddler Photo Lock works best with Guided Access. If you already turned it on in Settings, you’re all set — just start Guided Access after opening a photo. If you have not set it up yet, you can do that now."
            stepsLabel.text = "To set it up:\n1. Open Settings.\n2. Tap Accessibility.\n3. Tap Guided Access.\n4. Turn it on and choose your passcode or Face ID.\n\nOnce it is configured, open a photo here and start Guided Access with your shortcut."
            primaryButton.setTitle("Open Guided Access settings", for: .normal)
            secondaryButton.setTitle("Not now", for: .normal)
        }
    }

    @objc private func handlePrimaryAction() {
        if UIAccessibility.isGuidedAccessEnabled {
            dismiss(animated: true)
        } else {
            GuidedAccessSupport.openGuidedAccessSettings()
        }
    }

    @objc private func handleDismiss() {
        dismiss(animated: true)
    }
}