import Foundation
import SwiftData

@MainActor
protocol DependencyContainerProtocol {
    // Services
    var photoRepository: any PhotoRepositoryProtocol { get }
    var analysisService: any AnalysisServiceProtocol { get }
    var cameraService: any CameraServiceProtocol { get }
    var networkService: any NetworkServiceProtocol { get }
    var analysisExportService: any AnalysisExportServiceProtocol { get }
    var shareSheetPresenter: ShareSheetPresenter { get }

    // Storage
    var modelContainer: ModelContainer { get }
}

@MainActor
final class DependencyContainer: DependencyContainerProtocol {

    // MARK: - Managers
    let notificationManager = NotificationManager()
    let shareSheetPresenter = ShareSheetPresenter()

    // MARK: - Storage
    lazy var modelContainer: ModelContainer = {
        let schema = Schema([
            SkinLesionPhoto.self,
            AnalysisResult.self,
            PhotoMetadata.self,
            Exam.self
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
    lazy var photoRepository: any PhotoRepositoryProtocol = PhotoRepository(
        modelContainer: modelContainer
    )

    lazy var analysisService: any AnalysisServiceProtocol = AnalysisService(
        networkService: networkService,
        photoRepository: photoRepository,
        notificationManager: notificationManager
    )

    lazy var cameraService: any CameraServiceProtocol = CameraService(
        photoRepository: photoRepository,
        analysisService: analysisService,
        notificationManager: notificationManager
    )

    lazy var networkService: any NetworkServiceProtocol = RemoteAnalysisNetworkService()

    lazy var analysisExportService: any AnalysisExportServiceProtocol = AnalysisExportService()

    // MARK: - Singleton
    static let shared = DependencyContainer()

    private init() {
        migrateSearchableBodyLocationsIfNeeded()
    }

    func migrateSearchableBodyLocationsIfNeeded() {
        do {
            try PhotoMetadata.populateMissingSearchableBodyLocations(in: modelContainer.mainContext)
        } catch {
            print("Failed to migrate searchable body locations: \(error)")
        }
    }
}
