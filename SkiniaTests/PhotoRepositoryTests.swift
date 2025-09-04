import Testing
import SwiftData
import Foundation
import CoreGraphics
@testable import Skinia

@MainActor
struct PhotoRepositoryTests {
    
    private func createInMemoryContainer() -> ModelContainer {
        let schema = Schema([
            SkinLesionPhoto.self,
            AnalysisResult.self,
            PhotoMetadata.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create in-memory container: \(error)")
        }
    }
    
    private func createTestPhoto(status: AnalysisStatus = .pending) -> SkinLesionPhoto {
        let imageData = Data([1, 2, 3, 4, 5])
        return SkinLesionPhoto(
            imageData: imageData,
            analysisStatus: status,
            userNotes: "Test photo"
        )
    }
    
    @Test func repositoryInitialization() {
        let container = createInMemoryContainer()
        let repository = PhotoRepository(modelContainer: container)
        
        // Repository should be created successfully
        #expect(repository != nil)
    }
    
    @Test func saveAndFetchPhoto() async throws {
        let container = createInMemoryContainer()
        let repository = PhotoRepository(modelContainer: container)
        let photo = createTestPhoto()
        
        // Save photo
        try repository.save(photo)
        
        // Fetch photo by ID
        let fetchedPhoto = try repository.fetch(with: photo.id)
        #expect(fetchedPhoto?.id == photo.id)
        #expect(fetchedPhoto?.userNotes == "Test photo")
    }
    
    @Test func fetchAllPhotos() async throws {
        let container = createInMemoryContainer()
        let repository = PhotoRepository(modelContainer: container)
        
        // Create and save multiple photos
        let photo1 = createTestPhoto(status: .pending)
        let photo2 = createTestPhoto(status: .completed)
        let photo3 = createTestPhoto(status: .failed)
        
        try repository.save(photo1)
        try repository.save(photo2)
        try repository.save(photo3)
        
        // Fetch all photos
        let allPhotos = try repository.fetchAll()
        #expect(allPhotos.count == 3)
    }
    
    @Test func fetchPhotosByStatus() async throws {
        let container = createInMemoryContainer()
        let repository = PhotoRepository(modelContainer: container)
        
        // Create photos with different statuses
        let pendingPhoto1 = createTestPhoto(status: .pending)
        let pendingPhoto2 = createTestPhoto(status: .pending)
        let completedPhoto = createTestPhoto(status: .completed)
        let failedPhoto = createTestPhoto(status: .failed)
        
        try repository.save(pendingPhoto1)
        try repository.save(pendingPhoto2)
        try repository.save(completedPhoto)
        try repository.save(failedPhoto)
        
        // Fetch pending photos
        let pendingPhotos = try repository.fetchPending()
        #expect(pendingPhotos.count == 2)
        
        // Fetch completed photos
        let completedPhotos = try repository.fetchCompleted()
        #expect(completedPhotos.count == 1)
        
        // Fetch by specific status
        let failedPhotos = try repository.fetchByStatus(.failed)
        #expect(failedPhotos.count == 1)
    }
    
    @Test func updatePhoto() async throws {
        let container = createInMemoryContainer()
        let repository = PhotoRepository(modelContainer: container)
        let photo = createTestPhoto()
        
        try repository.save(photo)
        
        let originalUpdateTime = photo.lastUpdated
        
        // Small delay to ensure time difference
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        // Update photo
        photo.analysisStatus = .uploading
        try repository.update(photo)
        
        // Verify update
        let updatedPhoto = try repository.fetch(with: photo.id)
        #expect(updatedPhoto?.analysisStatus == .uploading)
        #expect(updatedPhoto?.lastUpdated != originalUpdateTime)
    }
    
    @Test func deletePhoto() async throws {
        let container = createInMemoryContainer()
        let repository = PhotoRepository(modelContainer: container)
        let photo = createTestPhoto()
        
        try repository.save(photo)
        
        // Delete photo (soft delete)
        try repository.delete(photo)
        
        // Photo should be marked as deleted but still exist
        #expect(photo.isDeleted == true)
        
        // fetchAll should not return deleted photos
        let allPhotos = try repository.fetchAll()
        #expect(allPhotos.count == 0)
        
        // But the photo should still exist in the container
        let allIncludingDeleted = try container.mainContext.fetch(FetchDescriptor<SkinLesionPhoto>())
        #expect(allIncludingDeleted.count == 1)
    }
    
    @Test func photoCount() async throws {
        let container = createInMemoryContainer()
        let repository = PhotoRepository(modelContainer: container)
        
        // Initially no photos
        let initialCount = try repository.count()
        #expect(initialCount == 0)
        
        // Add photos
        try repository.save(createTestPhoto())
        try repository.save(createTestPhoto())
        
        let countAfterAdding = try repository.count()
        #expect(countAfterAdding == 2)
        
        // Delete one photo
        let photos = try repository.fetchAll()
        try repository.delete(photos[0])
        
        let countAfterDeleting = try repository.count()
        #expect(countAfterDeleting == 1)
    }
    
    @Test func fetchRecentPhotos() async throws {
        let container = createInMemoryContainer()
        let repository = PhotoRepository(modelContainer: container)
        
        // Create photos with different capture dates
        let calendar = Calendar.current
        let now = Date()
        
        let photo1 = createTestPhoto()
        photo1.captureDate = calendar.date(byAdding: .day, value: -3, to: now)!
        
        let photo2 = createTestPhoto()
        photo2.captureDate = calendar.date(byAdding: .day, value: -2, to: now)!
        
        let photo3 = createTestPhoto()
        photo3.captureDate = calendar.date(byAdding: .day, value: -1, to: now)!
        
        try repository.save(photo1)
        try repository.save(photo2)
        try repository.save(photo3)
        
        // Fetch recent photos with limit
        let recentPhotos = try repository.fetchRecentPhotos(limit: 2)
        #expect(recentPhotos.count == 2)
        
        // Should be ordered by capture date (most recent first)
        #expect(recentPhotos[0].captureDate > recentPhotos[1].captureDate)
    }
    
    @Test func fetchPhotosNeedingAttention() async throws {
        let container = createInMemoryContainer()
        let repository = PhotoRepository(modelContainer: container)
        
        // Create photos with different conditions
        let normalPhoto = createTestPhoto(status: .completed)
        
        let failedPhoto = createTestPhoto(status: .failed)
        
        let urgentPhoto = createTestPhoto(status: .completed)
        let urgentResult = AnalysisResult(
            confidence: 0.9,
            lesionType: "High risk lesion",
            riskLevel: .urgent,
            recommendations: ["Seek immediate medical attention"]
        )
        urgentPhoto.analysisResult = urgentResult
        
        try repository.save(normalPhoto)
        try repository.save(failedPhoto)
        try repository.save(urgentPhoto)
        
        // Fetch photos needing attention
        let attentionPhotos = try repository.fetchPhotosNeedingAttention()
        
        // Should return failed photo and urgent result photo
        #expect(attentionPhotos.count == 2)
        
        let statuses = attentionPhotos.map { $0.analysisStatus }
        let riskLevels = attentionPhotos.compactMap { $0.analysisResult?.riskLevel }
        
        #expect(statuses.contains(.failed))
        #expect(riskLevels.contains(.urgent))
    }
    
    @Test func searchPhotosByBodyLocation() async throws {
        let container = createInMemoryContainer()
        let repository = PhotoRepository(modelContainer: container)
        
        // Create photos with metadata containing body locations
        let armPhoto = createTestPhoto()
        let armMetadata = PhotoMetadata(bodyLocation: "Braço direito")
        armPhoto.metadata = armMetadata
        
        let legPhoto = createTestPhoto()
        let legMetadata = PhotoMetadata(bodyLocation: "Perna esquerda")
        legPhoto.metadata = legMetadata
        
        let facePhoto = createTestPhoto()
        let faceMetadata = PhotoMetadata(bodyLocation: "Rosto")
        facePhoto.metadata = faceMetadata
        
        try repository.save(armPhoto)
        try repository.save(legPhoto)
        try repository.save(facePhoto)
        
        // Search for photos containing "braço"
        let armPhotos = try repository.searchPhotos(bodyLocation: "braço")
        #expect(armPhotos.count == 1)
        #expect(armPhotos[0].metadata?.bodyLocation?.contains("Braço") == true)
        
        // Search for photos containing "perna"
        let legPhotos = try repository.searchPhotos(bodyLocation: "perna")
        #expect(legPhotos.count == 1)
    }
    
    @Test func deleteAllPhotos() async throws {
        let container = createInMemoryContainer()
        let repository = PhotoRepository(modelContainer: container)
        
        // Add multiple photos
        try repository.save(createTestPhoto())
        try repository.save(createTestPhoto())
        try repository.save(createTestPhoto())
        
        let initialCount = try repository.count()
        #expect(initialCount == 3)
        
        // Delete all photos
        try repository.deleteAll()
        
        let finalCount = try repository.count()
        #expect(finalCount == 0)
    }
}