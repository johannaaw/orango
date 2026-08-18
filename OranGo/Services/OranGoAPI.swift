//
//  OranGoAPI.swift
//  OranGo
//
//  The app's only HTTP layer. Every call to the OranGo Vapor server goes through here.
//

import Foundation

// MARK: - Configuration

enum APIConfig {
    static let baseURL = URL(string: "https://orangoserver-production.up.railway.app")!

    /// Required by `POST /api/hasil-sortir`; the device supplies it, the iPad normally does not.
    static var apiKey: String?

    enum Path {
        static let machines = "/api/machines"
        static let grades = "/api/grades"
        static let batches = "/api/batches"
        static let retailGrades = "/api/retail-grades"
        static let thresholdRules = "/api/aturan-threshold"
        static let hasilSortir = "/api/hasil-sortir"
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case httpStatus(Int, body: String)
    case decoding(Error, body: String)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let path):
            return "URL API tidak valid: \(path)"

        case .invalidResponse:
            return "Balasan server tidak dikenali."

        case .httpStatus(let status, let body):
            if let reason = Self.reason(from: body) {
                return "Server menolak (\(status)): \(reason)"
            }
            return "Server membalas dengan kode \(status)."

        case .decoding:
            return "Format data dari server tidak sesuai."

        case .network(let error):
            return error.localizedDescription
        }
    }

    private static func reason(from body: String) -> String? {
        struct ServerError: Decodable { let reason: String }
        guard let data = body.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(ServerError.self, from: data)
        else { return nil }
        return parsed.reason
    }
}

// MARK: - Request Bodies

struct CreateBatchRequest: Codable {
    let machineId: Int
    let retailGradeId: Int
}

struct FinishBatchRequest: Codable {
    let selesaiPada: Date
}

struct CreateRetailGradeRequest: Codable {
    let retailGrade: RetailGrade
    let thresholds: [ThresholdRule]

    enum CodingKeys: String, CodingKey {
        case retailGrade = "retail_grade"
        case thresholds
    }
}

// MARK: - Client

struct OranGoAPI {
    static let shared = OranGoAPI()

    private let session: URLSession = .shared

    // MARK: Machines

    func machines() async throws -> [Machine] {
        try await get(APIConfig.Path.machines)
    }

    func createMachine(_ machine: Machine) async throws -> Machine {
        try await send(APIConfig.Path.machines, method: "POST", body: machine)
    }

    // MARK: Grades

    func grades() async throws -> [Grade] {
        try await get(APIConfig.Path.grades)
    }

    // MARK: Batches

    func batches() async throws -> [Batch] {
        try await get(APIConfig.Path.batches)
    }

    /// `kodeBatch` is composed by the server once the row id exists.
    func createBatch(machineID: Int, retailGradeID: Int) async throws -> Batch {
        try await send(
            APIConfig.Path.batches,
            method: "POST",
            body: CreateBatchRequest(machineId: machineID, retailGradeId: retailGradeID)
        )
    }

    // TODO: [DB] Menunggu PATCH /api/batches/:id ditambahkan di server.
    func finishBatch(id: Int) async throws -> Batch {
        try await send(
            "\(APIConfig.Path.batches)/\(id)",
            method: "PATCH",
            body: FinishBatchRequest(selesaiPada: .now)
        )
    }

    // MARK: Retail Grades

    func retailGrades() async throws -> [RetailGrade] {
        try await get(APIConfig.Path.retailGrades)
    }

    func retailGrade(id: Int) async throws -> RetailGradeDetail {
        try await get("\(APIConfig.Path.retailGrades)/\(id)")
    }

    func createRetailGrade(
        _ retailGrade: RetailGrade,
        thresholds: [ThresholdRule]
    ) async throws -> RetailGrade {
        try await send(
            APIConfig.Path.retailGrades,
            method: "POST",
            body: CreateRetailGradeRequest(retailGrade: retailGrade, thresholds: thresholds)
        )
    }

    // TODO: [DB] Endpoint activate belum ada di daftar API server.
    func activateRetailGrade(id: Int) async throws {
        try await sendVoid("\(APIConfig.Path.retailGrades)/\(id)/activate", method: "POST")
    }

    // MARK: Threshold Rules

    func thresholdRules() async throws -> [ThresholdRule] {
        try await get(APIConfig.Path.thresholdRules)
    }

    func createThresholdRule(_ rule: ThresholdRule) async throws -> ThresholdRule {
        try await send(APIConfig.Path.thresholdRules, method: "POST", body: rule)
    }

    func updateThresholdRule(_ rule: ThresholdRule) async throws -> ThresholdRule {
        try await send("\(APIConfig.Path.thresholdRules)/\(rule.id)", method: "PATCH", body: rule)
    }

    func deleteThresholdRule(id: Int) async throws {
        try await sendVoid("\(APIConfig.Path.thresholdRules)/\(id)", method: "DELETE")
    }

    // MARK: Hasil Sortir

    func hasilSortir(batchID: Int? = nil) async throws -> [HasilSortir] {
        var path = APIConfig.Path.hasilSortir
        if let batchID { path += "?batchId=\(batchID)" }
        return try await get(path)
    }

    func createHasilSortir(_ scan: HasilSortir, apiKey: String) async throws -> HasilSortir {
        try await send(APIConfig.Path.hasilSortir, method: "POST", body: scan, apiKey: apiKey)
    }

    // MARK: - Transport

    private func get<Response: Decodable>(_ path: String) async throws -> Response {
        try await perform(try request(path, method: "GET"))
    }

    private func send<Body: Encodable, Response: Decodable>(
        _ path: String,
        method: String,
        body: Body,
        apiKey: String? = nil
    ) async throws -> Response {
        var urlRequest = try request(path, method: method)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey { urlRequest.setValue(apiKey, forHTTPHeaderField: "X-API-Key") }
        urlRequest.httpBody = try Self.encoder.encode(body)
        return try await perform(urlRequest)
    }

    /// For endpoints that answer with no body worth decoding.
    private func sendVoid(_ path: String, method: String) async throws {
        var urlRequest = try request(path, method: method)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        _ = try await performData(urlRequest)
    }

    private func request(_ path: String, method: String) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: APIConfig.baseURL) else {
            throw APIError.invalidURL(path)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        if let key = APIConfig.apiKey {
            urlRequest.setValue(key, forHTTPHeaderField: "X-API-Key")
        }
        return urlRequest
    }

    private func performData(_ urlRequest: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.network(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode, body: String(decoding: data))
        }
        return data
    }

    private func perform<Response: Decodable>(_ urlRequest: URLRequest) async throws -> Response {
        let data = try await performData(urlRequest)

        do {
            return try Self.decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(error, body: String(decoding: data))
        }
    }

    // MARK: - Coding

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

private extension String {
    init(decoding data: Data) {
        self = String(data: data, encoding: .utf8) ?? ""
    }
}
