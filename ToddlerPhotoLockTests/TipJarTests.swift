import XCTest
@testable import ToddlerPhotoLock

final class TipJarTests: XCTestCase {

    // MARK: - TipJarProduct

    func testProductIDsMatchExpectedBundlePrefix() {
        XCTAssertEqual(TipJarProduct.tip2,   "com.example.ToddlerPhotoLock.tip2")
        XCTAssertEqual(TipJarProduct.tip5,   "com.example.ToddlerPhotoLock.tip5")
        XCTAssertEqual(TipJarProduct.tip20,  "com.example.ToddlerPhotoLock.tip20")
        XCTAssertEqual(TipJarProduct.annual, "com.example.ToddlerPhotoLock.annual")
    }

    func testAllIDsContainsEveryProduct() {
        let ids = TipJarProduct.allIDs
        XCTAssertTrue(ids.contains(TipJarProduct.tip2))
        XCTAssertTrue(ids.contains(TipJarProduct.tip5))
        XCTAssertTrue(ids.contains(TipJarProduct.tip20))
        XCTAssertTrue(ids.contains(TipJarProduct.annual))
        XCTAssertEqual(ids.count, 4)
    }

    func testAllIDsHasNoDuplicates() {
        let ids = TipJarProduct.allIDs
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    // MARK: - SubscriptionInfo Codable

    func testSubscriptionInfoRoundTrips() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let original = SubscriptionInfo(
            formattedPrice: "$9.99",
            price: Decimal(string: "9.99")!,
            renewalDate: date,
            originalTransactionID: 42
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SubscriptionInfo.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testSubscriptionInfoPreservesAllFields() throws {
        let date = Date(timeIntervalSince1970: 2_000_000_000)
        let info = SubscriptionInfo(
            formattedPrice: "$19.99",
            price: Decimal(string: "19.99")!,
            renewalDate: date,
            originalTransactionID: 99999
        )

        let data = try JSONEncoder().encode(info)
        let decoded = try JSONDecoder().decode(SubscriptionInfo.self, from: data)

        XCTAssertEqual(decoded.formattedPrice, "$19.99")
        XCTAssertEqual(decoded.price, Decimal(string: "19.99")!)
        XCTAssertEqual(decoded.renewalDate, date)
        XCTAssertEqual(decoded.originalTransactionID, 99999)
    }

    func testSubscriptionInfoEqualityIsValueBased() {
        let date = Date(timeIntervalSince1970: 1_000_000)
        let a = SubscriptionInfo(formattedPrice: "$9.99", price: 9.99, renewalDate: date, originalTransactionID: 1)
        let b = SubscriptionInfo(formattedPrice: "$9.99", price: 9.99, renewalDate: date, originalTransactionID: 1)
        let c = SubscriptionInfo(formattedPrice: "$9.99", price: 9.99, renewalDate: date, originalTransactionID: 2)

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: - StoreError

    func testStoreErrorFailedVerificationHasDescription() {
        let error = StoreError.failedVerification
        XCTAssertEqual(error.errorDescription, "Transaction verification failed.")
    }

    func testStoreErrorConformsToLocalizedError() {
        let error: LocalizedError = StoreError.failedVerification
        XCTAssertNotNil(error.errorDescription)
    }
}
