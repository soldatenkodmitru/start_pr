//
//  MovieManager.swift
//  TestForInterview
//
//  Created by Dmytro Soldatenko on 10.09.2025.
//
import Foundation

// MARK: - Networking Core
enum NetworkError: Error {
    case invalidURL
    case requestFailed(underlying: Error)
    case badStatus(code: Int, data: Data?)
    case decodingFailed(underlying: Error)
}

private struct TMDBConfig {

    static var bearerToken: String {
        return Helper.apiKey
    }

    static let baseURL = URL(string: "https://api.themoviedb.org/3")!
}
// Using TMDB v4 Bearer auth via Authorization header; no api_key in query params
private enum Endpoint {
    case topRated(page: Int)
    case search(query: String)

    var path: String {
        switch self {
        case .topRated: return "/movie/top_rated"
        case .search:   return "/search/movie"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .topRated(let page):
            return [
                URLQueryItem(name: "page", value: String(page))
            ]
        case .search(let query):
            return [
                URLQueryItem(name: "query", value: query)
            ]
        }
    }

    func urlRequest() throws -> URLRequest {
        var comps = URLComponents(url: TMDBConfig.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        comps?.queryItems = queryItems
        guard let url = comps?.url else { throw NetworkError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Bearer \(TMDBConfig.bearerToken)", forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 20
        return req
    }
}

private final class APIClient {
    static let shared = APIClient()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 40
        self.session = URLSession(configuration: config)
    }

    // Completion-based generic fetch
    func fetch<T: Decodable>(_ endpoint: Endpoint, completion: @escaping (Result<T, NetworkError>) -> Void) {
        let request: URLRequest
        do {
            request = try endpoint.urlRequest()
        } catch {
            completion(.failure(.invalidURL)); return
        }
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(underlying: error))); return
            }
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(.badStatus(code: -1, data: data))); return
            }
            guard (200...299).contains(http.statusCode) else {
                completion(.failure(.badStatus(code: http.statusCode, data: data))); return
            }
            guard let data = data else {
                completion(.failure(.badStatus(code: -1, data: nil))); return
            }
            let decoder = JSONDecoder()
            do {
                let decoded = try decoder.decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(.decodingFailed(underlying: error)))
            }
        }
        task.resume()
    }
}

// Thin façade over the APIClient
struct MovieManager {
    
    func fetchMovies(page: Int = 1, completion: @escaping (MovieModel) -> ()) {
        APIClient.shared.fetch(.topRated(page: page)) { (result: Result<MovieModel, NetworkError>) in
            switch result {
            case .success(let model):
                completion(model)
            case .failure(let error):
                print("[TopRated] error: \(error)")
            }
        }
    }
    
    func searchMovies(query: String, completion: @escaping (MovieModel) -> ()) {
        APIClient.shared.fetch(.search(query: query)) { (result: Result<MovieModel, NetworkError>) in
            switch result {
            case .success(let model):
                completion(model)
            case .failure(let error):
                print("[Search] error: \(error)")
            }
        }
    }
}
