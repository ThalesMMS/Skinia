import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("analysisCompleteNotifications") private var analysisCompleteNotifications = true
    @AppStorage("reminderNotifications") private var reminderNotifications = false
    @AppStorage("urgentResultNotifications") private var urgentResultNotifications = true
    @AppStorage("reminderFrequency") private var reminderFrequency = ReminderFrequency.monthly.rawValue
    
    @State private var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Notification Status Section
                Section {
                    NotificationStatusCard(status: notificationAuthorizationStatus)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
                
                // General Settings
                Section("Configurações Gerais") {
                    Toggle(isOn: $notificationsEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ativar Notificações")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.text)
                            
                            Text("Permitir que o app envie notificações")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
                    .disabled(notificationAuthorizationStatus == .denied)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        if newValue && notificationAuthorizationStatus == .notDetermined {
                            requestNotificationPermission()
                        }
                    }
                }
                
                // Analysis Notifications
                Section("Notificações de Análise") {
                    NotificationToggleRow(
                        isOn: $analysisCompleteNotifications,
                        title: "Análise Concluída",
                        subtitle: "Quando o resultado da análise estiver pronto",
                        icon: "checkmark.circle",
                        iconColor: DesignSystem.Colors.success,
                        isEnabled: notificationsEnabled && notificationAuthorizationStatus == .authorized
                    )
                    
                    NotificationToggleRow(
                        isOn: $urgentResultNotifications,
                        title: "Resultados Urgentes",
                        subtitle: "Para análises que indicam alto risco",
                        icon: "exclamationmark.triangle",
                        iconColor: DesignSystem.Colors.error,
                        isEnabled: notificationsEnabled && notificationAuthorizationStatus == .authorized
                    )
                }
                
                // Reminder Notifications
                Section("Lembretes") {
                    NotificationToggleRow(
                        isOn: $reminderNotifications,
                        title: "Lembretes de Monitoramento",
                        subtitle: "Para acompanhar lesões regularmente",
                        icon: "bell.badge",
                        iconColor: DesignSystem.Colors.warning,
                        isEnabled: notificationsEnabled && notificationAuthorizationStatus == .authorized
                    )
                    
                    if reminderNotifications {
                        ReminderFrequencyPicker(selectedFrequency: Binding(
                            get: { ReminderFrequency(rawValue: reminderFrequency) ?? .monthly },
                            set: { reminderFrequency = $0.rawValue }
                        ))
                        .disabled(!notificationsEnabled || notificationAuthorizationStatus != .authorized)
                    }
                }
                
                // Information Section
                Section("Informações") {
                    InfoRow(
                        icon: "info.circle",
                        iconColor: DesignSystem.Colors.info,
                        title: "Sobre as Notificações",
                        subtitle: "As notificações ajudam você a acompanhar suas análises e manter um monitoramento regular da saúde da sua pele."
                    )
                    
                    InfoRow(
                        icon: "shield.checkerboard",
                        iconColor: DesignSystem.Colors.success,
                        title: "Privacidade",
                        subtitle: "As notificações são geradas localmente no seu dispositivo e não compartilhamos informações com terceiros."
                    )
                }
            }
            .navigationTitle("Notificações")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            checkNotificationStatus()
        }
        .alert("Permissão de Notificação", isPresented: $showingPermissionAlert) {
            Button("Configurações") {
                openAppSettings()
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Para receber notificações, ative as permissões nas Configurações do iOS.")
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationAuthorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.notificationAuthorizationStatus = .authorized
                } else {
                    self.notificationAuthorizationStatus = .denied
                    self.notificationsEnabled = false
                    self.showingPermissionAlert = true
                }
            }
        }
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Reminder Frequency

enum ReminderFrequency: String, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    
    var title: String {
        switch self {
        case .weekly: return "Semanal"
        case .monthly: return "Mensal"
        case .quarterly: return "Trimestral"
        }
    }
    
    var description: String {
        switch self {
        case .weekly: return "A cada 7 dias"
        case .monthly: return "A cada 30 dias"
        case .quarterly: return "A cada 3 meses"
        }
    }
}

// MARK: - Notification Status Card

struct NotificationStatusCard: View {
    let status: UNAuthorizationStatus
    
    private var statusInfo: (title: String, subtitle: String, icon: String, color: Color) {
        switch status {
        case .authorized:
            return ("Notificações Ativas", "O app pode enviar notificações", "checkmark.circle.fill", DesignSystem.Colors.success)
        case .denied:
            return ("Notificações Desativadas", "Ative nas Configurações do iOS", "xmark.circle.fill", DesignSystem.Colors.error)
        case .notDetermined:
            return ("Permissão Pendente", "Ative as notificações para receber alertas", "questionmark.circle.fill", DesignSystem.Colors.warning)
        case .provisional:
            return ("Notificações Provisórias", "Notificações silenciosas ativadas", "bell.slash.fill", DesignSystem.Colors.warning)
        case .ephemeral:
            return ("Temporárias", "Notificações temporárias", "clock.fill", DesignSystem.Colors.info)
        @unknown default:
            return ("Status Desconhecido", "Verifique as configurações", "questionmark.circle.fill", DesignSystem.Colors.textSecondary)
        }
    }
    
    var body: some View {
        let info = statusInfo
        
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: info.icon)
                .font(.system(size: 28))
                .foregroundColor(info.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(info.title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
                
                Text(info.subtitle)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .background(info.color.opacity(0.1))
        .cornerRadius(DesignSystem.CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .stroke(info.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
}

// MARK: - Notification Toggle Row

struct NotificationToggleRow: View {
    @Binding var isOn: Bool
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let isEnabled: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor.opacity(isEnabled ? 1.0 : 0.5))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(isEnabled ? DesignSystem.Colors.text : DesignSystem.Colors.textSecondary)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - Reminder Frequency Picker

struct ReminderFrequencyPicker: View {
    @Binding var selectedFrequency: ReminderFrequency
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(width: 24)
                
                Text("Frequência dos Lembretes")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(ReminderFrequency.allCases, id: \.self) { frequency in
                    FrequencyOption(
                        frequency: frequency,
                        isSelected: selectedFrequency == frequency
                    ) {
                        selectedFrequency = frequency
                        HapticManager.shared.selection()
                    }
                }
            }
            .padding(.leading, 38) // Align with text above
        }
    }
}

// MARK: - Frequency Option

struct FrequencyOption: View {
    let frequency: ReminderFrequency
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(frequency.title)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text(frequency.description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24)
                .padding(.top, 1)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.text)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
}