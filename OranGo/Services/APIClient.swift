//
//  APIClient.swift
//  OranGo
//
//  Created by Johanna Angel on 16/08/26.
//

import Foundation

enum APIRequestMethod: String {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func request<T: Decodable>(
        _ path: String,
        method: APIRequestMethod,
        body: Encodable? = nil,
        responseType: T.Type
    ) async throws -> T {
        let data = try await performRequest(
            path,
            method: method,
            body: body
        )

        if data.isEmpty {
            if let emptyValue = EmptyResponse() as? T {
                return emptyValue
            }
        }

        do {
            return try decoder.decode(
                T.self,
                from: data
            )
        } catch {
            let responseBody = String(
                data: data,
                encoding: .utf8
            ) ?? "Invalid UTF-8 response"

            print("Decoding error for \(T.self):", error)
            print("Response body:", responseBody)
            throw APIError.decodingError
        }
    }

    func request(
        _ path: String,
        method: APIRequestMethod,
        body: Encodable? = nil
    ) async throws {
        let data = try await performRequest(
            path,
            method: method,
            body: body
        )

        guard !data.isEmpty else { return }

        do {
            _ = try decoder.decode(
                EmptyResponse.self,
                from: data
            )
        } catch {
            let responseBody = String(
                data: data,
                encoding: .utf8
            ) ?? "Invalid UTF-8 response"

            print("Unexpected non-empty response body on DELETE/void call:", responseBody)
        }
    }

    private func performRequest(
        _ path: String,
        method: APIRequestMethod,
        body: Encodable?
    ) async throws -> Data {
        let url = try APIConfiguration.makeURL(path)

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        do {
            let (data, response) = try await session.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard 200...299 ~= httpResponse.statusCode else {
                throw APIError.httpStatusCode(
                    httpResponse.statusCode,
                    data: data
                )
            }

            return data

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

private struct EmptyResponse: Decodable {}
