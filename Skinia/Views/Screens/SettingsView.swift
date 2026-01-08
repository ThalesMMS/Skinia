import SwiftUI
import MessageUI

struct SettingsView: View {
    private let legalDocumentOpener: LegalDocumentOpening

    @State private var showingFeedbackSheet = false
    @State private var showingHelpSheet = false
    @State private var showingPrivacySheet = false
    @State private var showingAboutSheet = false
    @State private var showingNotificationSettings = false
    @State private var showingImageQualitySettings = false

    init(legalDocumentOpener: LegalDocumentOpening = LegalDocumentOpener.shared) {
        self.legalDocumentOpener = legalDocumentOpener
    }
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Análise e Qualidade
                Section("Análise e Qualidade") {
                    SettingsRow(
                        icon: "photo.badge.checkmark",
                        iconColor: DesignSystem.Colors.primary,
                        title: "Qualidade da Imagem",
                        subtitle: "Configurar resolução e compressão",
                        action: {
                            showingImageQualitySettings = true
                        }
                    )
                    
                    SettingsRow(
                        icon: "bell.badge",
                        iconColor: DesignSystem.Colors.secondary,
                        title: "Notificações",
                        subtitle: "Resultados de análise e lembretes",
                        action: {
                            showingNotificationSettings = true
                        }
                    )
                }
                
                // MARK: - Privacidade e Segurança
                Section("Privacidade e Segurança") {
                    SettingsRow(
                        icon: "lock.shield",
                        iconColor: DesignSystem.Colors.success,
                        title: "Privacidade",
                        subtitle: "Gerenciar dados e permissões",
                        action: {
                            showingPrivacySheet = true
                        }
                    )
                    
                    SettingsRow(
                        icon: "camera",
                        iconColor: DesignSystem.Colors.info,
                        title: "Permissões da Câmera",
                        subtitle: "Configurar acesso à câmera e fotos",
                        action: {
                            openAppSettings()
                        }
                    )
                }
                
                // MARK: - Suporte e Ajuda
                Section("Suporte e Ajuda") {
                    SettingsRow(
                        icon: "questionmark.circle",
                        iconColor: DesignSystem.Colors.warning,
                        title: "Ajuda e Tutoriais",
                        subtitle: "Como usar o Skinia",
                        action: {
                            showingHelpSheet = true
                        }
                    )
                    
                    SettingsRow(
                        icon: "envelope",
                        iconColor: DesignSystem.Colors.secondary,
                        title: "Enviar Feedback",
                        subtitle: "Sugestões e problemas",
                        action: {
                            showingFeedbackSheet = true
                        }
                    )
                    
                    SettingsRow(
                        icon: "star",
                        iconColor: DesignSystem.Colors.warning,
                        title: "Avaliar o App",
                        subtitle: "Deixe sua avaliação na App Store",
                        action: {
                            openAppStore()
                        }
                    )
                }
                
                // MARK: - Sobre
                Section("Sobre") {
                    SettingsRow(
                        icon: "info.circle",
                        iconColor: DesignSystem.Colors.textSecondary,
                        title: "Sobre o Skinia",
                        subtitle: "Versão 1.0.0",
                        action: {
                            showingAboutSheet = true
                        }
                    )
                    
                    SettingsRow(
                        icon: "doc.text",
                        iconColor: DesignSystem.Colors.textSecondary,
                        title: "Termos de Uso",
                        subtitle: "Termos e condições",
                        action: {
                            legalDocumentOpener.open(.termsOfUse)
                        }
                    )

                    SettingsRow(
                        icon: "hand.raised",
                        iconColor: DesignSystem.Colors.textSecondary,
                        title: "Política de Privacidade",
                        subtitle: "Como protegemos seus dados",
                        action: {
                            legalDocumentOpener.open(.privacyPolicy)
                        }
                    )
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Configurações")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingHelpSheet) {
            HelpAndTutorialsView()
        }
        .sheet(isPresented: $showingFeedbackSheet) {
            FeedbackView()
        }
        .sheet(isPresented: $showingPrivacySheet) {
            PrivacySettingsView()
        }
        .sheet(isPresented: $showingAboutSheet) {
            AboutView()
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingImageQualitySettings) {
            ImageQualitySettingsView()
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
    
    private func openAppStore() {
        // TODO: Substituir pelo ID real do app quando publicado
        let appStoreURL = URL(string: "https://apps.apple.com/app/id123456789")
        if let url = appStoreURL {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Settings Row Component

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 28, height: 28)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview("Configurações") {
    SettingsView()
}

#if DEBUG
private struct SettingsViewPreviewContainer: View {
    @StateObject private var legalOpener = PreviewLegalDocumentOpener()

    var body: some View {
        SettingsView(legalDocumentOpener: legalOpener)
            .overlay(alignment: .bottom) {
                if let document = legalOpener.lastOpenedDocument {
                    PreviewLegalDocumentBanner(title: document.localizedTitle)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding()
                }
            }
            .overlay(alignment: .top) {
                PreviewInstructionLabel(text: "Toque nos links de Termos ou Privacidade para validar a prévia.")
            }
            .animation(.easeInOut, value: legalOpener.lastOpenedDocument)
    }
}

#Preview("Configurações • Ações Legais") {
    SettingsViewPreviewContainer()
}
#endif
