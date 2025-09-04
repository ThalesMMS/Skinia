import SwiftUI
import MessageUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFeedbackType: FeedbackType = .suggestion
    @State private var feedbackText = ""
    @State private var contactEmail = ""
    @State private var includeDeviceInfo = true
    @State private var showingMailComposer = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var canSendMail = MFMailComposeViewController.canSendMail()
    
    private let developerEmail = "thalesmmsradio@gmail.com"
    private let developerName = "Thales Matheus Mendonça Santos"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.secondary)
                        
                        Text("Enviar Feedback")
                            .font(DesignSystem.Typography.title1)
                            .foregroundColor(DesignSystem.Colors.text)
                        
                        Text("Sua opinião é muito importante para melhorarmos o Skinia")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, DesignSystem.Spacing.md)
                    
                    // Feedback form
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Feedback type selection
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Tipo de Feedback")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.text)
                            
                            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(FeedbackType.allCases, id: \.self) { type in
                                    FeedbackTypeCard(
                                        type: type,
                                        isSelected: selectedFeedbackType == type
                                    ) {
                                        selectedFeedbackType = type
                                        HapticManager.shared.selection()
                                    }
                                }
                            }
                        }
                        
                        // Feedback text
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Descrição")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.text)
                            
                            Text(selectedFeedbackType.placeholder)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            TextEditor(text: $feedbackText)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.text)
                                .frame(minHeight: 120)
                                .padding(DesignSystem.Spacing.md)
                                .background(DesignSystem.Colors.backgroundSecondary)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                )
                        }
                        
                        // Contact email (optional)
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Seu E-mail (Opcional)")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.text)
                            
                            Text("Para que possamos responder seu feedback")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            TextField("exemplo@email.com", text: $contactEmail)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.text)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(DesignSystem.Spacing.md)
                                .background(DesignSystem.Colors.backgroundSecondary)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                        .stroke(DesignSystem.Colors.border, lineWidth: 1)
                                )
                        }
                        
                        // Include device info toggle
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Toggle(isOn: $includeDeviceInfo) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Incluir Informações do Dispositivo")
                                        .font(DesignSystem.Typography.callout)
                                        .foregroundColor(DesignSystem.Colors.text)
                                    
                                    Text("Ajuda na resolução de problemas técnicos")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(DesignSystem.CornerRadius.card)
                        .designShadow(DesignSystem.Shadows.small)
                        
                        // Developer contact info
                        DeveloperContactCard(
                            name: developerName,
                            email: developerEmail
                        )
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enviar") {
                        sendFeedback()
                    }
                    .disabled(feedbackText.isEmpty)
                    .foregroundColor(feedbackText.isEmpty ? DesignSystem.Colors.textTertiary : DesignSystem.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showingMailComposer) {
            if canSendMail {
                MailComposeView(
                    subject: selectedFeedbackType.emailSubject,
                    recipients: [developerEmail],
                    messageBody: generateEmailBody(),
                    isHTML: false
                )
            }
        }
        .alert("Feedback", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func sendFeedback() {
        guard !feedbackText.isEmpty else { return }
        
        HapticManager.shared.impact(.medium)
        
        if canSendMail {
            showingMailComposer = true
        } else {
            // Fallback: show alert with instructions to send email manually
            alertMessage = """
            Para enviar seu feedback, copie as informações abaixo e envie um e-mail para:
            
            \(developerEmail)
            
            Assunto: \(selectedFeedbackType.emailSubject)
            
            \(generateEmailBody())
            """
            showingAlert = true
        }
    }
    
    private func generateEmailBody() -> String {
        var body = """
        Tipo de Feedback: \(selectedFeedbackType.title)
        
        Descrição:
        \(feedbackText)
        """
        
        if !contactEmail.isEmpty {
            body += "\n\nE-mail de Contato: \(contactEmail)"
        }
        
        if includeDeviceInfo {
            body += """
            
            
            --- Informações do Dispositivo ---
            App: Skinia v1.0.0
            Device: \(UIDevice.current.model)
            iOS: \(UIDevice.current.systemVersion)
            Identifier: \(UIDevice.current.identifierForVendor?.uuidString ?? "Unknown")
            """
        }
        
        return body
    }
}

// MARK: - Feedback Type

enum FeedbackType: String, CaseIterable {
    case bug = "bug"
    case suggestion = "suggestion"
    case question = "question"
    case praise = "praise"
    
    var title: String {
        switch self {
        case .bug: return "Reportar Bug"
        case .suggestion: return "Sugestão"
        case .question: return "Dúvida"
        case .praise: return "Elogio"
        }
    }
    
    var subtitle: String {
        switch self {
        case .bug: return "Algo não está funcionando?"
        case .suggestion: return "Ideia para melhorar o app"
        case .question: return "Precisa de ajuda?"
        case .praise: return "Gostou de algo específico?"
        }
    }
    
    var icon: String {
        switch self {
        case .bug: return "ladybug"
        case .suggestion: return "lightbulb"
        case .question: return "questionmark.circle"
        case .praise: return "heart"
        }
    }
    
    var color: Color {
        switch self {
        case .bug: return DesignSystem.Colors.error
        case .suggestion: return DesignSystem.Colors.warning
        case .question: return DesignSystem.Colors.info
        case .praise: return DesignSystem.Colors.success
        }
    }
    
    var placeholder: String {
        switch self {
        case .bug:
            return "Descreva o problema que encontrou, quando acontece e quais passos levaram ao erro."
        case .suggestion:
            return "Descreva sua ideia de melhoria ou nova funcionalidade para o Skinia."
        case .question:
            return "Faça sua pergunta sobre o uso do app ou funcionalidades."
        case .praise:
            return "Conte-nos o que mais gostou no Skinia!"
        }
    }
    
    var emailSubject: String {
        switch self {
        case .bug: return "[Skinia] Bug Report"
        case .suggestion: return "[Skinia] Sugestão"
        case .question: return "[Skinia] Dúvida"
        case .praise: return "[Skinia] Feedback Positivo"
        }
    }
}

// MARK: - Feedback Type Card

struct FeedbackTypeCard: View {
    let type: FeedbackType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: type.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(type.color)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.title)
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text(type.subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                isSelected ? DesignSystem.Colors.primaryLight : DesignSystem.Colors.surface
            )
            .cornerRadius(DesignSystem.CornerRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                    .stroke(
                        isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(DesignSystem.Animations.quick, value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Developer Contact Card

struct DeveloperContactCard: View {
    let name: String
    let email: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("Desenvolvedor")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.text)
                
                Text(email)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text("Respondo pessoalmente todos os feedbacks!")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .italic()
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

// MARK: - Mail Compose View

struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let recipients: [String]
    let messageBody: String
    let isHTML: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject(subject)
        composer.setToRecipients(recipients)
        composer.setMessageBody(messageBody, isHTML: isHTML)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if result == .sent {
                HapticManager.shared.notification(.success)
            }
            parent.dismiss()
        }
    }
}

#Preview {
    FeedbackView()
}