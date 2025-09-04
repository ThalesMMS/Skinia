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

extension AnalysisListViewModel {
    // Mock data for development - will be removed when real data is available
    func loadMockData() {
        let mockPhotos = createMockPhotos()
        allPhotos = mockPhotos
        filterPhotos()
    }
    
    private func createMockPhotos() -> [SkinLesionPhoto] {
        let calendar = Calendar.current
        let now = Date()
        
        // Create mock image data (small colored rectangles)
        let mockImageData1 = createMockImageData(color: .systemBrown)
        let mockImageData2 = createMockImageData(color: .systemRed)
        let mockImageData3 = createMockImageData(color: .systemBlue)
        
        // Mock photo 1 - Completed analysis
        let photo1 = SkinLesionPhoto(
            imageData: mockImageData1,
            captureDate: calendar.date(byAdding: .day, value: -2, to: now)!,
            analysisStatus: .completed,
            userNotes: "Lesão no braço direito"
        )
        
        let result1 = AnalysisResult(
            confidence: 0.87,
            lesionType: "Nevo Melanocítico",
            riskLevel: .low,
            recommendations: ["Monitorar mudanças", "Consulta de rotina em 6 meses"]
        )
        photo1.analysisResult = result1
        
        let metadata1 = PhotoMetadata(
            imageQuality: .good,
            bodyLocation: "Braço direito",
            imageSize: CGSize(width: 1024, height: 1024),
            fileSize: 2048000
        )
        photo1.metadata = metadata1
        
        // Mock photo 2 - Pending analysis
        let photo2 = SkinLesionPhoto(
            imageData: mockImageData2,
            captureDate: calendar.date(byAdding: .hour, value: -3, to: now)!,
            analysisStatus: .pending,
            userNotes: "Nova lesão nas costas"
        )
        
        let metadata2 = PhotoMetadata(
            imageQuality: .excellent,
            bodyLocation: "Costas",
            imageSize: CGSize(width: 1920, height: 1080),
            fileSize: 3200000
        )
        photo2.metadata = metadata2
        
        // Mock photo 3 - High risk result
        let photo3 = SkinLesionPhoto(
            imageData: mockImageData3,
            captureDate: calendar.date(byAdding: .day, value: -1, to: now)!,
            analysisStatus: .completed,
            userNotes: "Lesão que mudou de cor"
        )
        
        let result3 = AnalysisResult(
            confidence: 0.92,
            lesionType: "Possível Melanoma",
            riskLevel: .urgent,
            recommendations: ["Consultar dermatologista IMEDIATAMENTE", "Não aguardar", "Procurar atendimento especializado"]
        )
        photo3.analysisResult = result3
        
        let metadata3 = PhotoMetadata(
            imageQuality: .good,
            bodyLocation: "Perna esquerda",
            imageSize: CGSize(width: 1024, height: 768),
            fileSize: 1800000
        )
        photo3.metadata = metadata3
        
        return [photo1, photo2, photo3]
    }
    
    private func createMockImageData(color: UIColor) -> Data {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
              let data = image.pngData() else {
            return Data()
        }
        
        return data
    }
}