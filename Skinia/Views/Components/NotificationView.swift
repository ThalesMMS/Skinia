import SwiftUI

struct NotificationView: View {
    let notification: StatusNotification
    let onDismiss: () -> Void
    
    var body: some View {
        ToastView(notification: notification, onDismiss: onDismiss)
    }
}

struct StatusNotification: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String?
    let type: NotificationType
    let duration: TimeInterval
    
    init(title: String, message: String? = nil, type: NotificationType, duration: TimeInterval = 3.0) {
        self.title = title
        self.message = message
        self.type = type
        self.duration = duration
    }
    
    var icon: String {
        switch type {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.circle.fill"
        }
    }
    
    var color: Color {
        switch type {
        case .success:
            return .green
        case .error:
            return .red
        case .info:
            return .blue
        case .warning:
            return .orange
        }
    }
    
    enum NotificationType {
        case success
        case error
        case info
        case warning
    }
}

// MARK: - Notification Manager

@MainActor
@Observable
final class NotificationManager {
    private(set) var notifications: [StatusNotification] = []
    
    func show(_ notification: StatusNotification) {
        notifications.append(notification)
    }
    
    func show(title: String, message: String? = nil, type: StatusNotification.NotificationType, duration: TimeInterval = 3.0) {
        let notification = StatusNotification(title: title, message: message, type: type, duration: duration)
        show(notification)
    }
    
    func dismiss(_ notification: StatusNotification) {
        notifications.removeAll { $0.id == notification.id }
    }
    
    func dismissAll() {
        notifications.removeAll()
    }
}

// MARK: - Environment Key

private struct NotificationManagerKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue = NotificationManager()
}

extension EnvironmentValues {
    var notificationManager: NotificationManager {
        get { self[NotificationManagerKey.self] }
        set { self[NotificationManagerKey.self] = newValue }
    }
}

// MARK: - Notification Overlay

struct NotificationOverlay: View {
    @Environment(\.notificationManager) private var notificationManager
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(notificationManager.notifications) { notification in
                NotificationView(notification: notification) {
                    notificationManager.dismiss(notification)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false) // Allow touches to pass through to content below
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: notificationManager.notifications.count)
    }
}

#Preview {
    VStack(spacing: 20) {
        NotificationView(
            notification: StatusNotification(
                title: "Análise Concluída",
                message: "Sua foto foi analisada com sucesso. Confiança: 85%",
                type: .success
            )
        ) {}
        
        NotificationView(
            notification: StatusNotification(
                title: "Erro na Análise",
                message: "Houve um problema ao processar sua imagem. Tente novamente.",
                type: .error
            )
        ) {}
        
        NotificationView(
            notification: StatusNotification(
                title: "Análise Iniciada",
                message: "Processando sua imagem...",
                type: .info
            )
        ) {}
    }
    .padding()
}