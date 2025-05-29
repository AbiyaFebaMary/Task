//
//  APIService.swift
//  SwiftUITask
//
//  Created by AbiyaFeba on 28/05/25.
//

import Foundation
import Combine

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case requestFailed(String)
    case responseFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .responseFailed(let message):
            return "Response failed: \(message)"
        }
    }
}

// MARK: - API Service
final class APIService {
    // MARK: - Properties
    private let baseURL = "https://aes.shenlu.me/api/v1"
    private let jsonDecoder = JSONDecoder()
    private let session = URLSession.shared
    
    // MARK: - Endpoints
    private enum Endpoint {
        case species
        
        var path: String {
            switch self {
            case .species:
                return "/species"
            }
        }
    }
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Private Methods
    private func makeRequest(for endpoint: Endpoint) -> URLRequest? {
        guard let url = URL(string: baseURL + endpoint.path) else {
            return nil
        }
        
        return URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
    }
    
    // MARK: - Public Methods
    func fetchSpecies() -> AnyPublisher<[Species], Error> {
        guard let request = makeRequest(for: .species) else {
            return Fail(error: APIError.requestFailed("Invalid URL")).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { [weak self] data, response -> Data in
                guard let _ = self else { throw APIError.requestFailed("Self is nil") }
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.requestFailed("No HTTP response")
                }
                
                if httpResponse.statusCode >= 400 {
                    throw APIError.responseFailed("Server error with code: \(httpResponse.statusCode)")
                }
                
                #if DEBUG
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                }
                #endif
                
                return data
            }
            .decode(type: [Species].self, decoder: jsonDecoder)
            .mapError { error in
                #if DEBUG
                print("Error: \(error)")
                #endif
                
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    return APIError.responseFailed("Failed to decode response: \(error.localizedDescription)")
                } else {
                    return APIError.requestFailed(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
    
    @available(iOS 15.0, *)
    func fetchSpeciesAsync() async throws -> [Species] {
        guard let request = makeRequest(for: .species) else {
            throw APIError.requestFailed("Invalid URL")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.requestFailed("No HTTP response")
            }
            
            if httpResponse.statusCode >= 400 {
                throw APIError.responseFailed("Server error with code: \(httpResponse.statusCode)")
            }
            
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }
            #endif
            
            do {
                return try jsonDecoder.decode([Species].self, from: data)
            } catch {
                #if DEBUG
                print("Decoding error: \(error)")
                #endif
                throw APIError.responseFailed("Failed to decode response: \(error.localizedDescription)")
            }
        } catch {
            if let apiError = error as? APIError {
                throw apiError
            } else {
                #if DEBUG
                print("Network error: \(error)")
                #endif
                throw APIError.requestFailed("Network error: \(error.localizedDescription)")
            }
        }
    }
}
