import UIKit

final class HelpViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let tipJarViewController = TipJarViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Help"
        view.backgroundColor = .black
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(handleClose))
        setUpHierarchy()
    }

    private func setUpHierarchy() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 18

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24)
        ])

        // Help section
        contentStack.addArrangedSubview(makeSectionTitleLabel(text: "Help"))
        contentStack.addArrangedSubview(makeLinkButton(title: "• Privacy Policy", imageName: "chevron.right", action: #selector(handlePrivacyPolicy)))
        contentStack.addArrangedSubview(makeLinkButton(title: "• FAQ", imageName: "arrow.up.right", action: #selector(handleFAQ)))
        contentStack.addArrangedSubview(makeLinkButton(title: "• Report an issue", imageName: "arrow.up.right", action: #selector(handleReportIssue)))
        contentStack.addArrangedSubview(makeLinkButton(title: "• Email support", imageName: "envelope.fill", action: #selector(handleEmailSupport)))
        contentStack.setCustomSpacing(30, after: contentStack.arrangedSubviews.last!)

        // Donate section
        contentStack.addArrangedSubview(makeSectionTitleLabel(text: "Donate"))
        contentStack.addArrangedSubview(makeBodyLabel(text: AppSupportContent.donateMessage))

        // Tip jar — embedded as a child view controller so it can present alerts
        addChild(tipJarViewController)
        contentStack.addArrangedSubview(tipJarViewController.view)
        tipJarViewController.didMove(toParent: self)
    }

    // MARK: - View factories

    private func makeSectionTitleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .title2)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }

    private func makeBodyLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor(white: 0.86, alpha: 1)
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }

    private func makeLinkButton(title: String, imageName: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.baseForegroundColor = .white
        configuration.image = UIImage(systemName: imageName)
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 8
        configuration.contentInsets = .zero

        let button = UIButton(configuration: configuration)
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func open(_ url: URL) {
        UIApplication.shared.open(url)
    }

    // MARK: - Actions

    @objc private func handleClose() {
        dismiss(animated: true)
    }

    @objc private func handlePrivacyPolicy() {
        navigationController?.pushViewController(PrivacyPolicyViewController(), animated: true)
    }

    @objc private func handleFAQ() {
        open(AppSupportContent.faqURL)
    }

    @objc private func handleReportIssue() {
        open(AppSupportContent.issuesURL)
    }

    @objc private func handleEmailSupport() {
        open(AppSupportContent.supportEmailURL)
    }
}