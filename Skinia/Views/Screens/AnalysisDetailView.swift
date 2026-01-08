import Photos
import SwiftUI
import UIKit

struct AnalysisDetailView: View {
    @State private var viewModel: AnalysisDetailViewModel
    @Environment(\.notificationManager) private var notificationManager

    private let analysisExportService: any AnalysisExportServiceProtocol
    private let shareSheetPresenter: ShareSheetPresenter
    @State private var showingFullScreenImage = false
    @State private var showingPatientInfo = false

    init(
        photo: SkinLesionPhoto,
        photoRepository: any PhotoRepositoryProtocol,
        analysisService: any AnalysisServiceProtocol,
        analysisExportService: any AnalysisExportServiceProtocol,
        shareSheetPresenter: ShareSheetPresenter
    ) {
        self.analysisExportService = analysisExportService
        self.shareSheetPresenter = shareSheetPresenter
        _viewModel = State(
            wrappedValue: AnalysisDetailViewModel(
                photo: photo,
                photoRepository: photoRepository,
                analysisService: analysisService
            )
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                AnalysisPhotoSectionView(
                    photo: viewModel.photo,
                    showingFullScreenImage: $showingFullScreenImage
                )
                .id("photo-section")

                AnalysisStatusSectionView(
                    status: viewModel.photo.analysisStatus,
                    captureDate: viewModel.photo.formattedCaptureDate,
                    description: viewModel.statusDescription
                )
                .id("status-section")

                AnalysisPatientInfoSectionView(photo: viewModel.photo)
                    .id("patient-section")

                Group {
                    if let result = viewModel.photo.analysisResult {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            AnalysisResultSectionView(result: result)
                            AnalysisRiskAssessmentSectionView(riskLevel: result.riskLevel)
                            AnalysisRecommendationsSectionView(result: result)
                        }
                        .id("result-section")
                    } else if viewModel.photo.analysisStatus == .uploading || viewModel.photo.analysisStatus == .analyzing {
                        AnalysisInProgressView(status: viewModel.photo.analysisStatus)
                            .id("progress-section")
                    } else if viewModel.photo.analysisStatus == .failed {
                        AnalysisErrorView(
                            isRetrying: viewModel.isRetrying,
                            canRetry: viewModel.canRetryAnalysis,
                            retryAction: retryAnalysis
                        )
                        .id("error-section")
                    } else {
                        AnalysisWaitingView()
                            .id("waiting-section")
                    }
                }

                AnalysisUserNotesSectionView(notes: viewModel.photo.userNotes)
                    .id("notes-section")

                if let metadata = viewModel.photo.metadata {
                    AnalysisMetadataSectionView(metadata: metadata)
                        .id("metadata-section")
                }

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
                    exportReport()
                }
                .disabled(viewModel.photo.analysisResult == nil)
            }
        }
        .sheet(isPresented: $showingPatientInfo) {
            PatientInfoSheet(photo: viewModel.photo)
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            FullScreenImageView(photo: viewModel.photo)
        }
    }

    private var actionsSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("Ações")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: DesignSystem.Spacing.xs) {
                if viewModel.photo.analysisStatus == .failed {
                    Button(action: retryAnalysis) {
                        HStack {
                            if viewModel.isRetrying {
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
                        .foregroundColor(DesignSystem.Colors.surface)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isRetrying || !viewModel.canRetryAnalysis)
                }

                if viewModel.photo.analysisResult != nil {
                    Button("Exportar Relatório") {
                        exportReport()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .foregroundColor(.primary)
                    .cornerRadius(12)

                    Button("Salvar na Galeria") {
                        saveToPhotos()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignSystem.Colors.backgroundSecondary)
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.md)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(16)
    }

    private func retryAnalysis() {
        guard viewModel.canRetryAnalysis else { return }

        Task {
            await viewModel.retryAnalysis()

            if let message = viewModel.errorMessage {
                notificationManager.show(
                    title: "Erro ao Repetir Análise",
                    message: message,
                    type: .error
                )
            }
        }
    }

    private func exportReport() {
        do {
            let fileURL = try viewModel.exportReport(using: analysisExportService)
            shareSheetPresenter.present(items: [fileURL])
            showNotification(
                title: "Relatório Gerado",
                message: "Selecione onde compartilhar o PDF.",
                type: .success
            )
        } catch {
            let message: String
            if let localizedError = error as? LocalizedError,
               let description = localizedError.errorDescription {
                message = description
            } else {
                message = error.localizedDescription
            }

            showNotification(
                title: "Erro ao Exportar",
                message: message,
                type: .error
            )
        }
    }

    private func saveToPhotos() {
        guard let image = viewModel.photo.fullImage else {
            showNotification(
                title: "Erro ao Salvar",
                message: "Não foi possível acessar a imagem para salvar.",
                type: .error
            )
            return
        }

        let status = currentAuthorizationStatus()

        switch status {
        case .authorized, .limited:
            saveImageToPhotoLibrary(image)
        case .notDetermined:
            requestPhotoLibraryAccess { authorization in
                switch authorization {
                case .authorized, .limited:
                    saveImageToPhotoLibrary(image)
                case .denied, .restricted:
                    showNotification(
                        title: "Permissão Necessária",
                        message: "Autorize o acesso às fotos nas configurações para salvar a imagem.",
                        type: .error
                    )
                case .notDetermined:
                    break
                @unknown default:
                    showNotification(
                        title: "Erro ao Salvar",
                        message: "Não foi possível acessar a biblioteca de fotos.",
                        type: .error
                    )
                }
            }
        case .denied, .restricted:
            showNotification(
                title: "Permissão Necessária",
                message: "Autorize o acesso às fotos nas configurações para salvar a imagem.",
                type: .error
            )
        @unknown default:
            showNotification(
                title: "Erro ao Salvar",
                message: "Não foi possível acessar a biblioteca de fotos.",
                type: .error
            )
        }
    }

    private func currentAuthorizationStatus() -> PHAuthorizationStatus {
        if #available(iOS 14, *) {
            return PHPhotoLibrary.authorizationStatus(for: .addOnly)
        } else {
            return PHPhotoLibrary.authorizationStatus()
        }
    }

    private func requestPhotoLibraryAccess(_ completion: @escaping (PHAuthorizationStatus) -> Void) {
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                DispatchQueue.main.async {
                    completion(status)
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    completion(status)
                }
            }
        }
    }

    private func saveImageToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    showNotification(
                        title: "Imagem Salva",
                        message: "Imagem salva na galeria com sucesso.",
                        type: .success
                    )
                } else {
                    let message = error?.localizedDescription ?? "Não foi possível salvar a imagem."
                    showNotification(
                        title: "Erro ao Salvar",
                        message: message,
                        type: .error
                    )
                }
            }
        }
    }

    private func showNotification(
        title: String,
        message: String?,
        type: StatusNotification.NotificationType
    ) {
        Task { @MainActor in
            notificationManager.show(title: title, message: message, type: type)
        }
    }
}

private struct AnalysisInProgressView: View {
    let status: AnalysisStatus

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Text("Análise em Progresso")
                .font(DesignSystem.Typography.headline)

            ProgressView(status.displayName)
                .progressViewStyle(CircularProgressViewStyle())

            Text("Aguarde enquanto processamos sua imagem...")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.lg)
        .cardStyle()
    }
}

private struct AnalysisWaitingView: View {
    var body: some View {
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
    }
}

private struct AnalysisErrorView: View {
    let isRetrying: Bool
    let canRetry: Bool
    let retryAction: () -> Void

    var body: some View {
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

            Button(action: retryAction) {
                HStack {
                    if isRetrying {
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
                .foregroundColor(DesignSystem.Colors.surface)
                .cornerRadius(DesignSystem.CornerRadius.lg)
            }
            .disabled(isRetrying || !canRetry)
        }
        .padding(DesignSystem.Spacing.lg)
        .cardStyle()
    }
}

#Preview {
    let mockPhoto = SkinLesionPhoto(
        imageData: Data(),
        analysisStatus: .completed
    )

    let container = DependencyContainer.shared

    NavigationView {
        AnalysisDetailView(
            photo: mockPhoto,
            photoRepository: container.photoRepository,
            analysisService: container.analysisService,
            analysisExportService: container.analysisExportService,
            shareSheetPresenter: container.shareSheetPresenter
        )
    }
}
