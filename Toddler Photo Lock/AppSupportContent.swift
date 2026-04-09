import Foundation

struct PrivacyPolicySection: Equatable {
    let title: String
    let body: String
    let actionTitle: String?
    let actionURL: URL?
}

enum AppSupportContent {
    static let donateMessage = "I'm a dad who made this for my child. If it's been useful to you, a tip or annual subscription would mean a lot — it costs $100/year just to keep the app in the App Store."
    static let faqURL = URL(string: "https://github.com/ZachSaucier/Toddler-Photo-Lock/wiki/FAQ")!
    static let issuesURL = URL(string: "https://github.com/ZachSaucier/Toddler-Photo-Lock/issues")!
    static let repositoryURL = URL(string: "https://github.com/ZachSaucier/Toddler-Photo-Lock")!
    static let supportEmailAddress = "toddlerphotolock@zachsaucier.com"
    static let supportEmailURL = URL(string: "mailto:\(supportEmailAddress)")!

    static let privacyPolicyTitle = "Privacy Policy for Toddler Photo Lock"
    static let privacyPolicyLastUpdated = "Last Updated: March 15, 2026"
    static let privacyPolicySummary = "Toddler Photo Lock (\"the App\") is an open-source, privacy-first utility designed for parents. This Privacy Policy explains our approach to data: Your data never leaves your device."

    static let privacyPolicySections: [PrivacyPolicySection] = [
        PrivacyPolicySection(
            title: "1. Data Collection and Usage",
            body: "Toddler Photo Lock does not collect, store, or transmit any personal information.\n\n• No User Accounts: You are not required to create an account, log in, or provide any contact information (such as email or phone number) to use the App.\n• No Tracking: We do not use third-party analytics, advertising SDKs, or tracking cookies. We do not track your behavior across other apps or websites.\n• No Cloud Processing: All image processing and display happen locally on your iPhone or iPad. We do not operate any servers and cannot upload your images.",
            actionTitle: nil,
            actionURL: nil
        ),
        PrivacyPolicySection(
            title: "2. Permissions and System Access",
            body: "To provide its core functionality, the App requires specific system-level permissions. These are used only as described:\n\n• Photo Library Access: The App uses the iOS Photo Library permission to let you select a photo to display. The App reads these images locally; it does not copy, modify, or transmit them to any third party.\n• Idle Timer (Screen Wake): The App prevents the screen from dimming while in \"Lock Mode\" to ensure the child can view the photo. This is a local system command only.\n• Age Assurance (2026 Compliance): In accordance with 2026 App Store requirements, the App respects the Declared Age Range API signals provided by iOS to ensure an age-appropriate experience for users in all regions.",
            actionTitle: nil,
            actionURL: nil
        ),
        PrivacyPolicySection(
            title: "3. Children’s Privacy (Kids Category)",
            body: "Toddler Photo Lock is designed for parents of toddlers and complies with the Children’s Online Privacy Protection Act (COPPA), the GDPR-K, and relevant 2026 state age-assurance laws.\n\n• Zero Data Harvest: We do not collect any personally identifiable information (PII) from children.\n• No Third-Party Transmission: No device identifiers or usage data are shared with third parties.\n• Parental Gates: The App relies on the iOS Guided Access feature as a parental gate to prevent children from accessing external links, system settings, or other apps.",
            actionTitle: nil,
            actionURL: nil
        ),
        PrivacyPolicySection(
            title: "4. Open Source Transparency",
            body: "As an open-source project, the App's source code is available for public audit. This allows for technical verification of our \"No Data Collected\" claims.",
            actionTitle: "Open official GitHub repository",
            actionURL: repositoryURL
        ),
        PrivacyPolicySection(
            title: "5. Data Retention and Deletion",
            body: "Since no data is collected or stored on any server, there is no data to retain or delete. If you wish to reset the App, simply deleting it from your device will remove any temporary local cache.",
            actionTitle: nil,
            actionURL: nil
        ),
        PrivacyPolicySection(
            title: "6. Changes to This Policy",
            body: "We may update this Privacy Policy to reflect changes in iOS requirements. Any changes will be posted here with an updated Last Updated date. Because we do not collect contact info, we cannot notify you directly of updates.",
            actionTitle: nil,
            actionURL: nil
        ),
        PrivacyPolicySection(
            title: "7. Contact Information",
            body: "If you have questions about this Privacy Policy or wish to report a technical issue, please visit our GitHub repository and open a New Issue.",
            actionTitle: "Report an issue",
            actionURL: issuesURL
        )
    ]
}