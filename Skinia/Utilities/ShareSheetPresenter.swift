import UIKit

final class ShareSheetPresenter {
    func present(items: [Any], from sourceView: UIView? = nil, sourceRect: CGRect? = nil) {
        guard !items.isEmpty else { return }

        DispatchQueue.main.async {
            let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)

            if let popover = activityController.popoverPresentationController {
                if let sourceView {
                    popover.sourceView = sourceView
                    popover.sourceRect = sourceRect ?? sourceView.bounds
                } else if let window = self.keyWindow {
                    popover.sourceView = window
                    popover.sourceRect = sourceRect ?? CGRect(
                        x: window.bounds.midX,
                        y: window.bounds.midY,
                        width: 0,
                        height: 0
                    )
                    popover.permittedArrowDirections = []
                }
            }

            guard let presenter = self.topViewController() else { return }
            presenter.present(activityController, animated: true)
        }
    }

    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let startingController: UIViewController?
        if let base {
            startingController = base
        } else {
            startingController = keyWindow?.rootViewController
        }

        if let navigationController = startingController as? UINavigationController {
            return topViewController(base: navigationController.visibleViewController)
        }

        if let tabController = startingController as? UITabBarController,
           let selected = tabController.selectedViewController {
            return topViewController(base: selected)
        }

        if let presented = startingController?.presentedViewController {
            return topViewController(base: presented)
        }

        return startingController
    }

    private var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
    }
}
