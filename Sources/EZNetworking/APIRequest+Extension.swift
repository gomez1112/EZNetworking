//
//  APIRequest+Extension.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

/// An extension of the `APIRequest` protocol that provides default implementations for some properties and methods.
///
/// This extension simplifies the process of creating API requests by providing default headers, body data, and HTTP method.
/// It also includes a computed property to construct a `URLRequest` using the properties of the conforming type.

extension APIRequest {
    /// Default headers for the request.
    ///
    /// By default, the `Content-Type` is set to `application/json`, which is common for API requests that send or receive JSON data.
    
    public var headers: [String: String]? { ["Content-Type": "application/json"] }
    /// Default data for the request body.
    ///
    /// By default, no data is included in the request body, which is suitable for HTTP methods like `GET` that do not require a body.
    
    public var bodyData: Data? { nil }
    /// HTTP method to use for the request.
    ///
    /// The default HTTP method is `GET`, which is typically used for retrieving data from an API.
    
    public var method: HTTPMethod { .get }
    
    /// Constructs a `URLRequest` using the properties provided by the `APIRequest`.
    ///
    /// This computed property creates a `URLRequest` by combining the base URL, query items, HTTP method, headers, and body data specified in the conforming type.
    /// If the URL components cannot be resolved, or if the final URL cannot be constructed, the method returns `nil`.
    ///
    /// - Returns: A `URLRequest` object if the URL can be constructed, otherwise `nil`.
    
    public var urlRequest: URLRequest? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        
        // If there are query items, add them to the URL
        components.queryItems = queryItems
        guard let finalURL = components.url else { return nil }
        var request = URLRequest(url: finalURL)
        
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = bodyData
        return request
    }
}
