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
            titleLabel.text = "Guided Access Is Ready"
            bodyLabel.text = "Toddler Photo Lock works best when Guided Access keeps your child inside the photo and blocks accidental app switching or swipes."
            stepsLabel.text = "Guided Access is now on. Open a photo and Toddler Photo Lock will lock automatically."
            primaryButton.setTitle("Continue", for: .normal)
            secondaryButton.setTitle("Close", for: .normal)
        } else {
            titleLabel.text = "Turn On Guided Access"
            bodyLabel.text = "Guided Access is what makes Toddler Photo Lock safe to hand over. It keeps little hands from leaving the photo, changing your zoom, or moving into other apps."
            stepsLabel.text = "How to enable it:\n1. Open Settings.\n2. Tap Accessibility.\n3. Tap Guided Access.\n4. Turn it on and set a passcode."
            primaryButton.setTitle("Open Guided Access Settings", for: .normal)
            secondaryButton.setTitle("Not Now", for: .normal)
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