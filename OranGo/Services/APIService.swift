import Foundation

// MARK: - Threshold Rule API Protocol
protocol ThresholdRuleAPIServiceProtocol {
    func fetchThresholdRules() async throws -> [ThresholdRule]
    func createThresholdRule(_ rule: ThresholdRule) async throws -> ThresholdRule
    func updateThresholdRule(_ rule: ThresholdRule) async throws -> ThresholdRule
    func deleteThresholdRule(id: Int) async throws
}

// MARK: - Machine API Protocol
protocol MachineAPIServiceProtocol {
    func fetchMachines() async throws -> [Machine]
    func createMachine(_ machine: Machine) async throws -> Machine
}

// MARK: - Grade API Protocol
protocol GradeAPIServiceProtocol {
    func fetchGrades() async throws -> [Grade]
}

// MARK: - Batch API Protocol
protocol BatchAPIServiceProtocol {
    func fetchBatches() async throws -> [Batch]
    func createBatch(_ batch: Batch) async throws -> Batch
}

// MARK: - RetailGrade API Protocol
protocol RetailGradeAPIServiceProtocol {
    func fetchRetailGrades() async throws -> [RetailGrade]
    func fetchRetailGrade(id: Int) async throws -> RetailGrade
    func createRetailGrade(_ retailGrade: RetailGrade, withThresholds thresholds: [ThresholdRule]) async throws -> RetailGrade
    func activateRetailGrade(id: Int) async throws
}

// MARK: - Hasil Sortir API Protocol
protocol HasilSortirAPIServiceProtocol {
    func fetchHasilSortir() async throws -> [HasilSortir]
    func createHasilSortir(_ hasilSortir: HasilSortir, apiKey: String) async throws -> HasilSortir
}

// MARK: - Main API Service Implementation
final class APIService:
    ThresholdRuleAPIServiceProtocol,
    MachineAPIServiceProtocol,
    GradeAPIServiceProtocol,
    BatchAPIServiceProtocol,
    RetailGradeAPIServiceProtocol,
    HasilSortirAPIServiceProtocol
{
    static let shared = APIService()

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    // MARK: - Threshold Rule Methods
    func fetchThresholdRules() async throws -> [ThresholdRule] {
        try await apiClient.request(
            APIConfiguration.thresholdRulesEndpoint,
            method: .GET,
            responseType: [ThresholdRule].self
        )
    }

    func createThresholdRule(_ rule: ThresholdRule) async throws -> ThresholdRule {
        try await apiClient.request(
            APIConfiguration.thresholdRulesEndpoint,
            method: .POST,
            body: rule,
            responseType: ThresholdRule.self
        )
    }

    func updateThresholdRule(_ rule: ThresholdRule) async throws -> ThresholdRule {
        try await apiClient.request(
            "\(APIConfiguration.thresholdRulesEndpoint)/\(rule.id)",
            method: .PATCH,
            body: rule,
            responseType: ThresholdRule.self
        )
    }

    func deleteThresholdRule(id: Int) async throws {
        try await apiClient.request(
            "\(APIConfiguration.thresholdRulesEndpoint)/\(id)",
            method: .DELETE
        )
    }

    // MARK: - Machine Methods
    func fetchMachines() async throws -> [Machine] {
        try await apiClient.request(
            APIConfiguration.machinesEndpoint,
            method: .GET,
            responseType: [Machine].self
        )
    }

    func createMachine(_ machine: Machine) async throws -> Machine {
        try await apiClient.request(
            APIConfiguration.machinesEndpoint,
            method: .POST,
            body: machine,
            responseType: Machine.self
        )
    }

    // MARK: - Grade Methods
    func fetchGrades() async throws -> [Grade] {
        try await apiClient.request(
            APIConfiguration.gradesEndpoint,
            method: .GET,
            responseType: [Grade].self
        )
    }

    // MARK: - Batch Methods
    func fetchBatches() async throws -> [Batch] {
        try await apiClient.request(
            APIConfiguration.batchesEndpoint,
            method: .GET,
            responseType: [Batch].self
        )
    }

    func createBatch(_ batch: Batch) async throws -> Batch {
        try await apiClient.request(
            APIConfiguration.batchesEndpoint,
            method: .POST,
            body: batch,
            responseType: Batch.self
        )
    }

    // MARK: - RetailGrade Methods
    func fetchRetailGrades() async throws -> [RetailGrade] {
        try await apiClient.request(
            APIConfiguration.retailGradesEndpoint,
            method: .GET,
            responseType: [RetailGrade].self
        )
    }

    func fetchRetailGrade(id: Int) async throws -> RetailGrade {
        try await apiClient.request(
            "\(APIConfiguration.retailGradesEndpoint)/\(id)",
            method: .GET,
            responseType: RetailGrade.self
        )
    }

    func createRetailGrade(_ retailGrade: RetailGrade, withThresholds thresholds: [ThresholdRule]) async throws -> RetailGrade {
        // Create wrapper for POST that includes thresholds
        struct RetailGradePayload: Codable {
            let retailGrade: RetailGrade
            let thresholds: [ThresholdRule]

            enum CodingKeys: String, CodingKey {
                case retailGrade = "retail_grade"
                case thresholds
            }
        }

        let payload = RetailGradePayload(
            retailGrade: retailGrade,
            thresholds: thresholds
        )

        return try await apiClient.request(
            APIConfiguration.retailGradesEndpoint,
            method: .POST,
            body: payload,
            responseType: RetailGrade.self
        )
    }

    func activateRetailGrade(id: Int) async throws {
        try await apiClient.request(
            "\(APIConfiguration.retailGradesEndpoint)/\(id)/activate",
            method: .POST
        )
    }

    // MARK: - Hasil Sortir Methods
    func fetchHasilSortir() async throws -> [HasilSortir] {
        try await apiClient.request(
            APIConfiguration.hasilSortirEndpoint,
            method: .GET,
            responseType: [HasilSortir].self
        )
    }

    func createHasilSortir(_ hasilSortir: HasilSortir, apiKey: String) async throws -> HasilSortir {
        let url = try APIConfiguration.makeURL(APIConfiguration.hasilSortirEndpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(hasilSortir)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard 200...299 ~= httpResponse.statusCode else {
                throw APIError.httpStatusCode(httpResponse.statusCode, data: data)
            }

            let decoder = JSONDecoder()
            return try decoder.decode(HasilSortir.self, from: data)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}
