//
//  Client.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation
/// An actor responsible for managing network requests and decoding responses.
///
/// The `Client` actor provides a safe and efficient way to fetch data from APIs,
/// ensuring that network requests and response decoding are performed in a thread-safe manner.
public actor Client: NetworkService {
    /// The `JSONDecoder` instance used for decoding responses.
    /// This can be customized to allow different decoding strategies.
    private let decoder: JSONDecoder
    /// The downloader responsible for fetching data from URLs.
    /// The default implementation uses `URLSession`, but any type conforming to `HTTPDownloader` can be used.
    private let downloader: any HTTPDownloader
    
    /// Initializes a new client instance.
    /// - Parameters:
    ///   - downloader: The downloader to use for HTTP requests. Defaults to `URLSession.shared`.
    ///   - decoder: A custom `JSONDecoder` to use for decoding responses. Defaults to a decoder with `deferredToDate` and `convertFromSnakeCase` strategies.
    public init(downloader: any HTTPDownloader = URLSession.shared, decoder: JSONDecoder = JSONDecoder()) {
        self.downloader = downloader
        self.decoder = decoder
        // Set default decoding strategies if not provided
        self.decoder.dateDecodingStrategy = .deferredToDate
        self.decoder.keyDecodingStrategy = .useDefaultKeys
    }
    /// Decodes the provided data into the specified type using the configured `JSONDecoder`.
    ///
    /// - Parameter data: The data to decode.
    /// - Returns: The decoded object of type `T`.
    /// - Throws: An `APIError.decodingError` if the data cannot be decoded.
    public func decode<T: Codable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw APIError.decodingError(underlyingError: error)
        }
        catch {
            throw APIError.unknownError
        }
    }
    /// Downloads data for the given API request.
    ///
    /// - Parameter request: The API request to download data for.
    /// - Returns: The downloaded data.
    /// - Throws: An `APIError.invalidURL` if the URL is invalid, or other errors related to the network or HTTP status.
    private func downloadData<T: APIRequest>(for request: T) async throws -> Data {
        guard let urlRequest = request.urlRequest else { throw APIError.invalidURL }
        return try await downloader.httpData(from: urlRequest)
    }
    /// Fetches data from the provided API request and decodes it into the specified response type.
    ///
    /// - Parameter request: The API request object.
    /// - Returns: The decoded response object of the associated type `T.Response`.
    /// - Throws: An error if the data cannot be fetched or decoded.
    public func fetchData<T: APIRequest>(from request: T) async throws -> T.Response where T.Response: Codable & Sendable {
        let data = try await downloadData(for: request)
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw Response Data: \(jsonString)")
        } else {
            print("Failed to convert data to string")
        }
        
        return try decode(data)
    }
}
