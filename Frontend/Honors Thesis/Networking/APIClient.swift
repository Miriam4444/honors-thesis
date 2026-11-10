//
//  APIClient.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/5/26.
//
//  APIClient.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 10/5/26.
//
//
//talks to FastAPI backend.

import Foundation

enum APIError: LocalizedError {
    case cantReachServer
    case badStatus(Int, String)
    case notLoggedIn(String) //401: no token, expired, or logged out

    var errorDescription: String? {
        switch self {
        case .cantReachServer:
            return "Couldn't reach the backend. Is uvicorn running?"
        case .badStatus(let code, let body):
            return "The backend returned an error (\(code)): \(body)"
        case .notLoggedIn(let reason):
            return reason
        }
    }
}

extension Notification.Name {
    //posted when the backend says the login isn't valid anymore, so the app can go back to the login screen
    static let loginExpired = Notification.Name("loginExpired")
}

struct APIClient {
    //simulator shares Mac's network, so localhost is the mac.
    //on a real Vision Pro this has to be macs IP address instead
    static let baseURL = URL(string: "http://10.71.38.25:8000")!

    //the logged-in user's session token. AuthManager sets it after login (and clears it on logout),
    //and every request below sends it in the Authorization header
    static var authToken: String?

    //query = things after the "?" in the URL, e.g. [URLQueryItem(name: "state", value: "abc")]
    static func get<Response: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> Response {
        var url = baseURL.appendingPathComponent(path)
        if !query.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = query
            url = components?.url ?? url
        }
        return try await send(URLRequest(url: url))
    }

    static func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request)
    }

    static func put<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request)
    }

    static func delete<Response: Decodable>(_ path: String) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "DELETE"
        return try await send(request)
    }

    private static func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        var request = request
        if let authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.cantReachServer
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            //FastAPI errors look like {"detail": "..."}, so show just the message when there is one
            let detail = (try? JSONDecoder().decode(ErrorDetail.self, from: data))?.detail
            if http.statusCode == 401 {
                let reason = detail ?? "Please sign in again"
                if authToken != nil {
                    NotificationCenter.default.post(name: .loginExpired, object: reason)
                }
                throw APIError.notLoggedIn(reason)
            }
            throw APIError.badStatus(http.statusCode, detail ?? String(data: data, encoding: .utf8) ?? "")
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private struct ErrorDetail: Decodable { let detail: String }
}
