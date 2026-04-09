import Foundation
import StoreKit

// MARK: - Product identifiers

enum TipJarProduct {
    static let tip2   = "com.example.ToddlerPhotoLock.tip2"
    static let tip5   = "com.example.ToddlerPhotoLock.tip5"
    static let tip20  = "com.example.ToddlerPhotoLock.tip20"
    static let annual = "com.example.ToddlerPhotoLock.annual"

    static var allIDs: [String] { [tip2, tip5, tip20, annual] }
}

// MARK: - Persistence keys

private enum TipJarDefaults {
    static let tipsKey        = "ToddlerPhotoLock.tipAmounts"       // [String: Double] productID → amount
    static let subscriptionKey = "ToddlerPhotoLock.subscriptionInfo" // Data (encoded SubscriptionInfo)
}

// MARK: - Models

struct SubscriptionInfo: Codable, Equatable {
    /// Formatted price string, e.g. "$4.99"
    let formattedPrice: String
    /// Raw price value
    let price: Decimal
    /// Next renewal date
    let renewalDate: Date
    /// Original transaction ID, used to identify the active subscription
    let originalTransactionID: UInt64
}

// MARK: - Service

/// Handles all StoreKit 2 interactions for the tip jar.
/// Observation of transaction updates runs for the lifetime of the service.
@MainActor
final class TipJarService: ObservableObject {
    static let shared = TipJarService()

    /// productID → formatted price paid (persisted across launches)
    private(set) var completedTips: [String: String] = [:]

    /// Non-nil when an active auto-renewable subscription exists
    private(set) var activeSubscription: SubscriptionInfo?

    /// Loaded StoreKit products, keyed by product ID
    private(set) var products: [String: Product] = [:]

    private var transactionUpdateTask: Task<Void, Never>?

    private init() {
        loadPersistedState()
        transactionUpdateTask = listenForTransactionUpdates()
    }

    deinit {
        transactionUpdateTask?.cancel()
    }

    // MARK: - Public API

    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: TipJarProduct.allIDs)
            products = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
        } catch {
            // Products unavailable (e.g. no StoreKit config in simulator) — fail silently
        }
    }

    /// Initiates a purchase. Returns the purchased product on success, nil if the user cancelled.
    /// Throws on unrecoverable errors.
    func purchase(_ product: Product) async throws -> Product? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await handleTransaction(transaction)
            await transaction.finish()
            return product
        case .userCancelled:
            return nil
        case .pending:
            return nil
        @unknown default:
            return nil
        }
    }

    /// Re-checks current entitlements (e.g. after app foreground).
    func refreshStatus() async {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            await handleTransaction(transaction)
        }
    }

    // MARK: - Transaction handling

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard let self else { break }
                guard let transaction = try? self.checkVerified(result) else { continue }
                await self.handleTransaction(transaction)
                await transaction.finish()
            }
        }
    }

    private func handleTransaction(_ transaction: Transaction) async {
        if transaction.revocationDate != nil {
            // Subscription was refunded or revoked
            if transaction.productID == TipJarProduct.annual {
                clearSubscription()
            }
            return
        }

        switch transaction.productType {
        case .consumable:
            recordTip(productID: transaction.productID)
        case .autoRenewable:
            await recordSubscription(transaction: transaction)
        default:
            break
        }
    }

    // MARK: - Tip persistence

    private func recordTip(productID: String) {
        guard let product = products[productID] else { return }
        var tips = loadRawTips()
        tips[productID] = product.displayPrice
        saveRawTips(tips)
        completedTips = tips
    }

    private func loadRawTips() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: TipJarDefaults.tipsKey) as? [String: String] ?? [:]
    }

    private func saveRawTips(_ tips: [String: String]) {
        UserDefaults.standard.set(tips, forKey: TipJarDefaults.tipsKey)
    }

    // MARK: - Subscription persistence

    private func recordSubscription(transaction: Transaction) async {
        // Resolve renewal date from subscription status if available
        var renewalDate = transaction.expirationDate ?? Date().addingTimeInterval(365 * 24 * 3600)

        if let statuses = try? await Product.SubscriptionInfo.status(for: TipJarProduct.annual) {
            for status in statuses {
                if case .verified(let renewal) = status.renewalInfo,
                   let nextDate = renewal.renewalDate {
                    renewalDate = nextDate
                }
            }
        }

        let price: Decimal
        let formatted: String
        if let product = products[TipJarProduct.annual] {
            price = product.price
            formatted = product.displayPrice
        } else {
            price = 0
            formatted = ""
        }

        let info = SubscriptionInfo(
            formattedPrice: formatted,
            price: price,
            renewalDate: renewalDate,
            originalTransactionID: transaction.originalID
        )

        if let data = try? JSONEncoder().encode(info) {
            UserDefaults.standard.set(data, forKey: TipJarDefaults.subscriptionKey)
        }
        activeSubscription = info
    }

    private func clearSubscription() {
        UserDefaults.standard.removeObject(forKey: TipJarDefaults.subscriptionKey)
        activeSubscription = nil
    }

    // MARK: - State restoration

    private func loadPersistedState() {
        completedTips = loadRawTips()

        if let data = UserDefaults.standard.data(forKey: TipJarDefaults.subscriptionKey),
           let info = try? JSONDecoder().decode(SubscriptionInfo.self, from: data) {
            activeSubscription = info
        }
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }
}

// MARK: - Errors

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed."
        }
    }
}
