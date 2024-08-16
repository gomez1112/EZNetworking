//
//  GenericAPIRequest.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

public struct GenericAPIRequest<Response: Codable>: APIRequest {
    public var url: URL
    public var queryItems: [URLQueryItem]?
    public var method: HTTPMethod
    public var headers: [String : String]?
    public var postData: Data?
    
    /// Initializes a new API request.
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
        httpBody: T? = nil // Optional body parameter
    ) {
        self.url = URL(string: baseURL)!.appendingPathComponent(path)
        self.queryItems = queryItems
        self.method = method
        self.headers = headers
        self.postData = httpBody.flatMap { try? JSONEncoder().encode($0)}
    }
    
    /// Initializes a new API request.
    /// - Parameters:
    ///   - baseURL: The base URL as a string.
    ///   - path: The path to append to the base URL.
    ///   - queryItems: An optional array of query items to include in the URL.
    ///   - method: The HTTP method to use. Defaults to `GET`.
    ///   - headers: An optional dictionary of HTTP headers to include in the request.
    ///   - postData: Optional raw data to include in the request body.
    public init(
        baseURL: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        method: HTTPMethod = .get,
        headers: [String: String]? = ["Content-Type": "application/json"],
        postData: Data? = nil
    ) {
        self.url = URL(string: baseURL)!.appendingPathComponent(path)
        self.queryItems = queryItems
        self.method = method
        self.headers = headers
        self.postData = postData
    }
    
    /// Adds a new query item to the existing query items.
    /// - Parameter item: The query item to add.
    public mutating func addQueryItem(_ item: URLQueryItem) {
        self.queryItems?.append(item)
    }
}
