import Foundation
import SwiftData
import Testing
@testable import Skinia

@MainActor
struct ExamRepositoryTests {

    private func createInMemoryContainer() -> ModelContainer {
        let schema = Schema([
            Exam.self,
            SkinLesionPhoto.self,
            PhotoMetadata.self,
            AnalysisResult.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create in-memory container: \(error)")
        }
    }

    @Test
    func saveAndFetchByPatientID() throws {
        let container = createInMemoryContainer()
        let repository = ExamRepository(modelContainer: container)
        let exam = Exam(patientName: "Maria", patientID: "ABC123")

        try repository.save(exam)

        let fetched = try repository.fetch(patientID: "ABC123", patientName: nil)
        #expect(fetched?.id == exam.id)
        #expect(fetched?.patientName == "Maria")
    }

    @Test
    func fetchFallsBackToPatientName() throws {
        let container = createInMemoryContainer()
        let repository = ExamRepository(modelContainer: container)
        let exam = Exam(patientName: "João", patientID: nil)

        try repository.save(exam)

        let fetched = try repository.fetch(patientID: nil, patientName: "João")
        #expect(fetched?.id == exam.id)
    }

    @Test
    func fetchIgnoresDeletedExams() throws {
        let container = createInMemoryContainer()
        let repository = ExamRepository(modelContainer: container)
        let exam = Exam(patientName: "Ana", patientID: "XYZ987")

        try repository.save(exam)

        exam.markAsDeleted()
        try repository.update(exam)

        let fetched = try repository.fetch(patientID: "XYZ987", patientName: "Ana")
        #expect(fetched == nil)
    }

    @Test
    func updatePersistsPatientInformationChanges() throws {
        let container = createInMemoryContainer()
        let repository = ExamRepository(modelContainer: container)
        let exam = Exam(patientName: "Pedro", patientID: "111")

        try repository.save(exam)

        exam.updatePatientInfo(name: "Pedro Silva", id: "222")
        try repository.update(exam)

        let fetched = try repository.fetch(patientID: "222", patientName: "Pedro Silva")
        #expect(fetched?.patientName == "Pedro Silva")
        #expect(fetched?.patientID == "222")
    }
}
