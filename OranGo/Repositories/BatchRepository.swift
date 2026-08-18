import Foundation

protocol BatchRepositoryProtocol {
    func fetchBatches() async throws -> [Batch]
    func createBatch(_ batch: Batch) async throws -> Batch
}

final class BatchRepository: BatchRepositoryProtocol {
    private let apiService: BatchAPIServiceProtocol

    init(apiService: BatchAPIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }

    func fetchBatches() async throws -> [Batch] {
        try await apiService.fetchBatches()
    }

    func createBatch(_ batch: Batch) async throws -> Batch {
        try await apiService.createBatch(batch)
    }
}
