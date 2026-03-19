import XCTest
@testable import ToddlerPhotoLock

final class AppSupportContentTests: XCTestCase {
    func testHelpLinksUseExpectedDestinations() {
        XCTAssertEqual(AppSupportContent.faqURL.absoluteString, "https://github.com/ZachSaucier/Toddler-Photo-Lock/wiki/FAQ")
        XCTAssertEqual(AppSupportContent.issuesURL.absoluteString, "https://github.com/ZachSaucier/Toddler-Photo-Lock/issues")
        XCTAssertEqual(AppSupportContent.supportEmailURL.absoluteString, "mailto:toddlerphotolock@zachsaucier.com")
    }

    func testPrivacyPolicyUsesCurrentAppNameAndSevenSections() {
        XCTAssertEqual(AppSupportContent.privacyPolicyTitle, "Privacy Policy for Toddler Photo Lock")
        XCTAssertTrue(AppSupportContent.privacyPolicySummary.contains("Toddler Photo Lock"))
        XCTAssertEqual(AppSupportContent.privacyPolicySections.count, 7)
    }

    func testPrivacyPolicyLinkSectionsExposeExpectedURLs() {
        XCTAssertEqual(AppSupportContent.privacyPolicySections[3].actionURL, AppSupportContent.repositoryURL)
        XCTAssertEqual(AppSupportContent.privacyPolicySections[6].actionURL, AppSupportContent.issuesURL)
    }
}