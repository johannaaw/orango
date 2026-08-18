import Foundation

protocol GradeRepositoryProtocol {
    func fetchGrades() async throws -> [Grade]
}

final class GradeRepository: GradeRepositoryProtocol {
    private let apiService: GradeAPIServiceProtocol

    init(apiService: GradeAPIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }

    func fetchGrades() async throws -> [Grade] {
        try await apiService.fetchGrades()
    }
}
