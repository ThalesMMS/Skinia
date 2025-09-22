import Foundation

struct NetworkAnalysisSubmission {
    let analysisId: String
    let estimatedTime: TimeInterval?
    let initialStatus: RemoteAnalysisStatus?
}

struct RemoteAnalysisStatus {
    let analysisId: String
    let status: AnalysisStatus
    let stage: AnalysisStage
    let overallProgress: Double
    let stageProgress: Double
    let estimatedTimeRemaining: TimeInterval?
    let errorMessage: String?
    let suggestedRetryInterval: TimeInterval

    var isCompleted: Bool { status == .completed }
    var isFailed: Bool { status == .failed }
}

protocol AuthenticationProviding {
    func authenticationHeaders() async throws -> [String: String]
}

struct EnvironmentAuthenticationProvider: AuthenticationProviding {
    func authenticationHeaders() async throws -> [String: String] {
        var headers: [String: String] = [:]

        if let bearer = ProcessInfo.processInfo.environment["SKINIA_API_TOKEN"], !bearer.isEmpty {
            headers["Authorization"] = "Bearer \(bearer)"
        }

        if let apiKey = ProcessInfo.processInfo.environment["SKINIA_API_KEY"], !apiKey.isEmpty {
            headers["X-API-Key"] = apiKey
        }

        return headers
    }
}

enum RemoteAnalysisNetworkError: LocalizedError {
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(statusCode: Int)
    case decodingFailed(Error)
    case missingResult

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Resposta inválida do servidor."
        case .unauthorized:
            return "Autenticação necessária para realizar esta operação."
        case .notFound:
            return "Análise não encontrada."
        case .serverError(let statusCode):
            return "O servidor retornou um erro (código \(statusCode))."
        case .decodingFailed(let error):
            return "Falha ao interpretar a resposta da API: \(error.localizedDescription)"
        case .missingResult:
            return "Resultado da análise indisponível no momento."
        }
    }
}

final class RemoteAnalysisNetworkService: NetworkServiceProtocol {
    private enum Endpoint {
        static let analysis = "analysis"
    }

    private let baseURL: URL
    private let session: URLSession
    private let authenticationProvider: AuthenticationProviding
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        baseURL: URL = URL(string: "https://api.skinia.ai/v1")!,
        session: URLSession = .shared,
        authenticationProvider: AuthenticationProviding = EnvironmentAuthenticationProvider()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.authenticationProvider = authenticationProvider
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func submitAnalysis(imageData: Data, metadata: PhotoMetadata?) async throws -> NetworkAnalysisSubmission {
        let url = baseURL.appendingPathComponent(Endpoint.analysis)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let payload = AnalysisUploadRequest(
            imageBase64: imageData.base64EncodedString(),
            metadata: metadata.map(MetadataPayload.init),
            captureDate: Date()
        )
        request.httpBody = try encoder.encode(payload)

        try await applyAuthentication(to: &request)

        let (data, response) = try await session.data(for: request)
        let responseData = try validateResponse(data: data, response: response)
        let uploadResponse = try decode(AnalysisUploadResponse.self, from: responseData)

        let initialStatus = uploadResponse.status?.toDomain(analysisId: uploadResponse.analysisId)

        return NetworkAnalysisSubmission(
            analysisId: uploadResponse.analysisId,
            estimatedTime: uploadResponse.estimatedTimeSeconds,
            initialStatus: initialStatus
        )
    }

    func fetchAnalysisStatus(for analysisId: String) async throws -> RemoteAnalysisStatus {
        let url = baseURL
            .appendingPathComponent(Endpoint.analysis)
            .appendingPathComponent(analysisId)
            .appendingPathComponent("status")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30

        try await applyAuthentication(to: &request)

        let (data, response) = try await session.data(for: request)
        let responseData = try validateResponse(data: data, response: response)
        let statusResponse = try decode(RemoteAnalysisStatusResponse.self, from: responseData)

        return statusResponse.toDomain(analysisId: analysisId)
    }

    func fetchAnalysisResult(for analysisId: String) async throws -> AnalysisResult {
        let url = baseURL
            .appendingPathComponent(Endpoint.analysis)
            .appendingPathComponent(analysisId)
            .appendingPathComponent("result")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30

        try await applyAuthentication(to: &request)

        let (data, response) = try await session.data(for: request)
        let responseData = try validateResponse(data: data, response: response)
        let resultResponse = try decode(RemoteAnalysisResultResponse.self, from: responseData)

        return AnalysisResult(
            confidence: resultResponse.confidence,
            lesionType: resultResponse.lesionType,
            riskLevel: RiskLevel(rawValue: resultResponse.riskLevel.lowercased()) ?? .moderate,
            recommendations: resultResponse.recommendations,
            analysisDate: resultResponse.analysisDate,
            additionalNotes: resultResponse.additionalNotes
        )
    }

    func cancelAnalysis(for analysisId: String) async throws {
        let url = baseURL
            .appendingPathComponent(Endpoint.analysis)
            .appendingPathComponent(analysisId)
            .appendingPathComponent("cancel")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        try await applyAuthentication(to: &request)

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RemoteAnalysisNetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401:
            throw RemoteAnalysisNetworkError.unauthorized
        case 404:
            throw RemoteAnalysisNetworkError.notFound
        default:
            throw RemoteAnalysisNetworkError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Private helpers

    private func applyAuthentication(to request: inout URLRequest) async throws {
        let headers = try await authenticationProvider.authenticationHeaders()
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
    }

    private func validateResponse(data: Data, response: URLResponse) throws -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RemoteAnalysisNetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return data
        case 401:
            throw RemoteAnalysisNetworkError.unauthorized
        case 404:
            throw RemoteAnalysisNetworkError.notFound
        default:
            throw RemoteAnalysisNetworkError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw RemoteAnalysisNetworkError.decodingFailed(error)
        }
    }
}

// MARK: - Request/Response DTOs

private struct AnalysisUploadRequest: Encodable {
    let imageBase64: String
    let metadata: MetadataPayload?
    let captureDate: Date
}

private struct MetadataPayload: Encodable {
    let deviceInfo: String
    let imageQuality: String
    let bodyLocation: String?
    let imageWidth: Double
    let imageHeight: Double
    let fileSize: Int64
    let hasFlash: Bool
    let orientation: String
    let captureSettings: String?

    init(metadata: PhotoMetadata) {
        self.deviceInfo = metadata.deviceInfo
        self.imageQuality = metadata.imageQuality.rawValue
        self.bodyLocation = metadata.bodyLocation
        self.imageWidth = metadata.imageWidth
        self.imageHeight = metadata.imageHeight
        self.fileSize = metadata.fileSize
        self.hasFlash = metadata.hasFlash
        self.orientation = metadata.orientation
        self.captureSettings = metadata.captureSettings
    }
}

private struct AnalysisUploadResponse: Decodable {
    let analysisId: String
    let estimatedTimeSeconds: TimeInterval?
    let status: RemoteAnalysisStatusResponse?
}

private struct RemoteAnalysisStatusResponse: Decodable {
    let status: String
    let stage: String?
    let progress: Double?
    let stageProgress: Double?
    let estimatedTimeRemaining: TimeInterval?
    let message: String?
    let pollAfterSeconds: TimeInterval?

    func toDomain(analysisId: String) -> RemoteAnalysisStatus {
        let resolvedStatus = AnalysisStatus(rawValue: status) ?? .analyzing
        let resolvedStage: AnalysisStage

        if let stage = stage, let decodedStage = AnalysisStage(rawValue: stage) {
            resolvedStage = decodedStage
        } else {
            switch resolvedStatus {
            case .uploading:
                resolvedStage = .uploading
            case .completed:
                resolvedStage = .completed
            case .failed:
                resolvedStage = .failed
            default:
                resolvedStage = .analyzing
            }
        }

        let overall = max(0.0, min(1.0, progress ?? 0.0))
        let stageProgressValue = max(0.0, min(1.0, stageProgress ?? overall))
        let eta = estimatedTimeRemaining.map { max(0.0, $0) }
        let retry = max(0.5, pollAfterSeconds ?? 1.5)

        return RemoteAnalysisStatus(
            analysisId: analysisId,
            status: resolvedStatus,
            stage: resolvedStage,
            overallProgress: overall,
            stageProgress: stageProgressValue,
            estimatedTimeRemaining: eta,
            errorMessage: message,
            suggestedRetryInterval: retry
        )
    }
}

private struct RemoteAnalysisResultResponse: Decodable {
    let confidence: Double
    let lesionType: String
    let riskLevel: String
    let recommendations: [String]
    let analysisDate: Date
    let additionalNotes: String?
}
