import Testing
@testable import Skinia

@MainActor
final class InMemoryPhotoRepository: PhotoRepositoryProtocol {
    private var storage: [SkinLesionPhoto]

    init(photos: [SkinLesionPhoto] = []) {
        self.storage = photos
    }

    func save(_ photo: SkinLesionPhoto) throws {
        storage.append(photo)
    }

    func fetch(with id: UUID) throws -> SkinLesionPhoto? {
        storage.first { $0.id == id && !$0.isDeleted }
    }

    func fetchAll() throws -> [SkinLesionPhoto] {
        storage.filter { !$0.isDeleted }
    }

    func fetchPending() throws -> [SkinLesionPhoto] {
        try fetchByStatus(.pending)
    }

    func fetchCompleted() throws -> [SkinLesionPhoto] {
        try fetchByStatus(.completed)
    }

    func fetchByStatus(_ status: AnalysisStatus) throws -> [SkinLesionPhoto] {
        storage.filter { $0.analysisStatus == status && !$0.isDeleted }
    }

    func update(_ photo: SkinLesionPhoto) throws {
        guard let index = storage.firstIndex(where: { $0.id == photo.id }) else { return }
        storage[index] = photo
    }

    func delete(_ photo: SkinLesionPhoto) throws {
        storage.removeAll { $0.id == photo.id }
    }

    func deleteAll() throws {
        storage.removeAll()
    }

    func count() throws -> Int {
        storage.filter { !$0.isDeleted }.count
    }
}

@MainActor
struct AnalysisListViewModelTests {

    @Test
    func loadPhotosSortsByCaptureDate() throws {
        let repository = InMemoryPhotoRepository(photos: PreviewPhotoFactory.makeSamplePhotos())
        let viewModel = AnalysisListViewModel(photoRepository: repository)

        viewModel.loadPhotos()

        #expect(viewModel.photos.count == 3)
        #expect(viewModel.photos.first?.id == UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        #expect(viewModel.photos.last?.id == UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
    }

    @Test
    func filtersByStatus() throws {
        let repository = InMemoryPhotoRepository(photos: PreviewPhotoFactory.makeSamplePhotos())
        let viewModel = AnalysisListViewModel(photoRepository: repository)

        viewModel.loadPhotos()
        viewModel.setStatusFilter(.completed)

        #expect(viewModel.photos.count == 2)
        #expect(viewModel.photos.allSatisfy { $0.analysisStatus == .completed })

        viewModel.setStatusFilter(.pending)
        #expect(viewModel.photos.count == 1)
        #expect(viewModel.photos.first?.analysisStatus == .pending)
    }

    @Test
    func searchMatchesMultipleFields() throws {
        let repository = InMemoryPhotoRepository(photos: PreviewPhotoFactory.makeSamplePhotos())
        let viewModel = AnalysisListViewModel(photoRepository: repository)

        viewModel.loadPhotos()

        viewModel.searchText = "braço"
        #expect(viewModel.photos.count == 1)
        #expect(viewModel.photos.first?.metadata?.bodyLocation == "Braço direito")

        viewModel.searchText = "melanoma"
        #expect(viewModel.photos.count == 1)
        #expect(viewModel.photos.first?.analysisResult?.lesionType == "Possível Melanoma")

        viewModel.searchText = "nas costas"
        #expect(viewModel.photos.count == 1)
        #expect(viewModel.photos.first?.userNotes == "Nova lesão nas costas")
    }
}
