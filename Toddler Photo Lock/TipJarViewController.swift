import StoreKit
import UIKit

// MARK: - TipJarViewController

/// Embedded view controller that renders the full tip jar UI inside HelpViewController.
/// It manages its own height via intrinsic content — the parent just adds it as a child.
final class TipJarViewController: UIViewController {
    private let service = TipJarService.shared

    // MARK: Subviews

    private let stack: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .vertical
        s.alignment = .fill
        s.spacing = 12
        return s
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .medium)
        i.translatesAutoresizingMaskIntoConstraints = false
        i.color = .white
        i.hidesWhenStopped = true
        return i
    }()

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(stack)
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        loadingIndicator.startAnimating()
        Task { await loadAndRender() }
    }

    // MARK: - Rendering

    private func loadAndRender() async {
        await service.loadProducts()
        await service.refreshStatus()
        loadingIndicator.stopAnimating()
        render()
    }

    private func render() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Active subscription view — replaces tip buttons
        if let sub = service.activeSubscription {
            renderSubscriptionActive(sub)
            return
        }

        // Tip buttons
        let tipIDs = [TipJarProduct.tip2, TipJarProduct.tip5, TipJarProduct.tip20]
        for id in tipIDs {
            let product = service.products[id]
            let priorTip = service.completedTips[id]
            stack.addArrangedSubview(makeTipRow(productID: id, product: product, priorTip: priorTip))
        }

        // Divider
        stack.addArrangedSubview(makeDivider())

        // Annual subscription row
        let annualProduct = service.products[TipJarProduct.annual]
        stack.addArrangedSubview(makeSubscriptionRow(product: annualProduct))
    }

    // MARK: - Subscription active state

    private func renderSubscriptionActive(_ sub: SubscriptionInfo) {
        let thankYou = makeBodyLabel(
            text: "Thank you so much for your annual subscription of \(sub.formattedPrice)!"
        )
        stack.addArrangedSubview(thankYou)

        let renewalFormatter = DateFormatter()
        renewalFormatter.dateStyle = .long
        renewalFormatter.timeStyle = .none
        let renewalText = "Renews \(renewalFormatter.string(from: sub.renewalDate)) · \(sub.formattedPrice)/year"
        stack.addArrangedSubview(makeSecondaryLabel(text: renewalText))

        let cancelButton = makePlainButton(title: "Manage subscription", action: #selector(handleManageSubscription))
        stack.addArrangedSubview(cancelButton)
    }

    // MARK: - Tip row

    private func makeTipRow(productID: String, product: Product?, priorTip: String?) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12

        let label: UILabel
        if let priorTip {
            label = makeBodyLabel(text: "Thank you so much for your \(priorTip) tip!")
        } else {
            label = makeBodyLabel(text: tipLabel(for: productID))
        }
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let price = product?.displayPrice ?? priceLabel(for: productID)
        let button = makePillButton(title: price)
        button.tag = tipTag(for: productID)
        button.addTarget(self, action: #selector(handleTipTapped(_:)), for: .touchUpInside)
        button.isEnabled = product != nil && priorTip == nil

        // Dim button if already tipped or unavailable
        button.alpha = (product == nil || priorTip != nil) ? 0.45 : 1

        row.addArrangedSubview(label)
        row.addArrangedSubview(button)
        return row
    }

    // MARK: - Subscription row

    private func makeSubscriptionRow(product: Product?) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .fill
        container.spacing = 8

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12

        let label = makeBodyLabel(text: "Annual supporter")
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let price = product.map { "\($0.displayPrice)/yr" } ?? "$X/yr"
        let button = makePillButton(title: price)
        button.tag = 99
        button.addTarget(self, action: #selector(handleSubscribeTapped), for: .touchUpInside)
        button.isEnabled = product != nil
        button.alpha = product == nil ? 0.45 : 1

        row.addArrangedSubview(label)
        row.addArrangedSubview(button)
        container.addArrangedSubview(row)

        if let product {
            let desc = makeSecondaryLabel(text: product.description)
            container.addArrangedSubview(desc)
        }

        return container
    }

    // MARK: - Actions

    @objc private func handleTipTapped(_ sender: UIButton) {
        let productID: String
        switch sender.tag {
        case 2:  productID = TipJarProduct.tip2
        case 5:  productID = TipJarProduct.tip5
        case 20: productID = TipJarProduct.tip20
        default: return
        }
        guard let product = service.products[productID] else { return }
        purchase(product)
    }

    @objc private func handleSubscribeTapped() {
        guard let product = service.products[TipJarProduct.annual] else { return }
        purchase(product)
    }

    @objc private func handleManageSubscription() {
        guard let scene = view.window?.windowScene else { return }
        Task {
            try? await AppStore.showManageSubscriptions(in: scene)
        }
    }

    private func purchase(_ product: Product) {
        Task {
            do {
                let purchased = try await service.purchase(product)
                if purchased != nil {
                    render()
                    showSuccessAlert(for: product)
                }
            } catch {
                showErrorAlert(error)
            }
        }
    }

    // MARK: - Alerts

    private func showSuccessAlert(for product: Product) {
        let isSubscription = product.type == .autoRenewable
        let title = isSubscription ? "Subscription active!" : "Thank you!"
        let message: String
        if isSubscription {
            message = "Your annual subscription of \(product.displayPrice) is now active. Thank you for your support!"
        } else {
            message = "Your \(product.displayPrice) tip means a lot. Thank you!"
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Done", style: .default))
        present(alert, animated: true)
    }

    private func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "Purchase failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - View factories

    private func makeBodyLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor(white: 0.86, alpha: 1)
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }

    private func makeSecondaryLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor(white: 0.6, alpha: 1)
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }

    private func makePillButton(title: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor(white: 0.22, alpha: 1)
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var out = attrs
            out.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            return out
        }
        let button = UIButton(configuration: config)
        button.setTitle(title, for: .normal)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }

    private func makePlainButton(title: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = UIColor(white: 0.6, alpha: 1)
        config.contentInsets = .zero
        let button = UIButton(configuration: config)
        button.setTitle(title, for: .normal)
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeDivider() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.25, alpha: 1)
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return view
    }

    // MARK: - Helpers

    private func tipLabel(for productID: String) -> String {
        switch productID {
        case TipJarProduct.tip2:  return "Small tip"
        case TipJarProduct.tip5:  return "Medium tip"
        case TipJarProduct.tip20: return "Large tip"
        default: return "Tip"
        }
    }

    private func priceLabel(for productID: String) -> String {
        switch productID {
        case TipJarProduct.tip2:  return "$1.99"
        case TipJarProduct.tip5:  return "$4.99"
        case TipJarProduct.tip20: return "$19.99"
        default: return "—"
        }
    }

    private func tipTag(for productID: String) -> Int {
        switch productID {
        case TipJarProduct.tip2:  return 2
        case TipJarProduct.tip5:  return 5
        case TipJarProduct.tip20: return 20
        default: return 0
        }
    }
}
