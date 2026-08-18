import Foundation

protocol RetailGradeRepositoryProtocol {
    func fetchRetailGrades() async throws -> [RetailGrade]
    func fetchRetailGrade(id: Int) async throws -> RetailGrade
    func activateRetailGrade(id: Int) async throws
    func createRetailGrade(_ retailGrade: RetailGrade, withThresholds thresholds: [ThresholdRule]) async throws -> RetailGrade
}

final class RetailGradeRepository: RetailGradeRepositoryProtocol {
    private let apiService: RetailGradeAPIServiceProtocol
    
    init(apiService: RetailGradeAPIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }
    
    func fetchRetailGrades() async throws -> [RetailGrade] {
        try await apiService.fetchRetailGrades()
    }
    
    func fetchRetailGrade(id: Int) async throws -> RetailGrade {
        try await apiService.fetchRetailGrade(id: id)
    }
    
    func activateRetailGrade(id: Int) async throws {
        try await apiService.activateRetailGrade(id: id)
    }
    
    func createRetailGrade(_ retailGrade: RetailGrade, withThresholds thresholds: [ThresholdRule]) async throws -> RetailGrade {
        try await apiService.createRetailGrade(retailGrade, withThresholds: thresholds)
    }
}
