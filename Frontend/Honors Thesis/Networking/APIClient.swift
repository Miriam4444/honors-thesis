//
//  APIClient.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/5/26.
//
//
//  Talks to the FastAPI backend.

import Foundation

enum APIError: LocalizedError {
    case cantReachServer
    case badStatus(Int, String)

    var errorDescription: String? {
        switch self {
        case .cantReachServer:
            return "Couldn't reach the backend. Is uvicorn running?"
        case .badStatus(let code, let body):
            return "The backend returned an error (\(code)): \(body)"
        }
    }
}

struct APIClient {
    // the simulator shares your Mac's network, so localhost = your Mac.
    // on a real Vision Pro this has to be your Mac's IP address instead (like http://192.168.1.20:8000)
    static let baseURL = URL(string: "http://10.71.45.6:8000")!
    
    static func get<Response: Decodable>(_ path: String) async throws -> Response {
        let request = URLRequest(url: baseURL.appendingPathComponent(path))
        return try await send(request)
    }

    static func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request)
    }

    private static func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.cantReachServer
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw APIError.badStatus(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }
}
