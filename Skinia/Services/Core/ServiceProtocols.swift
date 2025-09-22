import Foundation

@MainActor
protocol AnalysisServiceProtocol {
    func startAnalysis(for photo: SkinLesionPhoto) async throws
    func getAnalysisProgress(for photoId: UUID) -> AnalysisProgress?
    func cancelAnalysis(for photoId: UUID) async
    func retryAnalysis(for photo: SkinLesionPhoto) async throws
}

@MainActor
protocol CameraServiceProtocol {
    func savePhoto(_ imageData: Data, bodyLocation: String?, userNotes: String?, patientName: String?, patientID: String?, metadata: PhotoMetadata) async throws -> SkinLesionPhoto
    func checkCameraPermission() async -> Bool
}

@MainActor
protocol NetworkServiceProtocol {
    func submitAnalysis(imageData: Data, metadata: PhotoMetadata?) async throws -> NetworkAnalysisSubmission
    func fetchAnalysisStatus(for analysisId: String) async throws -> RemoteAnalysisStatus
    func fetchAnalysisResult(for analysisId: String) async throws -> AnalysisResult
    func cancelAnalysis(for analysisId: String) async throws
}
