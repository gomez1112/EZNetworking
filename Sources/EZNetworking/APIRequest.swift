//
//  APIRequest.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

/// A protocol that represents a network API request.
///
/// Conforming types are expected to provide necessary details for constructing
/// a `URLRequest` that can be sent over the network. This includes the base URL,
/// HTTP method, headers, query items, and any data to be sent in the body of the request.
public protocol APIRequest: Sendable {
    /// The type of the response that will be returned by this API request.
    associatedtype Response: Codable
    /// The base URL components for the API request, which typically includes the scheme, host, and path.
    /// - Example: `https://api.example.com/v1/`
    var baseURLComponents: URLComponents { get }
    /// The query items to be included in the URL.
    /// - Example: `?query=example&limit=10`
    var queryItems: [URLQueryItem]? { get }
    /// The HTTP method to be used for the request, such as `GET`, `POST`, etc.
    var method: HTTPMethod { get }
    /// The HTTP headers to be included in the request.
    /// - Example: `["Authorization": "Bearer token"]`
    var headers: [String: String]? { get }
    /// The data to be sent in the body of the request, typically for `POST` or `PUT` requests.
    var postData: Data? { get }
}
/// An enumeration representing the various HTTP methods that can be used in a network request.
///
/// Each case corresponds to a standard HTTP method, such as `GET`, `POST`, `PUT`, etc.
public enum HTTPMethod: String, Sendable {
    case delete = "DELETE"
    case get = "GET"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
    
}
