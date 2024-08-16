//
//  GenericAPIRequest.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

/// A generic structure for making API requests with custom response types.
public struct GenericAPIRequest<Response: Codable & Sendable>: APIRequest {
    public var url: URL
    public var queryItems: [URLQueryItem]?
    public var method: HTTPMethod
    public var headers: [String : String]?
    public var bodyData: Data?
    
    /// Initializes a new API request.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL as a string.
    ///   - path: The path to append to the base URL.
    ///   - queryItems: An optional array of query items to include in the URL.
    ///   - method: The HTTP method to use. Defaults to `GET`.
    ///   - headers: An optional dictionary of HTTP headers to include in the request.
    ///   - body: An optional body to include in the request, encoded as JSON.
    public init<T: Codable>(
        baseURL: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        method: HTTPMethod = .get,
        headers: [String: String]? = ["Content-Type": "application/json"],
        body: T? = nil // Optional body parameter
    ) {
        guard let base = URL(string: baseURL) else { fatalError("Invalid base URL")}
        self.url = base.appendingPathComponent(path)
        self.queryItems = queryItems
        self.method = method
        self.headers = headers
        self.bodyData = body.flatMap { try? JSONEncoder().encode($0)}
    }
    
    /// Initializes a new API request.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL as a string.
    ///   - path: The path to append to the base URL.
    ///   - queryItems: An optional array of query items to include in the URL.
    ///   - method: The HTTP method to use. Defaults to `GET`.
    ///   - headers: An optional dictionary of HTTP headers to include in the request.
    ///   - bodyData: Optional raw data to include in the request body.
    public init(
        baseURL: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        method: HTTPMethod = .get,
        headers: [String: String]? = ["Content-Type": "application/json"],
        bodyData: Data? = nil
    ) {
        self.url = URL(string: baseURL)!.appendingPathComponent(path)
        self.queryItems = queryItems
        self.method = method
        self.headers = headers
        self.bodyData = bodyData
    }
    
    /// Adds a new query item to the existing query items.
    ///
    /// - Parameter item: The query item to add.
    public mutating func addQueryItem(_ item: URLQueryItem) {
        if self.queryItems == nil {
            self.queryItems = []
        }
        self.queryItems?.append(item)
    }
}
