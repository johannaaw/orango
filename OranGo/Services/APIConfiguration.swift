import Foundation

enum APIConfiguration {
    static let baseURL = "https://orangoserver-production.up.railway.app"
    
    // Endpoint paths
    static let machinesEndpoint = "/api/machines"
    static let gradesEndpoint = "/api/grades"
    static let batchesEndpoint = "/api/batches"
    static let retailGradesEndpoint = "/api/retail-grades"
    static let thresholdRulesEndpoint = "/api/aturan-threshold"
    static let hasilSortirEndpoint = "/api/hasil-sortir"

    static func makeURL(_ path: String) throws -> URL {
        let normalizedPath = path.hasPrefix("http") ? path : baseURL + path

        guard let url = URL(string: normalizedPath) else {
            throw APIError.invalidURL
        }

        return url
    }
}
