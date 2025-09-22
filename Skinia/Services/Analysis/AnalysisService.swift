import Foundation

@MainActor
final class AnalysisService: AnalysisServiceProtocol {
    private let networkService: any NetworkServiceProtocol
    private let photoRepository: any PhotoRepositoryProtocol
    private var activeAnalyses: [UUID: AnalysisProgress] = [:]
    private var analysisTasks: [UUID: Task<Void, Never>] = [:]
    private var remoteAnalysisIds: [UUID: String] = [:]
    private let notificationManager: NotificationManager

    init(networkService: any NetworkServiceProtocol, photoRepository: any PhotoRepositoryProtocol, notificationManager: NotificationManager) {
        self.networkService = networkService
        self.photoRepository = photoRepository
        self.notificationManager = notificationManager
    }

    func startAnalysis(for photo: SkinLesionPhoto) async throws {
        if let existingTask = analysisTasks[photo.id] {
            existingTask.cancel()
            analysisTasks.removeValue(forKey: photo.id)
        }

        let progress = AnalysisProgress(photoId: photo.id)
        activeAnalyses[photo.id] = progress

        photo.analysisStatus = .uploading
        try photoRepository.update(photo)

        notificationManager.show(
            title: "Análise Iniciada",
            message: "Processando sua imagem...",
            type: .info
        )

        let task = Task<Void, Never> {
            await performAnalysis(for: photo, progress: progress)
        }
        analysisTasks[photo.id] = task

        await task.value
    }

    func getAnalysisProgress(for photoId: UUID) -> AnalysisProgress? {
        return activeAnalyses[photoId]
    }

    func cancelAnalysis(for photoId: UUID) async {
        analysisTasks[photoId]?.cancel()
        analysisTasks.removeValue(forKey: photoId)

        if let remoteId = remoteAnalysisIds.removeValue(forKey: photoId) {
            do {
                try await networkService.cancelAnalysis(for: remoteId)
            } catch {
                print("AnalysisService.cancelAnalysis - failed to cancel remote analysis: \(error)")
            }
        }

        activeAnalyses.removeValue(forKey: photoId)

        do {
            guard let photo = try photoRepository.fetch(with: photoId) else {
                return
            }

            photo.analysisStatus = .pending

            do {
                try photoRepository.update(photo)
            } catch {
                print("AnalysisService.cancelAnalysis - failed to update photo: \(error)")
                notificationManager.show(
                    title: "Erro ao atualizar análise",
                    message: "Não foi possível restaurar o status da foto cancelada.",
                    type: .error
                )
            }
        } catch {
            print("AnalysisService.cancelAnalysis - failed to fetch photo: \(error)")
            notificationManager.show(
                title: "Erro ao carregar foto",
                message: "Não foi possível acessar a foto para cancelar a análise.",
                type: .error
            )
        }
    }

    func retryAnalysis(for photo: SkinLesionPhoto) async throws {
        photo.analysisStatus = .pending
        photo.analysisResult = nil
        try photoRepository.update(photo)
        remoteAnalysisIds.removeValue(forKey: photo.id)
        try await startAnalysis(for: photo)
    }

    private func performAnalysis(for photo: SkinLesionPhoto, progress: AnalysisProgress) async {
        do {
            let submission = try await networkService.submitAnalysis(imageData: photo.imageData, metadata: photo.metadata)
            remoteAnalysisIds[photo.id] = submission.analysisId

            if let initialStatus = submission.initialStatus {
                updateAnalysisProgress(for: photo, progress: progress, with: initialStatus)
            } else {
                progress.updateProgress(
                    stage: .uploading,
                    stageProgress: 0.1,
                    overallProgress: 0.1,
                    estimatedTimeRemaining: submission.estimatedTime
                )
                do {
                    try photoRepository.update(photo)
                } catch {
                    print("AnalysisService.performAnalysis - failed to update photo: \(error)")
                }
            }

            try await pollAnalysis(for: photo, progress: progress, analysisId: submission.analysisId)
        } catch is CancellationError {
            await handleAnalysisCancellation(for: photo, progress: progress)
        } catch {
            await handleAnalysisFailure(for: photo, progress: progress, error: error)
        }
    }

    private func pollAnalysis(for photo: SkinLesionPhoto, progress: AnalysisProgress, analysisId: String) async throws {
        while true {
            try Task.checkCancellation()

            let status = try await networkService.fetchAnalysisStatus(for: analysisId)
            updateAnalysisProgress(for: photo, progress: progress, with: status)

            if status.isFailed {
                await handleAnalysisFailure(for: photo, progress: progress, message: status.errorMessage)
                return
            }

            if status.isCompleted {
                let result = try await networkService.fetchAnalysisResult(for: analysisId)
                await completeAnalysis(for: photo, progress: progress, result: result)
                return
            }

            let safeInterval = min(max(0.5, status.suggestedRetryInterval), 30.0)
            let nanoseconds = UInt64((safeInterval * 1_000_000_000).rounded())
            try await Task.sleep(nanoseconds: nanoseconds)
        }
    }

    private func updateAnalysisProgress(for photo: SkinLesionPhoto, progress: AnalysisProgress, with status: RemoteAnalysisStatus) {
        if status.isFailed {
            progress.setError(status.errorMessage ?? "Falha na análise da imagem.")
        } else {
            progress.clearError()
        }

        progress.updateProgress(
            stage: status.stage,
            stageProgress: status.stageProgress,
            overallProgress: status.overallProgress,
            estimatedTimeRemaining: status.estimatedTimeRemaining
        )

        photo.analysisStatus = status.status

        do {
            try photoRepository.update(photo)
        } catch {
            print("AnalysisService.updateAnalysisProgress - failed to update photo: \(error)")
        }
    }

    private func completeAnalysis(for photo: SkinLesionPhoto, progress: AnalysisProgress, result: AnalysisResult) async {
        progress.updateProgress(stage: .completed, stageProgress: 1.0, overallProgress: 1.0)

        photo.analysisStatus = .completed
        photo.analysisResult = result
        try? photoRepository.update(photo)

        notificationManager.show(
            title: "Análise Concluída",
            message: "Resultado: \(result.lesionType) - Confiança: \(result.confidencePercentage)",
            type: .success,
            duration: 4.0
        )

        activeAnalyses.removeValue(forKey: photo.id)
        analysisTasks.removeValue(forKey: photo.id)
        remoteAnalysisIds.removeValue(forKey: photo.id)
    }

    private func handleAnalysisFailure(for photo: SkinLesionPhoto, progress: AnalysisProgress, error: Error? = nil, message: String? = nil) async {
        let errorMessage = message ?? error?.localizedDescription ?? "Falha na análise. Tente novamente mais tarde."

        progress.updateProgress(stage: .failed, stageProgress: 0.0, overallProgress: progress.overallProgress)
        progress.setError(errorMessage)

        photo.analysisStatus = .failed
        try? photoRepository.update(photo)

        notificationManager.show(
            title: "Erro na Análise",
            message: errorMessage,
            type: .error,
            duration: 5.0
        )

        activeAnalyses.removeValue(forKey: photo.id)
        analysisTasks.removeValue(forKey: photo.id)
        remoteAnalysisIds.removeValue(forKey: photo.id)
    }

    private func handleAnalysisCancellation(for photo: SkinLesionPhoto, progress: AnalysisProgress) async {
        notificationManager.show(
            title: "Análise Cancelada",
            message: "O processamento foi interrompido",
            type: .warning
        )

        activeAnalyses.removeValue(forKey: photo.id)
        analysisTasks.removeValue(forKey: photo.id)
        remoteAnalysisIds.removeValue(forKey: photo.id)
    }
}
