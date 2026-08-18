//
//  OranGoAPI.swift
//  OranGo
//
//  HTTP client for the OranGo Vapor server.
//

import Foundation

// MARK: - Configuration

enum APIConfig {
    static let baseURL = URL(string: "https://orangoserver-production.up.railway.app")!

    static var apiKey: String? = nil
}

// MARK: - Errors

enum APIError: LocalizedError {
    case badResponse(status: Int, body: String)
    case decoding(underlying: Error, body: String)

    var errorDescription: String? {
        switch self {
        case .badResponse(let status, let body):
            if let reason = Self.reason(from: body) {
                return "Server menolak (\(status)): \(reason)"
            }
            return "Server membalas dengan kode \(status)."
        case .decoding:
            return "Format data dari server tidak dikenali."
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

// MARK: - Wire Models

struct Ref: Codable, Hashable {
    let id: Int
}

struct MachineDTO: Codable, Hashable {
    let id: Int
    let machineName: String
    let lokasi: String?
    let statusKoneksi: String
    let terakhirTerlihat: Date?
    let thresholdAktif: Ref?
}

struct GradeDTO: Codable, Hashable {
    let id: Int
    let kelasGrading: String
    let label: String
    let warnaTampilan: String
}

struct RetailGradeDTO: Codable, Hashable {
    let id: Int
    let retailName: String
    let dibuatPada: Date?
    let aktif: Bool
    let catatan: String?
}

struct BatchDTO: Codable, Hashable {
    let id: Int
    let kodeBatch: String
    let mulaiPada: Date
    let selesaiPada: Date?
    let machine: Ref
    let retailGrade: Ref
}

struct HasilSortirDTO: Codable, Hashable {
    let id: Int
    let batch: Ref?
    let grade: Ref
    let retailGrade: Ref
    let waktuScan: Date
    let diameter: Double
    let berat: Double
    let warnaOranye: Double
    let bentukWajar: Bool
}

// MARK: Aggregates

// TODO: [DB] Kontrak untuk endpoint ringkasan yang belum ada di server.
struct SortingSummaryDTO: Codable, Hashable {
    let totalBerat: Double
    let totalJumlah: Int
    let totalBatch: Int
    let perGrade: [GradeSummaryDTO]
}

struct GradeSummaryDTO: Codable, Hashable {
    let kelasGrading: String
    let totalBerat: Double
    let totalJumlah: Int
}

// MARK: Requests

// TODO: [DB] kodeBatch disusun server setelah id terbentuk, tidak dikirim dari iPad.
struct CreateBatchRequest: Codable {
    let machineId: Int
    let retailGradeId: Int
}

struct FinishBatchRequest: Codable {
    let selesaiPada: Date
}

// MARK: - Client

struct OranGoAPI {
    static let shared = OranGoAPI()

    private let session: URLSession = .shared

    // MARK: Master Data

    func machines() async throws -> [MachineDTO] {
        try await get("/api/machines")
    }

    func grades() async throws -> [GradeDTO] {
        try await get("/api/grades")
    }

    func retailGrades() async throws -> [RetailGradeDTO] {
        try await get("/api/retail-grades")
    }

    // MARK: Batches

    func batches() async throws -> [BatchDTO] {
        try await get("/api/batches")
    }

    func createBatch(machineID: Int, retailGradeID: Int) async throws -> BatchDTO {
        try await send(
            "/api/batches",
            method: "POST",
            body: CreateBatchRequest(
                machineId: machineID,
                retailGradeId: retailGradeID
            )
        )
    }

    // TODO: [DB] Menunggu PATCH /api/batches/:id ditambahkan di server.
    func finishBatch(id: Int) async throws -> BatchDTO {
        try await send(
            "/api/batches/\(id)",
            method: "PATCH",
            body: FinishBatchRequest(selesaiPada: .now)
        )
    }

    // MARK: Results

    func hasilSortir(batchID: Int? = nil) async throws -> [HasilSortirDTO] {
        var path = "/api/hasil-sortir"
        if let batchID {
            path += "?batchId=\(batchID)"
        }
        return try await get(path)
    }

    // TODO: [DB] Menunggu endpoint ringkasan ditambahkan di server.
    func summary(from: Date, to: Date) async throws -> SortingSummaryDTO {
        let formatter = ISO8601DateFormatter()
        let query = "?from=\(formatter.string(from: from))&to=\(formatter.string(from: to))"
        return try await get("/api/summary" + query)
    }

    // TODO: [DB] Menunggu endpoint ringkasan per batch ditambahkan di server.
    func batchSummary(id: Int) async throws -> SortingSummaryDTO {
        try await get("/api/batches/\(id)/summary")
    }

    // MARK: - Transport

    private func get<Response: Decodable>(_ path: String) async throws -> Response {
        try await perform(request(path, method: "GET"))
    }

    private func send<Body: Encodable, Response: Decodable>(
        _ path: String,
        method: String,
        body: Body
    ) async throws -> Response {
        var urlRequest = request(path, method: method)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try Self.encoder.encode(body)
        return try await perform(urlRequest)
    }

    private func request(_ path: String, method: String) -> URLRequest {
        var urlRequest = URLRequest(url: URL(string: path, relativeTo: APIConfig.baseURL)!)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        if let key = APIConfig.apiKey {
            urlRequest.setValue(key, forHTTPHeaderField: "X-API-Key")
        }
        return urlRequest
    }

    private func perform<Response: Decodable>(_ urlRequest: URLRequest) async throws -> Response {
        let (data, response) = try await session.data(for: urlRequest)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        guard (200 ..< 300).contains(status) else {
            throw APIError.badResponse(status: status, body: String(decoding: data))
        }

        do {
            return try Self.decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(underlying: error, body: String(decoding: data))
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
