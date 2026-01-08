import SwiftUI

// MARK: - Analysis Service Environment Key

private struct AnalysisServiceKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: any AnalysisServiceProtocol = MockAnalysisService()
}

extension EnvironmentValues {
    var analysisService: any AnalysisServiceProtocol {
        get { self[AnalysisServiceKey.self] }
        set { self[AnalysisServiceKey.self] = newValue }
    }
}

// MARK: - Mock Analysis Service for Previews

@MainActor
private final class MockAnalysisService: AnalysisServiceProtocol {
    func startAnalysis(for photo: SkinLesionPhoto) async throws {
        // Mock implementation
    }
    
    func getAnalysisProgress(for photoId: UUID) -> AnalysisProgress? {
        return nil
    }
    
    func cancelAnalysis(for photoId: UUID) async {
        // Mock implementation
    }
    
    func retryAnalysis(for photo: SkinLesionPhoto) async throws {
        // Mock implementation
    }
}