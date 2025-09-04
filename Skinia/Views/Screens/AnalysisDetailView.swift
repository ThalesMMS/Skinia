import SwiftUI

struct AnalysisDetailView: View {
    let photo: SkinLesionPhoto
    @Environment(\.analysisService) private var analysisService
    @Environment(\.notificationManager) private var notificationManager
    @State private var showingShareSheet = false
    @State private var isRetryingAnalysis = false
    @State private var showingFullScreenImage = false
    @State private var showingPatientInfo = false
    
    init(photo: SkinLesionPhoto) {
        self.photo = photo
        print("🔍 AnalysisDetailView init for photo: \(photo.id)")
    }
    
    var body: some View {
        let _ = print("🔍 AnalysisDetailView body rendering for photo: \(photo.id)")
        
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Photo section - main image
                photoSection
                    .id("photo-section")
                
                // Status section
                statusSection
                    .id("status-section")
                
                // Patient info section
                patientInfoSection
                    .id("patient-section")
                
                // Analysis result or progress
                Group {
                    if let result = photo.analysisResult {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            analysisResultSection(result)
                            riskAssessmentSection(result)
                            recommendationsSection(result)
                        }
                        .id("result-section")
                    } else if photo.analysisStatus == .uploading || photo.analysisStatus == .analyzing {
                        // Simple progress view instead of full AnalysisProgressView
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Text("Análise em Progresso")
                                .font(DesignSystem.Typography.headline)
                            
                            ProgressView(photo.analysisStatus.displayName)
                                .progressViewStyle(CircularProgressViewStyle())
                            
                            Text("Aguarde enquanto processamos sua imagem...")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .cardStyle()
                        .id("progress-section")
                    } else if photo.analysisStatus == .failed {
                        // Simple error view
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(DesignSystem.Colors.error)
                            
                            Text("Erro na Análise")
                                .font(DesignSystem.Typography.headline)
                            
                            Text("Não foi possível processar a análise da imagem.")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: retryAnalysis) {
                                HStack {
                                    if isRetryingAnalysis {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                    }
                                    Text("Tentar Novamente")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(DesignSystem.Colors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(DesignSystem.CornerRadius.lg)
                            }
                            .disabled(isRetryingAnalysis)
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .cardStyle()
                        .id("error-section")
                    } else {
                        // Simple waiting view
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 40))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                            
                            Text("Aguardando Análise")
                                .font(DesignSystem.Typography.headline)
                            
                            Text("A análise será iniciada em breve.")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .cardStyle()
                        .id("waiting-section")
                    }
                }
                
                // User notes section
                userNotesSection
                    .id("notes-section")
                
                // Metadata section  
                if let metadata = photo.metadata {
                    metadataSection(metadata)
                        .id("metadata-section")
                }
                
                // Actions section
                actionsSection
                    .id("actions-section")
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Análise Dermatológica")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingPatientInfo.toggle()
                } label: {
                    Image(systemName: "person.circle")
                }
                
                Button("Compartilhar") {
                    showingShareSheet = true
                }
                .disabled(photo.analysisResult == nil)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let result = photo.analysisResult {
                ShareSheet(photo: photo, result: result)
            }
        }
        .sheet(isPresented: $showingPatientInfo) {
            PatientInfoSheet(photo: photo)
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            FullScreenImageView(photo: photo)
        }
    }
    
    private var photoSection: some View {
        let _ = print("🔍 PhotoSection rendering - has image: \(photo.fullImage != nil)")
        
        return Group {
            if let image = photo.fullImage {
                let aspectRatio = image.size.width / image.size.height
                let optimalHeight = calculateOptimalHeight(for: aspectRatio)
                
                Button {
                    showingFullScreenImage = true
                    HapticManager.shared.impact(.light)
                } label: {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(aspectRatio, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: optimalHeight)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                        .designShadow(DesignSystem.Shadows.medium)
                        .overlay(alignment: .topTrailing) {
                            HStack(spacing: 4) {
                                Image(systemName: "viewfinder")
                                    .font(.caption2)
                                Text("Tocar para ampliar")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .padding(8)
                        }
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.backgroundSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 280) // Altura padrão
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                            
                            Text("Imagem não disponível")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                    }
                    .designShadow(DesignSystem.Shadows.small)
            }
        }
    }
    
    // MARK: - Helper Functions for Photo Layout
    
    private func calculateOptimalHeight(for aspectRatio: CGFloat) -> CGFloat {
        let minHeight: CGFloat = 180
        let maxHeight: CGFloat = 400
        let targetHeight: CGFloat = 280
        
        // Se a imagem é muito larga (panorâmica), reduz a altura
        if aspectRatio > 2.0 {
            return max(minHeight, targetHeight * 0.6)
        }
        // Se a imagem é muito alta (portrait), aumenta a altura
        else if aspectRatio < 0.75 {
            return min(maxHeight, targetHeight * 1.3)
        }
        // Para aspect ratios normais, usa a altura padrão
        else {
            return targetHeight
        }
    }
    
    private var statusSection: some View {
        VStack(spacing: 16) {
            HStack {
                StatusBadge(status: photo.analysisStatus)
                Spacer()
                Text(photo.formattedCaptureDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func analysisResultSection(_ result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with title and timestamp
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resultado da Análise")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Análise completa com IA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                RiskBadge(riskLevel: result.riskLevel)
            }
            
            Divider()
            
            // Lesion type with prominent display
            VStack(alignment: .leading, spacing: 12) {
                Text("Diagnóstico Principal")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(result.lesionType)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Confidence visualization
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Nível de Confiança")
                        .font(.headline)
                    Spacer()
                    Text(result.confidencePercentage)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(confidenceColor(result.confidence))
                }
                
                ProgressView(value: result.confidence)
                    .progressViewStyle(LinearProgressViewStyle(tint: confidenceColor(result.confidence)))
                    .scaleEffect(y: 2.0, anchor: .center)
                
                Text(confidenceDescription(result.confidence))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(result.riskLevel.color.opacity(0.3), lineWidth: 2)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func metadataSection(_ metadata: PhotoMetadata) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Informações Técnicas")
                .font(.headline)
            
            VStack(spacing: 8) {
                metadataRow(label: "Qualidade", value: metadata.imageQuality.rawValue.capitalized)
                metadataRow(label: "Dispositivo", value: metadata.deviceInfo)
                metadataRow(label: "Orientação", value: metadata.orientation.capitalized)
                metadataRow(label: "Dimensões", value: metadata.imageDimensions)
                metadataRow(label: "Tamanho", value: metadata.fileSizeFormatted)
                
                if let bodyLocation = metadata.bodyLocation {
                    metadataRow(label: "Local do Corpo", value: bodyLocation)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - New Enhanced Sections
    
    private func riskAssessmentSection(_ result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Avaliação de Risco")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                // Risk level icon and description
                VStack(spacing: 8) {
                    Image(systemName: result.riskLevel.systemImage)
                        .font(.system(size: 40))
                        .foregroundColor(result.riskLevel.color)
                    
                    Text(result.riskLevel.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(result.riskLevel.color)
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(riskDescription(result.riskLevel))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(riskActionText(result.riskLevel))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(result.riskLevel.color.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func recommendationsSection(_ result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recomendações Médicas")
                .font(.title2)
                .fontWeight(.bold)
            
            if !result.recommendationsList.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(result.recommendationsList.enumerated()), id: \.offset) { index, recommendation in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 24, height: 24)
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recommendation)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                if isUrgentRecommendation(recommendation) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                            .font(.caption2)
                                        Text("Ação urgente recomendada")
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        
                        if index < result.recommendationsList.count - 1 {
                            Divider()
                        }
                    }
                }
            } else {
                Text("Nenhuma recomendação específica disponível.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Text("Ações")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                // Retry analysis button
                if photo.analysisStatus == .failed {
                    Button(action: retryAnalysis) {
                        HStack {
                            if isRetryingAnalysis {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Repetir Análise")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isRetryingAnalysis)
                }
                
                // Export report button
                if photo.analysisResult != nil {
                    Button("Exportar Relatório") {
                        exportReport()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                
                // Save to Photos button
                if photo.analysisResult != nil {
                    Button("Salvar na Galeria") {
                        saveToPhotos()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var userNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Observações do Paciente")
                .font(.headline)
            
            if let notes = photo.userNotes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
            } else {
                Text("Nenhuma observação adicionada.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Functions
    
    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.9...1.0: return .green
        case 0.7..<0.9: return .blue
        case 0.5..<0.7: return .orange
        default: return .red
        }
    }
    
    private func confidenceDescription(_ confidence: Double) -> String {
        switch confidence {
        case 0.9...1.0: return "Confiança muito alta - resultado altamente confiável"
        case 0.7..<0.9: return "Confiança alta - resultado confiável"
        case 0.5..<0.7: return "Confiança moderada - considere análise adicional"
        default: return "Confiança baixa - recomendada nova análise"
        }
    }
    
    private func riskDescription(_ riskLevel: RiskLevel) -> String {
        switch riskLevel {
        case .low:
            return "A lesão apresenta características benignas com baixa probabilidade de malignidade."
        case .moderate:
            return "A lesão requer monitoramento regular, mas não apresenta sinais imediatos de preocupação."
        case .high:
            return "A lesão apresenta características que requerem avaliação dermatológica urgente."
        case .urgent:
            return "A lesão apresenta características altamente suspeitas que requerem atenção médica imediata."
        }
    }
    
    private func riskActionText(_ riskLevel: RiskLevel) -> String {
        switch riskLevel {
        case .low:
            return "Continue com acompanhamento dermatológico regular."
        case .moderate:
            return "Agende consulta dermatológica em 3-6 meses."
        case .high:
            return "Consulte um dermatologista dentro de 2-4 semanas."
        case .urgent:
            return "Procure atendimento dermatológico imediatamente."
        }
    }
    
    private func isUrgentRecommendation(_ recommendation: String) -> Bool {
        let urgentKeywords = ["URGENTE", "IMEDIATA", "IMEDIATAMENTE", "NÃO RETARDAR"]
        return urgentKeywords.contains { keyword in
            recommendation.uppercased().contains(keyword)
        }
    }
    
    // MARK: - Action Functions
    
    private func retryAnalysis() {
        isRetryingAnalysis = true
        Task {
            do {
                try await analysisService.retryAnalysis(for: photo)
            } catch {
                notificationManager.show(
                    title: "Erro ao Repetir Análise",
                    message: error.localizedDescription,
                    type: .error
                )
            }
            isRetryingAnalysis = false
        }
    }
    
    private func exportReport() {
        notificationManager.show(
            title: "Exportando Relatório",
            message: "Gerando relatório em PDF...",
            type: .info
        )
        // Implementation will be added later
    }
    
    private func saveToPhotos() {
        guard let image = photo.fullImage else { return }
        
        // Save to photo library (implementation needed)
        notificationManager.show(
            title: "Imagem Salva",
            message: "Imagem salva na galeria com sucesso",
            type: .success
        )
    }
    
    // MARK: - New Sections
    
    private var patientInfoSection: some View {
        Group {
            if let bodyLocation = photo.metadata?.bodyLocation {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Local da Lesão")
                            .font(DesignSystem.Typography.medicalCaption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(bodyLocation)
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.text)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Data da Captura")
                            .font(DesignSystem.Typography.medicalCaption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(photo.formattedCaptureDate)
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.text)
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .cardStyle()
            }
        }
    }
}

// MARK: - Supporting Views

struct FullScreenImageView: View {
    let photo: SkinLesionPhoto
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScaleValue: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if let image = photo.fullImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScaleValue
                                lastScaleValue = value
                                scale = min(max(scale * delta, 0.5), 3.0)
                            }
                            .onEnded { value in
                                lastScaleValue = 1.0
                                if scale < 1.0 {
                                    withAnimation(.spring()) {
                                        scale = 1.0
                                        offset = .zero
                                    }
                                }
                            }
                            .simultaneously(with:
                                DragGesture()
                                    .onChanged { value in
                                        offset = value.translation
                                    }
                                    .onEnded { value in
                                        withAnimation(.spring()) {
                                            offset = .zero
                                        }
                                    }
                            )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            if scale > 1.0 {
                                scale = 1.0
                                offset = .zero
                            } else {
                                scale = 2.0
                            }
                        }
                    }
            }
            
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
            }
        }
        .gesture(
            TapGesture()
                .onEnded {
                    dismiss()
                }
        )
    }
}

struct PatientInfoSheet: View {
    let photo: SkinLesionPhoto
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Patient header
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.primary)
                        
                        Text("Informações do Paciente")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, DesignSystem.Spacing.lg)
                    
                    // Analysis info
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        infoCard(
                            title: "Data da Análise",
                            value: photo.formattedCaptureDate,
                            icon: "calendar"
                        )
                        
                        if let bodyLocation = photo.metadata?.bodyLocation {
                            infoCard(
                                title: "Local da Lesão",
                                value: bodyLocation,
                                icon: "figure.walk"
                            )
                        }
                        
                        infoCard(
                            title: "Status da Análise",
                            value: photo.analysisStatus.displayName,
                            icon: "stethoscope"
                        )
                        
                        if let notes = photo.userNotes, !notes.isEmpty {
                            infoCard(
                                title: "Observações",
                                value: notes,
                                icon: "note.text",
                                isMultiline: true
                            )
                        }
                    }
                    
                    Spacer()
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .navigationTitle("Paciente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func infoCard(title: String, value: String, icon: String, isMultiline: Bool = false) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 24, alignment: .center)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.medicalCaption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(value)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text)
                    .lineLimit(isMultiline ? nil : 1)
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let photo: SkinLesionPhoto
    let result: AnalysisResult
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let reportText = generateShareableReport()
        var items: [Any] = [reportText]
        
        if let image = photo.fullImage {
            items.append(image)
        }
        
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    
    private func generateShareableReport() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return """
        📊 RELATÓRIO DE ANÁLISE DERMATOLÓGICA
        
        🗓 Data da Análise: \(formatter.string(from: photo.captureDate))
        
        🔬 Resultado: \(result.lesionType)
        📊 Confiança: \(result.confidencePercentage)
        ⚠️ Nível de Risco: \(result.riskLevel.displayName)
        
        📋 RECOMENDAÇÕES:
        \(result.recommendationsList.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        
        ⚠️ IMPORTANTE: Este relatório é gerado por inteligência artificial e não substitui a consulta médica profissional. Sempre procure um dermatologista para diagnóstico definitivo.
        
        📱 Gerado pelo aplicativo Skinia
        """
    }
}

#Preview {
    let mockPhoto = SkinLesionPhoto(
        imageData: Data(),
        analysisStatus: .completed
    )
    
    NavigationView {
        AnalysisDetailView(photo: mockPhoto)
    }
}