import Foundation
import SwiftData

@MainActor
protocol ExamRepositoryProtocol {
    func fetch(patientID: String?, patientName: String?) throws -> Exam?
    func save(_ exam: Exam) throws
    func update(_ exam: Exam) throws
}

@MainActor
final class ExamRepository: ExamRepositoryProtocol {
    private let modelContainer: ModelContainer
    private var modelContext: ModelContext {
        modelContainer.mainContext
    }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func fetch(patientID: String?, patientName: String?) throws -> Exam? {
        let trimmedID = patientID?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = patientName?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let id = trimmedID, !id.isEmpty {
            let predicate = #Predicate<Exam> { exam in
                exam.patientID == id && !exam.isDeleted
            }
            let descriptor = FetchDescriptor<Exam>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
            )
            if let exam = try modelContext.fetch(descriptor).first {
                return exam
            }
        }

        if let name = trimmedName, !name.isEmpty {
            let predicate = #Predicate<Exam> { exam in
                exam.patientName == name && !exam.isDeleted
            }
            let descriptor = FetchDescriptor<Exam>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
            )
            return try modelContext.fetch(descriptor).first
        }

        return nil
    }

    func save(_ exam: Exam) throws {
        modelContext.insert(exam)
        try modelContext.save()
    }

    func update(_ exam: Exam) throws {
        exam.lastUpdated = Date()
        try modelContext.save()
    }
}
