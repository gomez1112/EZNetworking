//
//  URLSession+Extension.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

/// Extends `URLSession` to conform to the `HTTPDownloader` protocol, enabling it to be used for downloading data asynchronously.
extension URLSession: HTTPDownloader {
    /// Downloads data asynchronously from the specified URL.
    ///
    /// This method uses the `URLSession`'s `data(from:)` method to perform the network request and handle the response. It checks the response to ensure it is an HTTP response and that the status code indicates success.
    ///
    /// - Parameter url: The URL from which to download data.
    /// - Returns: The downloaded data if the request is successful.
    /// - Throws: An `APIError.networkError` if the response is not an HTTP response, or `APIError.httpStatusCodeFailed` if the HTTP status code indicates a failure.
    public func httpData(from url: URL) async throws -> Data {
        let (data, response) = try await data(from: url)
        // Ensure the response is an HTTP response
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.networkError }
        // Check that the HTTP status code is within the success range (200...299)
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpStatusCodeFailed(statusCode: httpResponse.statusCode, description: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
        }
        // Return the downloaded data
        return data
    }
}
