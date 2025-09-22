import Foundation
import SafariServices
import UIKit

/// Lista centralizada dos documentos legais disponíveis no app.
enum LegalDocument: CaseIterable, Identifiable {
    case termsOfUse
    case privacyPolicy
    case thirdPartyLicenses

    var id: String { localizedTitle }

    /// Título amigável do documento para uso em testes e prévias.
    var localizedTitle: String {
        switch self {
        case .termsOfUse:
            return "Termos de Uso"
        case .privacyPolicy:
            return "Política de Privacidade"
        case .thirdPartyLicenses:
            return "Licenças de Terceiros"
        }
    }

    /// URL associada ao documento.
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

struct LegalResources {
    /// URL oficial com os termos de uso do Skinia.
    static let termsOfUseURL = URL(string: "https://skinia.app/legal/terms")

    /// URL oficial com a política de privacidade do Skinia.
    static let privacyPolicyURL = URL(string: "https://skinia.app/legal/privacy")

    /// URL com as licenças de código aberto utilizadas pelo app.
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

