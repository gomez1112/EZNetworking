//
//  NetworkService.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

public protocol NetworkService {
    /// Fetches data from the provided API request.
    ///
    /// - Parameter request: The API request object.
    /// - Returns: The decoded response.
    /// - Throws: An error if the data cannot be fetched or decoded.
    func fetchData<T: APIRequest>(from request: T) async throws -> T.Response where T.Response: Codable
}
public protocol HTTPDownloader: Sendable {
    /// Downloads data from the provided URL.
    /// - Parameter url: The URL to download data from.
    /// - Returns: The downloaded data.
    /// - Throws: An error if the data cannot be downloaded.
    func httpData(from request: URLRequest) async throws -> Data
}
