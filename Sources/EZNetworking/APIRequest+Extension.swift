//
//  APIRequest+Extension.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

extension APIRequest {
    /// Default headers for the request.
    public var headers: [String: String]? { nil }
    /// Default data for the request body.
    public var postData: Data? { nil }
    /// HTTP method to use for the request.
    public var method: HTTPMethod { .get }
    
    /// Constructs a `URLRequest` using the properties provided by the `APIRequest`.
    /// - Returns: A `URLRequest` object if the URL can be constructed, otherwise `nil`.
    public var urlRequest: URLRequest? {
        var components = baseURLComponents
        components.queryItems = queryItems
        
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if let headers = self.headers {
            request.allHTTPHeaderFields = headers
        }
        if let data = postData {
            request.httpBody = data
        }
        return request
    }
}
