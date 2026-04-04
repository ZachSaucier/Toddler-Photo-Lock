import UIKit

final class HelpViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

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

        let helpTitle = makeSectionTitleLabel(text: "Help")
        let donateTitle = makeSectionTitleLabel(text: "Donate")
        let donateBody = makeBodyLabel(text: AppSupportContent.donateMessage)
        let donateButton = makeDonateButton()

        contentStack.addArrangedSubview(helpTitle)
        contentStack.addArrangedSubview(makeLinkButton(title: "• Privacy Policy", imageName: "chevron.right", action: #selector(handlePrivacyPolicy)))
        contentStack.addArrangedSubview(makeLinkButton(title: "• FAQ", imageName: "arrow.up.right", action: #selector(handleFAQ)))
        contentStack.addArrangedSubview(makeLinkButton(title: "• Report an issue", imageName: "arrow.up.right", action: #selector(handleReportIssue)))
        contentStack.addArrangedSubview(makeLinkButton(title: "• Email support", imageName: "envelope.fill", action: #selector(handleEmailSupport)))
        contentStack.setCustomSpacing(30, after: contentStack.arrangedSubviews.last!)
        contentStack.addArrangedSubview(donateTitle)
        contentStack.addArrangedSubview(donateBody)
        contentStack.addArrangedSubview(donateButton)
    }

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

    private func makeDonateButton() -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = UIColor(red: 0.98, green: 0.83, blue: 0.26, alpha: 1)
        configuration.baseForegroundColor = .black
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        configuration.title = "Buy me a coffee"
        configuration.image = UIImage(systemName: "cup.and.saucer.fill")
        configuration.imagePadding = 6

        let button = UIButton(configuration: configuration)
        button.contentHorizontalAlignment = .center
        button.addTarget(self, action: #selector(handleDonate), for: .touchUpInside)
        return button
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

    @objc private func handleClose() {
        dismiss(animated: true)
    }

    @objc private func handleDonate() {
        GuidedAccessSupport.dismissBuyMeACoffee()
        open(GuidedAccessSupport.buyMeACoffeeURL)
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