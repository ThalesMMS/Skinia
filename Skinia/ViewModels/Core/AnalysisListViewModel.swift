import Foundation
import SwiftData
import UIKit

@MainActor
@Observable
final class AnalysisListViewModel {
    
    // MARK: - Published Properties
    private(set) var photos: [SkinLesionPhoto] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    // Filtering and searching
    var selectedStatusFilter: AnalysisStatus?
    var searchText = "" {
        didSet {
            filterPhotos()
        }
    }
    
    // MARK: - Private Properties
    private let photoRepository: PhotoRepositoryProtocol
    private var allPhotos: [SkinLesionPhoto] = []
    
    // MARK: - Initialization
    init(photoRepository: PhotoRepositoryProtocol) {
        self.photoRepository = photoRepository
    }
    
    // MARK: - Public Methods
    func loadPhotos() {
        isLoading = true
        errorMessage = nil
        
        do {
            allPhotos = try photoRepository.fetchAll()
            filterPhotos()
        } catch {
            errorMessage = "Erro ao carregar análises: \(error.localizedDescription)"
            photos = []
        }
        
        isLoading = false
    }
    
    func refreshPhotos() async {
        await Task { @MainActor in
            isLoading = true
            
            // Add a small delay to make the refresh feel more natural
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            loadPhotos()
        }.value
    }
    
    func deletePhoto(_ photo: SkinLesionPhoto) {
        do {
            try photoRepository.delete(photo)
            loadPhotos() // Reload to update the list
        } catch {
            errorMessage = "Erro ao excluir análise: \(error.localizedDescription)"
        }
    }
    
    func setStatusFilter(_ status: AnalysisStatus?) {
        selectedStatusFilter = status
        filterPhotos()
    }
    
    func clearFilters() {
        selectedStatusFilter = nil
        searchText = ""
        filterPhotos()
    }

    func clearErrorMessage() {
        errorMessage = nil
    }
    
    // MARK: - Computed Properties
    var hasPhotos: Bool {
        !photos.isEmpty
    }
    
    var getAllPhotos: [SkinLesionPhoto] {
        allPhotos
    }
    
    var photosNeedingAttention: [SkinLesionPhoto] {
        photos.filter { $0.needsAttention }
    }
    
    var photosByStatus: [AnalysisStatus: [SkinLesionPhoto]] {
        Dictionary(grouping: photos) { $0.analysisStatus }
    }
    
    var statusFilterOptions: [AnalysisStatus] {
        Array(Set(allPhotos.map { $0.analysisStatus })).sorted { status1, status2 in
            // Sort by priority: failed -> pending -> analyzing -> uploading -> completed
            let priority = [AnalysisStatus.failed, .pending, .analyzing, .uploading, .completed]
            let index1 = priority.firstIndex(of: status1) ?? priority.count
            let index2 = priority.firstIndex(of: status2) ?? priority.count
            return index1 < index2
        }
    }
    
    // MARK: - Private Methods
    private func filterPhotos() {
        var filtered = allPhotos
        
        // Filter by status
        if let selectedStatus = selectedStatusFilter {
            filtered = filtered.filter { $0.analysisStatus == selectedStatus }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { photo in
                // Search in body location
                if let bodyLocation = photo.metadata?.bodyLocation,
                   bodyLocation.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                
                // Search in user notes
                if let userNotes = photo.userNotes,
                   userNotes.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                
                // Search in analysis result
                if let result = photo.analysisResult,
                   result.lesionType.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                
                return false
            }
        }
        
        // Sort by capture date (newest first)
        filtered = filtered.sorted { $0.captureDate > $1.captureDate }
        
        photos = filtered
    }
}
