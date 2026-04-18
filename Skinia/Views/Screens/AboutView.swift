import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let appVersion = "1.0.0"
    private let buildNumber = "1"
    private let releaseDate = "2025"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // App Header
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // App Icon and Name
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "cross.case.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(DesignSystem.Colors.primary)
                                .background(
                                    Circle()
                                        .fill(DesignSystem.Colors.primaryLight)
                                        .frame(width: 100, height: 100)
                                )
                            
                            VStack(spacing: 4) {
                                Text("Skinia")
                                    .font(DesignSystem.Typography.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(DesignSystem.Colors.text)
                                
                                Text("Análise Inteligente de Lesões de Pele")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // Version Info
                        VStack(spacing: 4) {
                            Text("Versão \(appVersion) (Build \(buildNumber))")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Text("© \(releaseDate) Thales Matheus Mendonça Santos")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // About Sections
                    VStack(spacing: DesignSystem.Spacing.md) {
                        AboutSectionCard(
                            title: "Nossa Missão",
                            icon: "heart.text.square",
                            iconColor: DesignSystem.Colors.error,
                            content: "Democratizar o acesso à análise preliminar de lesões de pele através da inteligência artificial, ajudando pessoas a identificar precocemente possíveis problemas dermatológicos e incentivando o acompanhamento médico adequado."
                        )
                        
                        AboutSectionCard(
                            title: "Como Funciona",
                            icon: "brain.head.profile",
                            iconColor: DesignSystem.Colors.primary,
                            content: "Utilizamos algoritmos de deep learning treinados com milhares de imagens dermatológicas para analisar lesões de pele e fornecer uma avaliação preliminar do risco. Nossa IA considera fatores como formato, cor, textura e simetria das lesões."
                        )
                        
                        AboutSectionCard(
                            title: "Importante",
                            icon: "exclamationmark.triangle",
                            iconColor: DesignSystem.Colors.warning,
                            content: "Este aplicativo não substitui a consulta médica. Sempre procure um dermatologista para diagnóstico, tratamento e acompanhamento adequados. Use o Skinia apenas como ferramenta de apoio inicial."
                        )
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Technology Stack
                    TechnologyStackCard()
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Developer Info
                    DeveloperInfoCard()
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Acknowledgments
                    AcknowledgmentsCard()
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // Legal Links
                    LegalLinksCard()
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
    }
}

// MARK: - About Section Card

struct AboutSectionCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            
            Text(content)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineSpacing(4)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.card)
        .designShadow(DesignSystem.Shadows.small)
    }
}

// MARK: - Technology Stack Card

struct TechnologyStackCard: View {
    private let technologies = [
        ("Swift", "swift", DesignSystem.Colors.secondary),
        ("SwiftUI", "paintbrush.pointed", DesignSystem.Colors.primary),
        ("Core ML", "brain", DesignSystem.Colors.success),
        ("SwiftData", "internaldrive", DesignSystem.Colors.info),
        ("Vision Framework", "eye", DesignSystem.Colors.warning)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("Tecnologias")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            
            Text("Construído com as mais modernas tecnologias da Apple para garantir performance, segurança e privacidade.")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineSpacing(2)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignSystem.Spacing.sm) {
                ForEach(Array(technologies.enumerated()), id: \.offset) { index, tech in
                    TechnologyItem(name: tech.0, icon: tech.1, color: tech.2)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.card)
        .designShadow(DesignSystem.Shadows.small)
    }
}

struct TechnologyItem: View {
    let name: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(name)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.text)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Developer Info Card

struct DeveloperInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "person.circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("Desenvolvedor")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Thales Matheus Mendonça Santos")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.text)
                        
                        Text("Desenvolvedor iOS & Especialista em IA")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                
                Text("Especializado em desenvolvimento iOS e aplicações de machine learning para saúde. Comprometido em criar tecnologias que tornam o cuidado médico mais acessível.")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .lineSpacing(2)
                
                HStack(spacing: DesignSystem.Spacing.md) {
                    ContactButton(
                        icon: "envelope",
                        text: "E-mail",
                        action: {
                            if let emailURL = URL(string: "mailto:thalesmmsradio@gmail.com?subject=Skinia%20App") {
                                UIApplication.shared.open(emailURL)
                            }
                        }
                    )
                    
                    Spacer()
                }
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

struct ContactButton: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text(text)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(DesignSystem.Colors.primary.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Acknowledgments Card

struct AcknowledgmentsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "heart.circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.error)
                
                Text("Agradecimentos")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                AcknowledgmentItem(
                    title: "Comunidade Médica",
                    description: "Dermatologistas que contribuíram com conhecimento e validação científica"
                )
                
                AcknowledgmentItem(
                    title: "Datasets Públicos",
                    description: "Pesquisadores que disponibilizaram datasets dermatológicos para pesquisa"
                )
                
                AcknowledgmentItem(
                    title: "Beta Testers",
                    description: "Usuários que testaram o app e forneceram feedback valioso"
                )
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.card)
        .designShadow(DesignSystem.Shadows.small)
    }
}

struct AcknowledgmentItem: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(DesignSystem.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.text)
            
            Text(description)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

// MARK: - Legal Links Card

struct LegalLinksCard: View {
    private let legalDocumentOpener: LegalDocumentOpening

    init(legalDocumentOpener: LegalDocumentOpening = LegalDocumentOpener.shared) {
        self.legalDocumentOpener = legalDocumentOpener
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "doc.text")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text("Legal Information")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
            }

            VStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(LegalDocument.allCases) { document in
                    LegalLinkItem(title: document.localizedTitle) {
                        legalDocumentOpener.open(document)
                    }
                }
            }

            Text("This app does not store personal data on external servers and fully respects your privacy.")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textTertiary)
                .padding(.top, 4)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.card)
    }
}

struct LegalLinkItem: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AboutView()
}

#if DEBUG
private struct LegalLinksCardPreviewContainer: View {
    @StateObject private var legalOpener = PreviewLegalDocumentOpener()

    var body: some View {
        LegalLinksCard(legalDocumentOpener: legalOpener)
            .padding()
            .background(DesignSystem.Colors.surface)
            .previewLayout(.sizeThatFits)
            .overlay(alignment: .bottom) {
                if let document = legalOpener.lastOpenedDocument {
                    PreviewLegalDocumentBanner(title: document.localizedTitle)
                        .padding(.bottom)
                }
            }
            .overlay(alignment: .top) {
                PreviewInstructionLabel(text: "Tap any link to verify the simulated action.")
            }
            .animation(.easeInOut, value: legalOpener.lastOpenedDocument)
    }
}

#Preview("Legal Links Card") {
    LegalLinksCardPreviewContainer()
}
#endif