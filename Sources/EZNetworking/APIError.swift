//
//  APIError.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

public enum APIError: Error, LocalizedError {
    case invalidURL
    case httpStatusCodeFailed(statusCode: Int, description: String)
    case decodingError(underlyingError: Error)
    case networkError
    case unknownError
    
    public var errorDescription: String? {
        switch self {
            case .invalidURL:
                return "The URL provided was invalid."
            case .httpStatusCodeFailed(let statusCode, let description):
                return "HTTP request failed with status code \(statusCode): \(description)."
            case .decodingError(let underlyingError):
                return "Failed to decode the response: \(underlyingError)."
            case .networkError:
                return "There was a network error."
            case .unknownError:
                return "An unknown error has occurred."
        }
    }
}
