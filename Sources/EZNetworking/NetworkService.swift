//
//  NetworkService.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

/// A protocol that defines a service responsible for fetching data from an API.
///
/// Types conforming to `NetworkService` are expected to handle the network requests and responses,
/// ensuring that data is fetched and decoded appropriately.
///
/// - Note: The `fetchData(from:)` method is asynchronous and throws an error if the data cannot be fetched or decoded.
public protocol NetworkService {
    /// Fetches data from the provided API request.
    ///
    /// This method takes an API request conforming to the `APIRequest` protocol and returns the decoded response.
    /// The response type must conform to `Codable` to ensure it can be decoded from the fetched data.
    ///
    /// - Parameter request: The API request object conforming to `APIRequest`.
    /// - Returns: The decoded response of type `T.Response`.
    /// - Throws: An error if the data cannot be fetched or decoded.
    func fetchData<T: APIRequest>(from request: T) async throws -> T.Response where T.Response: Codable
}
/// A protocol that defines a downloader responsible for retrieving data over HTTP.
///
/// Conforming types are expected to handle the downloading of data from a given URL, typically for use
/// in network-related operations.
///
/// - Note: The `httpData(from:)` method is asynchronous and throws an error if the data cannot be downloaded.
public protocol HTTPDownloader: Sendable {
    /// Downloads data from the provided URL.
    ///
    /// This method takes a `URLRequest` object and returns the downloaded data in the form of `Data`.
    /// It is designed to work asynchronously and handle errors that may occur during the download process.
    ///
    /// - Parameter request: The `URLRequest` object representing the URL to download data from.
    /// - Returns: The downloaded data in the form of `Data`.
    /// - Throws: An error if the data cannot be downloaded.
    func httpData(from request: URLRequest) async throws -> Data
}
