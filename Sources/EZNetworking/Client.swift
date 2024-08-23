//
//  Client.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation
import os
/// An actor responsible for managing network requests and decoding responses.
///
/// The `Client` actor provides a safe and efficient way to fetch data from APIs,
/// ensuring that network requests and response decoding are performed in a thread-safe manner.
/// By using an actor, the `Client` guarantees that all network operations are safely handled
/// in a concurrent environment, preventing data races and ensuring data consistency.

public actor Client: NetworkService {
    /// The `JSONDecoder` instance used for decoding responses.
    ///
    /// This decoder can be customized to allow different decoding strategies, such as handling different
    /// date formats or key naming conventions. By default, the decoder uses the `.deferredToDate` strategy
    /// for dates and the `.useDefaultKeys` strategy for keys.
    
    private let decoder: JSONDecoder
    /// The downloader responsible for fetching data from URLs.
    ///
    /// The default implementation uses `URLSession.shared` as the downloader, but any type conforming to
    /// the `HTTPDownloader` protocol can be provided. This allows for flexibility in how the data is fetched,
    /// such as using a mock downloader for testing purposes.
    
    private let downloader: any HTTPDownloader
    /// Initializes a new client instance.
    ///
    /// This initializer allows you to specify a custom downloader and decoder, providing flexibility in
    /// how the client handles network requests and data decoding.
    ///
    /// - Parameters:
    ///   - downloader: The downloader to use for HTTP requests. Defaults to `URLSession.shared`.
    ///   - decoder: A custom `JSONDecoder` to use for decoding responses. Defaults to a decoder with `deferredToDate` and `useDefaultKeys` strategies.
    
    public init(downloader: any HTTPDownloader = URLSession.shared, decoder: JSONDecoder = JSONDecoder()) {
        self.downloader = downloader
        self.decoder = decoder
        // Set default decoding strategies if not provided
        self.decoder.dateDecodingStrategy = .deferredToDate
        self.decoder.keyDecodingStrategy = .useDefaultKeys
        Logger.networking.info("Client initialized with custom decoder and downloader.")
    }
    /// Decodes the provided data into the specified type using the configured `JSONDecoder`.
    ///
    /// This method attempts to decode the given data into the expected type `T` using the `JSONDecoder`
    /// configured in the `Client`. If the decoding fails, it throws an `APIError.decodingError` with the
    /// underlying error.
    ///
    /// - Parameter data: The data to decode.
    /// - Returns: The decoded object of type `T`.
    /// - Throws: An `APIError.decodingError` if the data cannot be decoded, or `APIError.unknownError` for other unexpected errors.
    
    public func decode<T: Codable>(_ data: Data) throws -> T {
        do {
            let decodedObject = try decoder.decode(T.self, from: data)
            Logger.networking.debug("Decoded object: \(String(describing: decodedObject))")
            return decodedObject
        } catch let error as DecodingError {
            Logger.networking.error("Decoding error: \(error.localizedDescription, privacy: .public)")
            throw APIError.decodingError(underlyingError: error)
        }
        catch {
            throw APIError.unknownError
        }
    }
    /// Downloads data for the given API request.
    ///
    /// This private method constructs a `URLRequest` from the `APIRequest` and then uses the downloader
    /// to fetch the data. If the URL is invalid or other errors occur during the download, the method
    /// throws the appropriate `APIError`.
    ///
    /// - Parameter request: The API request to download data for.
    /// - Returns: The downloaded data.
    /// - Throws: An `APIError.invalidURL` if the URL is invalid, or other errors related to the network or HTTP status.
    
    private func downloadData<T: APIRequest>(for request: T) async throws -> Data {
        guard let urlRequest = request.urlRequest else {
            Logger.networking.error("Invalid URLRequest")
            throw APIError.invalidURL
        }
        let data = try await downloader.httpData(from: urlRequest)
        Logger.networking.debug("Downloaded data for \(urlRequest.url?.absoluteString ?? "unknown URL")")
        return data
        
    }
    /// Fetches data from the provided API request and decodes it into the specified response type.
    ///
    /// This method combines downloading the data and decoding it into the expected response type `T.Response`.
    /// It prints the raw response data as a string for debugging purposes, and throws an error if the data
    /// cannot be fetched or decoded.
    ///
    /// - Parameter request: The API request object.
    /// - Returns: The decoded response object of the associated type `T.Response`.
    /// - Throws: An error if the data cannot be fetched or decoded.
    
    public func fetchData<T: APIRequest>(from request: T) async throws -> T.Response where T.Response: Codable & Sendable {
        let data = try await downloadData(for: request)
        Logger.networking.debug("Data received: \(data.count) bytes")
        if let jsonString = String(data: data, encoding: .utf8) {
            Logger.networking.debug("Raw Response Data: \(jsonString)")
        } else {
            Logger.networking.error("Failed to convert data to string: privacy: .public)")
        }
        return try decode(data)
    }
}
