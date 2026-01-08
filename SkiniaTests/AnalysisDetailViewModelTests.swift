import Testing
@testable import Skinia

@MainActor
struct AnalysisDetailViewModelTests {

    @MainActor
    private final class MockPhotoRepository: PhotoRepositoryProtocol {
        var updatedPhotos: [SkinLesionPhoto] = []
        var deletedPhotos: [SkinLesionPhoto] = []

        func save(_ photo: SkinLesionPhoto) throws {
            fatalError("Not implemented")
        }

        func fetch(with id: UUID) throws -> SkinLesionPhoto? {
            fatalError("Not implemented")
        }

        func fetchAll() throws -> [SkinLesionPhoto] {
            fatalError("Not implemented")
        }

        func fetchPending() throws -> [SkinLesionPhoto] {
            fatalError("Not implemented")
        }

        func fetchCompleted() throws -> [SkinLesionPhoto] {
            fatalError("Not implemented")
        }

        func fetchByStatus(_ status: AnalysisStatus) throws -> [SkinLesionPhoto] {
            fatalError("Not implemented")
        }

        func update(_ photo: SkinLesionPhoto) throws {
            updatedPhotos.append(photo)
        }

        func delete(_ photo: SkinLesionPhoto) throws {
            deletedPhotos.append(photo)
        }

        func deleteAll() throws {
            fatalError("Not implemented")
        }

        func count() throws -> Int {
            fatalError("Not implemented")
        }
    }

    @MainActor
    private final class MockAnalysisService: AnalysisServiceProtocol {
        enum MockError: Error, Equatable {
            case retryFailed
        }

        var retryCalled = false
        var shouldThrow = false
        let repository: MockPhotoRepository

        init(repository: MockPhotoRepository) {
            self.repository = repository
        }

        func startAnalysis(for photo: SkinLesionPhoto) async throws {}

        func getAnalysisProgress(for photoId: UUID) -> AnalysisProgress? {
            return nil
        }

        func cancelAnalysis(for photoId: UUID) async {}

        func retryAnalysis(for photo: SkinLesionPhoto) async throws {
            retryCalled = true

            if shouldThrow {
                throw MockError.retryFailed
            }

            photo.analysisStatus = .uploading
            try repository.update(photo)
        }
    }

    @MainActor
    private final class MockAnalysisExportService: AnalysisExportServiceProtocol {
        enum MockError: Error {
            case exportFailed
        }

        var exportedPhotos: [[SkinLesionPhoto]] = []
        var shouldThrow = false
        var urlToReturn = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("mock.pdf")

        func exportPhotos(_ photos: [SkinLesionPhoto], format: AnalysisExportFormat) throws -> URL {
            exportedPhotos.append(photos)

            if shouldThrow {
                throw MockError.exportFailed
            }

            return urlToReturn
        }
    }

    private func makeViewModel(status: AnalysisStatus = .failed) -> (AnalysisDetailViewModel, MockPhotoRepository, MockAnalysisService, SkinLesionPhoto) {
        let repository = MockPhotoRepository()
        let photo = SkinLesionPhoto(
            imageData: Data(),
            analysisStatus: status
        )
        let service = MockAnalysisService(repository: repository)
        let viewModel = AnalysisDetailViewModel(
            photo: photo,
            photoRepository: repository,
            analysisService: service
        )
        return (viewModel, repository, service, photo)
    }

    @Test
    func retryAnalysisSuccessUpdatesRepositoryAndClearsError() async {
        let (viewModel, repository, service, photo) = makeViewModel()

        await viewModel.retryAnalysis()

        #expect(service.retryCalled)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isRetrying)
        #expect(repository.updatedPhotos.contains(where: { $0 === photo }))
        #expect(photo.analysisStatus == .uploading)
    }

    @Test
    func retryAnalysisFailureSetsErrorMessage() async {
        let (viewModel, _, service, _) = makeViewModel()
        service.shouldThrow = true

        await viewModel.retryAnalysis()

        #expect(service.retryCalled)
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isRetrying)
    }

    @Test
    func exportReportSuccessReturnsURL() throws {
        let (viewModel, _, _, photo) = makeViewModel(status: .completed)
        let exportService = MockAnalysisExportService()

        let url = try viewModel.exportReport(using: exportService)

        #expect(url == exportService.urlToReturn)
        #expect(exportService.exportedPhotos.count == 1)
        #expect(exportService.exportedPhotos.first?.first === photo)
    }

    @Test
    func exportReportFailurePropagatesError() {
        let (viewModel, _, _, _) = makeViewModel(status: .completed)
        let exportService = MockAnalysisExportService()
        exportService.shouldThrow = true

        #expect(throws: MockAnalysisExportService.MockError.exportFailed) {
            _ = try viewModel.exportReport(using: exportService)
        }
    }
}
