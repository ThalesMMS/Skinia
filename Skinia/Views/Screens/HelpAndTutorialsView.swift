import SwiftUI

struct HelpAndTutorialsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTutorial: Tutorial? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.primary)
                        
                        Text("Ajuda e Tutoriais")
                            .font(DesignSystem.Typography.title1)
                            .foregroundColor(DesignSystem.Colors.text)
                        
                        Text("Aprenda a usar o Skinia de forma segura e eficiente para análise de lesões de pele")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                    
                    // Tutorial Cards
                    LazyVStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(Tutorial.allTutorials) { tutorial in
                            TutorialCard(tutorial: tutorial) {
                                selectedTutorial = tutorial
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    // FAQ Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Perguntas Frequentes")
                            .font(DesignSystem.Typography.title2)
                            .foregroundColor(DesignSystem.Colors.text)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        LazyVStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(FAQ.allFAQs) { faq in
                                FAQCard(faq: faq)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                    
                    // Emergency Warning
                    EmergencyWarningCard()
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
        .sheet(item: $selectedTutorial) { tutorial in
            TutorialDetailView(tutorial: tutorial)
        }
    }
}

// MARK: - Tutorial Model

struct Tutorial: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let steps: [TutorialStep]
    let category: Category
    
    static func == (lhs: Tutorial, rhs: Tutorial) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum Category: Hashable {
        case basicUsage, photography, analysis, safety
        
        var name: String {
            switch self {
            case .basicUsage: return "Uso Básico"
            case .photography: return "Fotografia"
            case .analysis: return "Análise"
            case .safety: return "Segurança"
            }
        }
    }
    
    static let allTutorials: [Tutorial] = [
        Tutorial(
            title: "Primeiros Passos",
            subtitle: "Como começar a usar o Skinia",
            icon: "play.circle",
            iconColor: DesignSystem.Colors.primary,
            steps: [
                TutorialStep(title: "Bem-vindo ao Skinia", description: "O Skinia é um aplicativo para análise de lesões de pele que utiliza inteligência artificial para fornecer informações preliminares sobre possíveis condições dermatológicas."),
                TutorialStep(title: "Importante: Não Substitui Consulta Médica", description: "Este app é apenas uma ferramenta de apoio. Sempre consulte um dermatologista para diagnóstico e tratamento adequados."),
                TutorialStep(title: "Permissões Necessárias", description: "O app precisa de acesso à câmera para capturar fotos e às notificações para informar sobre resultados de análises."),
                TutorialStep(title: "Navegação Principal", description: "Use a aba 'Análises' para ver histórico, 'Nova Foto' para capturar imagens e 'Configurações' para personalizar o app.")
            ],
            category: .basicUsage
        ),
        
        Tutorial(
            title: "Como Tirar Boas Fotos",
            subtitle: "Técnicas para fotografias de qualidade",
            icon: "camera.fill",
            iconColor: DesignSystem.Colors.secondary,
            steps: [
                TutorialStep(title: "Iluminação Adequada", description: "Use luz natural ou luz branca uniforme. Evite sombras, reflexos ou luz muito direta sobre a lesão."),
                TutorialStep(title: "Distância e Enquadramento", description: "Mantenha a câmera a 10-15cm da lesão. A lesão deve ocupar cerca de 60-80% do quadro para melhor análise."),
                TutorialStep(title: "Foco e Estabilidade", description: "Toque na tela para focar na lesão. Mantenha o dispositivo estável ou apoie em uma superfície firme."),
                TutorialStep(title: "Ângulo Perpendicular", description: "Mantenha a câmera perpendicular à pele. Evite ângulos oblíquos que possam distorcer a lesão."),
                TutorialStep(title: "Múltiplas Fotos", description: "Se necessário, tire várias fotos da mesma lesão em ângulos ligeiramente diferentes para melhor análise.")
            ],
            category: .photography
        ),
        
        Tutorial(
            title: "Entendendo os Resultados",
            subtitle: "Como interpretar as análises",
            icon: "doc.text.magnifyingglass",
            iconColor: DesignSystem.Colors.success,
            steps: [
                TutorialStep(title: "Níveis de Risco", description: "As análises são classificadas em: Baixo (verde), Moderado (amarelo), Alto (laranja) e Urgente (vermelho)."),
                TutorialStep(title: "Confiança da Análise", description: "O percentual indica o nível de confiança da IA. Valores baixos podem indicar necessidade de nova foto ou consulta médica."),
                TutorialStep(title: "Recomendações", description: "Cada resultado inclui recomendações específicas baseadas na análise. Sempre siga as orientações médicas fornecidas."),
                TutorialStep(title: "Histórico de Análises", description: "Mantenha um histórico das suas análises para acompanhar mudanças ao longo do tempo."),
                TutorialStep(title: "Quando Procurar um Médico", description: "Procure um dermatologista imediatamente se o resultado for de alto risco ou urgente, ou se notar mudanças na lesão.")
            ],
            category: .analysis
        ),
        
        Tutorial(
            title: "Segurança e Privacidade",
            subtitle: "Como seus dados são protegidos",
            icon: "lock.shield",
            iconColor: DesignSystem.Colors.info,
            steps: [
                TutorialStep(title: "Armazenamento Local", description: "Suas fotos são armazenadas localmente no dispositivo e apenas enviadas para análise quando você autorizar."),
                TutorialStep(title: "Criptografia", description: "Todas as comunicações com nossos servidores são criptografadas usando protocolos de segurança avançados."),
                TutorialStep(title: "Exclusão de Dados", description: "Você pode excluir suas fotos e análises a qualquer momento através da tela de detalhes."),
                TutorialStep(title: "Não Compartilhamento", description: "Seus dados médicos nunca são compartilhados com terceiros sem seu consentimento explícito."),
                TutorialStep(title: "Controle de Permissões", description: "Você pode revogar permissões nas configurações do iOS a qualquer momento.")
            ],
            category: .safety
        )
    ]
}

struct TutorialStep: Hashable {
    let title: String
    let description: String
}

// MARK: - FAQ Model

struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    
    static let allFAQs: [FAQ] = [
        FAQ(
            question: "O Skinia substitui a consulta com um dermatologista?",
            answer: "Não. O Skinia é uma ferramenta de apoio que oferece análise preliminar usando IA. Sempre consulte um dermatologista para diagnóstico, tratamento e acompanhamento adequados."
        ),
        FAQ(
            question: "Quão precisa é a análise por IA?",
            answer: "Nossa IA tem alta precisão, mas não é 100% infalível. Fatores como qualidade da foto, tipo de lesão e condições de iluminação podem afetar os resultados. Use sempre como referência inicial."
        ),
        FAQ(
            question: "Minhas fotos são enviadas para algum servidor?",
            answer: "As fotos são enviadas apenas para análise e são processadas em servidores seguros e criptografados. Após a análise, as imagens não são armazenadas permanentemente."
        ),
        FAQ(
            question: "O que fazer se o resultado for 'Alto Risco' ou 'Urgente'?",
            answer: "Procure um dermatologista imediatamente. Resultados de alto risco indicam necessidade de avaliação médica urgente para descartar condições graves."
        ),
        FAQ(
            question: "Posso analisar lesões em qualquer parte do corpo?",
            answer: "O app é otimizado para lesões visíveis na pele. Para áreas difíceis de fotografar ou lesões em mucosas, consulte diretamente um médico."
        ),
        FAQ(
            question: "Com que frequência devo monitorar minhas lesões?",
            answer: "Depende da recomendação médica. Geralmente, lesões suspeitas devem ser monitoradas mensalmente, mas sempre siga orientações do seu dermatologista."
        )
    ]
}

// MARK: - Tutorial Card

struct TutorialCard: View {
    let tutorial: Tutorial
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Icon
                Image(systemName: tutorial.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(tutorial.iconColor)
                    .frame(width: 40, height: 40)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(tutorial.title)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text(tutorial.subtitle)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(tutorial.category.name)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(tutorial.iconColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.card)
            .designShadow(DesignSystem.Shadows.small)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - FAQ Card

struct FAQCard: View {
    let faq: FAQ
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Button(action: {
                withAnimation(DesignSystem.Animations.standard) {
                    isExpanded.toggle()
                }
                HapticManager.shared.selection()
            }) {
                HStack {
                    Text(faq.question)
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.text)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(faq.answer)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.card)
        .designShadow(DesignSystem.Shadows.small)
    }
}

// MARK: - Emergency Warning Card

struct EmergencyWarningCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.error)
                
                Text("Emergência Médica")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.error)
            }
            
            Text("Se você notar mudanças repentinas em uma lesão (sangramento, crescimento rápido, dor intensa, mudança de cor), procure atendimento médico imediato. Não espere pela análise do app.")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.errorLight)
        .cornerRadius(DesignSystem.CornerRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card)
                .stroke(DesignSystem.Colors.error.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    HelpAndTutorialsView()
}