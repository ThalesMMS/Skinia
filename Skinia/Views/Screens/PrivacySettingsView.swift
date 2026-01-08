import SwiftUI
import SwiftData

@MainActor
struct PrivacySettingsView: View {
    private let analysisExportService: any AnalysisExportServiceProtocol
    private let photoRepository: any PhotoRepositoryProtocol
    private let shareSheetPresenter: ShareSheetPresenter
    private let modelContainer: ModelContainer

    @Environment(\.dismiss) private var dismiss
    @Environment(\.notificationManager) private var notificationManager
    @State private var showingDataDeletionAlert = false
    @State private var showingPermissionsInfo = false
    @State private var isShareSheetPresented = false
    @State private var exportedFileURL: URL?
    @State private var pendingSuccessMessage: String?
    @State private var pendingErrorMessage: String?

    init(
        analysisExportService: (any AnalysisExportServiceProtocol)? = nil,
        photoRepository: (any PhotoRepositoryProtocol)? = nil,
        shareSheetPresenter: ShareSheetPresenter? = nil,
        modelContainer: ModelContainer? = nil
    ) {
        let container = DependencyContainer.shared
        self.analysisExportService = analysisExportService ?? container.analysisExportService
        self.photoRepository = photoRepository ?? container.photoRepository
        self.shareSheetPresenter = shareSheetPresenter ?? container.shareSheetPresenter
        self.modelContainer = modelContainer ?? container.modelContainer
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.success)
                        
                        Text("Privacidade e Segurança")
                            .font(DesignSystem.Typography.title1)
                            .foregroundColor(DesignSystem.Colors.text)
                        
                        Text("Controle como seus dados são coletados, armazenados e utilizados")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, DesignSystem.Spacing.md)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Privacy sections
                    VStack(spacing: DesignSystem.Spacing.md) {
                        // Data Storage
                        PrivacySectionCard(
                            title: "Armazenamento de Dados",
                            icon: "internaldrive",
                            iconColor: DesignSystem.Colors.primary,
                            items: [
                                PrivacyItem(
                                    title: "Fotos das Lesões",
                                    description: "Armazenadas localmente no seu dispositivo",
                                    status: .secure,
                                    icon: "photo"
                                ),
                                PrivacyItem(
                                    title: "Resultados de Análise",
                                    description: "Salvos no dispositivo, nunca compartilhados",
                                    status: .secure,
                                    icon: "doc.text"
                                ),
                                PrivacyItem(
                                    title: "Histórico de Análises",
                                    description: "Mantido apenas localmente",
                                    status: .secure,
                                    icon: "clock"
                                )
                            ]
                        )
                        
                        // Data Transmission
                        PrivacySectionCard(
                            title: "Transmissão de Dados",
                            icon: "network",
                            iconColor: DesignSystem.Colors.info,
                            items: [
                                PrivacyItem(
                                    title: "Upload para Análise",
                                    description: "Imagens são enviadas apenas quando você solicita análise",
                                    status: .controlled,
                                    icon: "arrow.up.circle"
                                ),
                                PrivacyItem(
                                    title: "Criptografia SSL/TLS",
                                    description: "Todas as comunicações são criptografadas",
                                    status: .secure,
                                    icon: "lock"
                                ),
                                PrivacyItem(
                                    title: "Exclusão Automática",
                                    description: "Imagens são deletadas dos servidores após análise",
                                    status: .secure,
                                    icon: "trash"
                                )
                            ]
                        )
                        
                        // Permissions
                        PrivacySectionCard(
                            title: "Permissões",
                            icon: "checkmark.shield",
                            iconColor: DesignSystem.Colors.warning,
                            items: [
                                PrivacyItem(
                                    title: "Câmera",
                                    description: "Para capturar fotos das lesões",
                                    status: .required,
                                    icon: "camera",
                                    action: {
                                        openAppSettings()
                                    }
                                ),
                                PrivacyItem(
                                    title: "Biblioteca de Fotos",
                                    description: "Para importar fotos existentes (opcional)",
                                    status: .optional,
                                    icon: "photo.on.rectangle",
                                    action: {
                                        openAppSettings()
                                    }
                                ),
                                PrivacyItem(
                                    title: "Notificações",
                                    description: "Para avisos sobre resultados de análise (opcional)",
                                    status: .optional,
                                    icon: "bell",
                                    action: {
                                        openAppSettings()
                                    }
                                )
                            ]
                        )
                        
                        // Data Control
                        PrivacySectionCard(
                            title: "Controle de Dados",
                            icon: "person.badge.key",
                            iconColor: DesignSystem.Colors.secondary,
                            items: [
                                PrivacyItem(
                                    title: "Exportar Dados",
                                    description: "Exporte todas as suas análises",
                                    status: .available,
                                    icon: "square.and.arrow.up",
                                    action: {
                                        exportAllData()
                                    }
                                ),
                                PrivacyItem(
                                    title: "Excluir Todos os Dados",
                                    description: "Remove permanentemente todas as fotos e análises",
                                    status: .destructive,
                                    icon: "trash.fill",
                                    action: {
                                        showingDataDeletionAlert = true
                                    }
                                )
                            ]
                        )
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Privacy commitment
                    PrivacyCommitmentCard()
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.bottom, DesignSystem.Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Excluir Todos os Dados", isPresented: $showingDataDeletionAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Excluir Tudo", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("Esta ação não pode ser desfeita. Todas as suas fotos, análises e dados serão permanentemente removidos do dispositivo.")
        }
        .onChange(of: exportedFileURL) { _, url in
            guard isShareSheetPresented, let url else { return }
            shareSheetPresenter.present(items: [url])
            exportedFileURL = nil
            isShareSheetPresented = false
        }
        .onChange(of: pendingSuccessMessage) { _, message in
            guard let message else { return }
            notificationManager.show(
                title: "Tudo pronto",
                message: message,
                type: .success
            )
            pendingSuccessMessage = nil
        }
        .onChange(of: pendingErrorMessage) { _, message in
            guard let message else { return }
            notificationManager.show(
                title: "Algo deu errado",
                message: message,
                type: .error
            )
            pendingErrorMessage = nil
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

    private func exportAllData() {
        do {
            let photos = try photoRepository.fetchAll()

            guard !photos.isEmpty else {
                HapticManager.shared.notification(.warning)
                pendingErrorMessage = "Não há dados disponíveis para exportação."
                return
            }

            let fileURL = try analysisExportService.exportPhotos(photos, format: .pdf)
            exportedFileURL = fileURL
            isShareSheetPresented = true

            HapticManager.shared.notification(.success)
            pendingSuccessMessage = "Arquivo gerado com sucesso. Escolha onde deseja salvar ou compartilhar."
        } catch {
            exportedFileURL = nil
            isShareSheetPresented = false

            HapticManager.shared.notification(.error)
            pendingErrorMessage = error.localizedDescription
        }
    }

    private func deleteAllData() {
        Task { @MainActor in
            do {
                try photoRepository.deleteAll()
                try deleteAllExams()

                HapticManager.shared.notification(.success)
                pendingSuccessMessage = "Todos os dados foram removidos do dispositivo."
                dismiss()
            } catch {
                HapticManager.shared.notification(.error)
                pendingErrorMessage = "Não foi possível remover todos os dados: \(error.localizedDescription)"
            }
        }
    }

    private func deleteAllExams() throws {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Exam>()
        let exams = try context.fetch(descriptor)

        guard !exams.isEmpty else { return }

        for exam in exams {
            context.delete(exam)
        }

        try context.save()
    }
}

// MARK: - Privacy Models

struct PrivacyItem {
    let title: String
    let description: String
    let status: PrivacyStatus
    let icon: String
    let action: (() -> Void)?
    
    init(title: String, description: String, status: PrivacyStatus, icon: String, action: (() -> Void)? = nil) {
        self.title = title
        self.description = description
        self.status = status
        self.icon = icon
        self.action = action
    }
}

enum PrivacyStatus {
    case secure, controlled, required, optional, available, destructive
    
    var color: Color {
        switch self {
        case .secure: return DesignSystem.Colors.success
        case .controlled: return DesignSystem.Colors.warning
        case .required: return DesignSystem.Colors.error
        case .optional: return DesignSystem.Colors.info
        case .available: return DesignSystem.Colors.primary
        case .destructive: return DesignSystem.Colors.error
        }
    }
    
    var badge: String {
        switch self {
        case .secure: return "Seguro"
        case .controlled: return "Controlado"
        case .required: return "Obrigatório"
        case .optional: return "Opcional"
        case .available: return "Disponível"
        case .destructive: return "Atenção"
        }
    }
}

// MARK: - Privacy Section Card

struct PrivacySectionCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let items: [PrivacyItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Section header
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            
            // Items
            VStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    PrivacyItemRow(item: item)
                    
                    if index < items.count - 1 {
                        Divider()
                            .background(DesignSystem.Colors.borderLight)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.card)
        .designShadow(DesignSystem.Shadows.small)
    }
}

// MARK: - Privacy Item Row

struct PrivacyItemRow: View {
    let item: PrivacyItem
    
    var body: some View {
        Button(action: {
            if let action = item.action {
                HapticManager.shared.selection()
                action()
            }
        }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Icon
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(item.status.color)
                    .frame(width: 20)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(item.title)
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.text)
                        
                        Spacer()
                        
                        // Status badge
                        Text(item.status.badge)
                            .font(DesignSystem.Typography.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(item.status.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(item.status.color.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Text(item.description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                if item.action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(item.action == nil)
    }
}

// MARK: - Privacy Commitment Card

struct PrivacyCommitmentCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 24))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("Nosso Compromisso")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                CommitmentPoint(
                    text: "Seus dados médicos jamais serão vendidos ou compartilhados com terceiros"
                )
                
                CommitmentPoint(
                    text: "Você tem controle total sobre seus dados e pode excluí-los a qualquer momento"
                )
                
                CommitmentPoint(
                    text: "Utilizamos apenas os dados necessários para fornecer análises precisas"
                )
                
                CommitmentPoint(
                    text: "Seguimos as melhores práticas de segurança e privacidade da indústria"
                )
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.primaryLight)
        .cornerRadius(DesignSystem.CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .stroke(DesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CommitmentPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignSystem.Colors.success)
                .padding(.top, 1)
            
            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PrivacySettingsView()
}
