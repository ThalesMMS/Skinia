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
}
