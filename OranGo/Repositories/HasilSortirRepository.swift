import Foundation

protocol HasilSortirRepositoryProtocol {
    func fetchHasilSortir() async throws -> [HasilSortir]
    func createHasilSortir(_ hasilSortir: HasilSortir, apiKey: String) async throws -> HasilSortir
}

final class HasilSortirRepository: HasilSortirRepositoryProtocol {
    private let apiService: HasilSortirAPIServiceProtocol

    init(apiService: HasilSortirAPIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }

    func fetchHasilSortir() async throws -> [HasilSortir] {
        try await apiService.fetchHasilSortir()
    }

    func createHasilSortir(_ hasilSortir: HasilSortir, apiKey: String) async throws -> HasilSortir {
        try await apiService.createHasilSortir(hasilSortir, apiKey: apiKey)
    }
}
