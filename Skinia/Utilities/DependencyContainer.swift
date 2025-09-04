import Foundation
import SwiftData

@MainActor
protocol DependencyContainerProtocol {
    // Services
    var photoRepository: PhotoRepositoryProtocol { get }
    var analysisService: AnalysisServiceProtocol { get }
    var cameraService: CameraServiceProtocol { get }
    var networkService: NetworkServiceProtocol { get }
    
    // Storage
    var modelContainer: ModelContainer { get }
}

@MainActor
final class DependencyContainer: DependencyContainerProtocol {
    
    // MARK: - Storage
    lazy var modelContainer: ModelContainer = {
        let schema = Schema([
            SkinLesionPhoto.self,
            AnalysisResult.self,
            PhotoMetadata.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // MARK: - Services
    lazy var photoRepository: PhotoRepositoryProtocol = PhotoRepository(
        modelContainer: modelContainer
    )
    
    lazy var analysisService: AnalysisServiceProtocol = AnalysisService(
        networkService: networkService,
        photoRepository: photoRepository
    )
    
    lazy var cameraService: CameraServiceProtocol = CameraService()
    
    lazy var networkService: NetworkServiceProtocol = NetworkService()
    
    // MARK: - Singleton
    static let shared = DependencyContainer()
    
    private init() {}
}

// MARK: - Protocol Placeholders
// Estes protocolos serão implementados nas próximas etapas

@MainActor
protocol AnalysisServiceProtocol {
    // Será implementado quando criarmos os serviços de rede
}

@MainActor
protocol CameraServiceProtocol {
    // Será implementado quando criarmos a captura de fotos
}

@MainActor
protocol NetworkServiceProtocol {
    // Será implementado quando criarmos os serviços de rede
}

// MARK: - Mock Implementations for now

@MainActor
final class AnalysisService: AnalysisServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private let photoRepository: PhotoRepositoryProtocol
    
    init(networkService: NetworkServiceProtocol, photoRepository: PhotoRepositoryProtocol) {
        self.networkService = networkService
        self.photoRepository = photoRepository
    }
}

@MainActor
final class CameraService: CameraServiceProtocol {
    init() {}
}

@MainActor
final class NetworkService: NetworkServiceProtocol {
    init() {}
}