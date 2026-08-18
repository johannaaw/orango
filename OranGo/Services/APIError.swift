//
//  APIError.swift
//  OranGo
//
//  Created by Johanna Angel on 17/08/26.
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatusCode(Int, data: Data?)
    case decodingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL API tidak valid."

        case .invalidResponse:
            return "Response dari server tidak valid."

        case .httpStatusCode(let statusCode, let data):
            let serverMessage = data.flatMap { String(data: $0, encoding: .utf8) }
            if let serverMessage, !serverMessage.isEmpty {
                return "Request gagal (\(statusCode)): \(serverMessage)"
            }
            return "Request gagal dengan status \(statusCode)."

        case .decodingError:
            return "Data dari server tidak dapat diproses."

        case .networkError(let error):
            return error.localizedDescription
        }
    }
}
