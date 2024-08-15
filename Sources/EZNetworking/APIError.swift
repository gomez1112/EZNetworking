//
//  APIError.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

/// An enumeration representing errors that can occur during an API request.
public enum APIError: Error, LocalizedError, Equatable {
    /// The URL provided was invalid.
    case invalidURL
    /// The HTTP request failed with a specific status code and description.
    /// - Parameters:
    ///   - statusCode: The HTTP status code that was returned.
    ///   - description: A human-readable description of the status code.
    case httpStatusCodeFailed(statusCode: Int, description: String)
    /// The response could not be decoded due to an underlying decoding error.
    /// - Parameter underlyingError: The error that occurred during decoding.
    case decodingError(underlyingError: Error)
    /// A network error occurred, typically due to connectivity issues.
    case networkError
    case unknownError
    
    /// Provides a localized description for the error, useful for displaying user-friendly error messages.
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
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
            case (.invalidURL, .invalidURL),
                (.networkError, .networkError),
                (.unknownError, .unknownError):
                return true
            case let (.httpStatusCodeFailed(code1, _), .httpStatusCodeFailed(code2, _)):
                return code1 == code2
            case (.decodingError, .decodingError):
                return true // Note: This doesn't compare the underlying errors
            default:
                return false
        }
    }
}
