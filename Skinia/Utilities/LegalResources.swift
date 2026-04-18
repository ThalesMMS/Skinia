import Foundation
import SafariServices
import UIKit

/// Centralized list of legal documents available in the app.
enum LegalDocument: String, CaseIterable, Identifiable {
    case termsOfUse = "terms_of_use"
    case privacyPolicy = "privacy_policy"
    case thirdPartyLicenses = "third_party_licenses"

    var id: String { rawValue }

    /// User-facing document title displayed in AboutView and reused by tests and previews.
    var localizedTitle: String {
        switch self {
        case .termsOfUse:
            return String(
                localized: "TermsOfUseTitle",
                defaultValue: "Terms of Use",
                comment: "Title for the terms of use legal document."
            )
        case .privacyPolicy:
            return String(
                localized: "PrivacyPolicyTitle",
                defaultValue: "Privacy Policy",
                comment: "Title for the privacy policy legal document."
            )
        case .thirdPartyLicenses:
            return String(
                localized: "ThirdPartyLicensesTitle",
                defaultValue: "Third-Party Licenses",
                comment: "Title for the third-party licenses legal document."
            )
        }
    }

    /// URL associated with the document.
    var url: URL? {
        switch self {
        case .termsOfUse:
            return LegalResources.termsOfUseURL
        case .privacyPolicy:
            return LegalResources.privacyPolicyURL
        case .thirdPartyLicenses:
            return LegalResources.thirdPartyLicensesURL
        }
    }
}

enum LegalResources {
    /// Official URL for Skinia's terms of use.
    static let termsOfUseURL = URL(string: "https://skinia.app/legal/terms")

    /// Official URL for Skinia's privacy policy.
    static let privacyPolicyURL = URL(string: "https://skinia.app/legal/privacy")

    /// URL for the open-source licenses used by the app.
    static let thirdPartyLicensesURL = URL(string: "https://skinia.app/legal/licenses")
}

protocol LegalDocumentOpening {
    func open(_ document: LegalDocument)
}

final class LegalDocumentOpener: LegalDocumentOpening {
    static let shared = LegalDocumentOpener()

    private init() {}

    func open(_ document: LegalDocument) {
        guard let url = document.url else {
            return
        }

        open(url)
    }

    // MARK: - Private helpers

    private func open(_ url: URL) {
        DispatchQueue.main.async {
            if let presenter = UIApplication.shared.topMostViewController() {
                let safariController = SFSafariViewController(url: url)
                presenter.present(safariController, animated: true)
            } else if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

private extension UIApplication {
    /// Finds the app's current top-most view controller.
    /// - Parameter controller: The starting controller to inspect. If omitted, the function uses the key window's `rootViewController` from the app's connected `UIWindowScene` instances.
    /// - Returns: The view controller that is currently visible to the user, or `nil` if none.
    func topMostViewController(
        controller: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .rootViewController
    ) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topMostViewController(controller: navigationController.visibleViewController)
        }

        if let tabController = controller as? UITabBarController, let selected = tabController.selectedViewController {
            return topMostViewController(controller: selected)
        }

        if let presented = controller?.presentedViewController {
            return topMostViewController(controller: presented)
        }

        return controller
    }
}
