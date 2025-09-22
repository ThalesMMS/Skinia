import Foundation
import SwiftData

@MainActor
protocol PhotoRepositoryProtocol {
    func save(_ photo: SkinLesionPhoto) throws
    func fetch(with id: UUID) throws -> SkinLesionPhoto?
    func fetchAll() throws -> [SkinLesionPhoto]
    func fetchPending() throws -> [SkinLesionPhoto]
    func fetchCompleted() throws -> [SkinLesionPhoto]
    func fetchByStatus(_ status: AnalysisStatus) throws -> [SkinLesionPhoto]
    func update(_ photo: SkinLesionPhoto) throws
    func delete(_ photo: SkinLesionPhoto) throws
    func deleteAll() throws
    func count() throws -> Int
}

@MainActor
final class PhotoRepository: PhotoRepositoryProtocol {
    private let modelContainer: ModelContainer
    private var modelContext: ModelContext {
        modelContainer.mainContext
    }
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    func save(_ photo: SkinLesionPhoto) throws {
        modelContext.insert(photo)
        try modelContext.save()
    }
    
    func fetch(with id: UUID) throws -> SkinLesionPhoto? {
        let predicate = #Predicate<SkinLesionPhoto> { photo in
            photo.id == id && !photo.isDeleted
        }
        let descriptor = FetchDescriptor<SkinLesionPhoto>(predicate: predicate)
        let photos = try modelContext.fetch(descriptor)
        return photos.first
    }
    
    func fetchAll() throws -> [SkinLesionPhoto] {
        let predicate = #Predicate<SkinLesionPhoto> { photo in
            !photo.isDeleted
        }
        let descriptor = FetchDescriptor<SkinLesionPhoto>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.captureDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchPending() throws -> [SkinLesionPhoto] {
        return try fetchByStatus(.pending)
    }
    
    func fetchCompleted() throws -> [SkinLesionPhoto] {
        return try fetchByStatus(.completed)
    }
    
    func fetchByStatus(_ status: AnalysisStatus) throws -> [SkinLesionPhoto] {
        let predicate = #Predicate<SkinLesionPhoto> { photo in
            photo.analysisStatus == status && !photo.isDeleted
        }
        let descriptor = FetchDescriptor<SkinLesionPhoto>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.captureDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func update(_ photo: SkinLesionPhoto) throws {
        photo.lastUpdated = Date()
        try modelContext.save()
    }
    
    func delete(_ photo: SkinLesionPhoto) throws {
        photo.markAsDeleted()
        try modelContext.save()
    }
    
    func deleteAll() throws {
        let allPhotos = try fetchAll()
        for photo in allPhotos {
            photo.markAsDeleted()
        }
        try modelContext.save()
    }
    
    func count() throws -> Int {
        let predicate = #Predicate<SkinLesionPhoto> { photo in
            !photo.isDeleted
        }
        let descriptor = FetchDescriptor<SkinLesionPhoto>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }
}

extension PhotoRepository {
    func fetchRecentPhotos(limit: Int = 10) throws -> [SkinLesionPhoto] {
        let predicate = #Predicate<SkinLesionPhoto> { photo in
            !photo.isDeleted
        }
        var descriptor = FetchDescriptor<SkinLesionPhoto>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.captureDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }
    
    func fetchPhotosNeedingAttention() throws -> [SkinLesionPhoto] {
        let predicate = #Predicate<SkinLesionPhoto> { photo in
            !photo.isDeleted && (
                photo.analysisStatus == .failed ||
                (photo.analysisStatus == .completed && photo.analysisResult?.riskLevel == .urgent)
            )
        }
        let descriptor = FetchDescriptor<SkinLesionPhoto>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.captureDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func searchPhotos(bodyLocation: String) throws -> [SkinLesionPhoto] {
        let trimmedSearch = bodyLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else {
            return []
        }

        let normalizedSearch = trimmedSearch
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        let predicate = #Predicate<SkinLesionPhoto> { photo in
            !photo.isDeleted &&
            photo.metadata?.searchableBodyLocation?.contains(normalizedSearch) == true
        }
        let descriptor = FetchDescriptor<SkinLesionPhoto>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.captureDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}