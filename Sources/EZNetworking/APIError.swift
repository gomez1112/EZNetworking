//
//  APIError.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

/// An enumeration representing errors that can occur during an API request.
///
/// The `APIError` enum provides a set of cases that represent various errors that might be encountered
/// while making an API request, including invalid URLs, HTTP status code failures, decoding errors, and network issues.
///
/// - Conforms To: `Error`, `LocalizedError`
public enum APIError: Error, LocalizedError {
    /// The URL provided was invalid.
    ///
    /// This error occurs when an attempt is made to use a malformed or otherwise invalid URL for an API request.
    
    case invalidURL
    /// The HTTP request failed with a specific status code and description.
    ///
    /// This error is thrown when an HTTP request returns a status code that indicates a failure, such as 404 or 500.
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code that was returned.
    ///   - description: A human-readable description of the status code.
    
    case httpStatusCodeFailed(statusCode: Int, description: String)
    /// The response could not be decoded due to an underlying decoding error.
    ///
    /// This error is thrown when the data received from the API cannot be decoded into the expected model or data structure.
    ///
    /// - Parameter underlyingError: The error that occurred during decoding, providing more context for the failure.
    
    case decodingError(underlyingError: Error)
    /// A network error occurred, typically due to connectivity issues.
    ///
    /// This error occurs when there is a problem with the network connection, preventing the API request from completing.
    
    case networkError
    /// An unknown error has occurred.
    ///
    /// This error is a catch-all for any errors that do not fit into the other defined cases.
    
    case unknownError
    
    /// Provides a localized description for the error.
    ///
    /// This computed property returns a user-friendly error message that can be displayed to the user,
    /// based on the specific `APIError` case that occurred.
    
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
