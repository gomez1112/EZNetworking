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
        headers: [String: String]? = nil,
        httpBody: T? = nil // Optional body parameter
    ) {
        let baseURL = URL(string: baseURL)!
        self.url = baseURL.appendingPathComponent(path)
        self.queryItems = queryItems
        self.method = method
        self.headers = headers
        
        // Encode the body to JSON if provided
        if let httpBody = httpBody {
            self.postData = try? JSONEncoder().encode(httpBody)
        } else {
            self.postData = nil
        }
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
        headers: [String: String]? = nil,
        postData: Data? = nil
    ) {
        let baseURL = URL(string: baseURL)!
        self.url = baseURL.appendingPathComponent(path)
        self.queryItems = queryItems
        self.method = method
        self.headers = headers
        self.postData = postData
    }
    
    /// Adds a new query item to the existing query items.
    /// - Parameter item: The query item to add.
    public mutating func addQueryItem(_ item: URLQueryItem) {
        if self.queryItems == nil {
            self.queryItems = []
        }
        self.queryItems?.append(item)
    }
}
