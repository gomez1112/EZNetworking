//
//  APIRequest.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

/// A protocol that represents a network API request.
///
/// Conforming types are expected to provide the necessary details for constructing
/// a `URLRequest` that can be sent over the network. This includes the base URL,
/// HTTP method, headers, query items, and any data to be sent in the body of the request.
///
/// The `APIRequest` protocol defines the structure of a network request, ensuring that
/// all required components are specified for proper execution. Each API request must specify
/// the response type it expects, which must conform to both `Codable` and `Sendable`.

public protocol APIRequest: Sendable {
    /// The type of the response that will be returned by this API request.
    ///
    /// This associated type defines the expected response type for the API request. The response
    /// the network response and used in a concurrency-safe manner.
    
    associatedtype Response: Codable & Sendable
    /// The base URL for the API request, typically including the scheme, host, and path.
    ///
    /// This property represents the URL where the API request will be sent. It is expected to
    /// include the basic components such as scheme (e.g., `https`), host (e.g., `api.example.com`),
    /// and path (e.g., `/v1/resource`).
    ///
    /// - Example: `https://api.example.com/v1/`
    
    var url: URL { get }
    /// The query items to be included in the URL.
    ///
    /// This property allows you to specify any query parameters that should be appended to the URL.
    /// These are typically used to filter or limit the results returned by the API.
    ///
    /// - Example: `?query=example&limit=10`
    
    var queryItems: [URLQueryItem]? { get }
    /// The HTTP method to be used for the request, such as `GET`, `POST`, etc.
    ///
    /// This property specifies the HTTP method that should be used when sending the request.
    /// The method is represented by the `HTTPMethod` enum, which includes common methods like `GET`, `POST`, `PUT`, etc.
    
    var method: HTTPMethod { get }
    /// The HTTP headers to be included in the request.
    ///
    /// This property allows you to specify any additional headers that should be included in the request,
    /// such as authorization tokens or content-type specifications.
    ///
    /// - Example: `["Authorization": "Bearer token"]`
    
    var headers: [String: String]? { get }
    /// The data to be sent in the body of the request.
    ///
    /// This property allows you to specify any data that should be sent in the body of the request.
    /// This is typically used for `POST` or `PUT` requests where data needs to be sent to the server.
    
    var bodyData: Data? { get }
}

/// An enumeration representing the various HTTP methods that can be used in a network request.
///
/// Each case corresponds to a standard HTTP method, such as `GET`, `POST`, `PUT`, etc.
/// The `HTTPMethod` enum provides a type-safe way to specify the method for a network request.

public enum HTTPMethod: String, Sendable {
    case delete = "DELETE"
    case get = "GET"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
}
