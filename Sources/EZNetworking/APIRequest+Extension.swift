//
//  APIRequest+Extension.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

extension APIRequest {
    /// Default headers for the request.
    public var headers: [String: String]? { ["Content-Type": "application/json"] }
    /// Default data for the request body.
    public var postData: Data? { nil }
    /// HTTP method to use for the request.
    public var method: HTTPMethod { .get }
    
    /// Constructs a `URLRequest` using the properties provided by the `APIRequest`.
    /// - Returns: A `URLRequest` object if the URL can be constructed, otherwise `nil`.
    public var urlRequest: URLRequest? {
        var url = (self as? GenericAPIRequest<Response>)?.url ?? URL(string: "")!
        
        // If there are query items, add them to the URL
        if let queryItems = (self as? GenericAPIRequest<Response>)?.queryItems {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryItems
            url = components?.url ?? url
        }
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
