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
    public var bodyData: Data? { nil }
    /// HTTP method to use for the request.
    public var method: HTTPMethod { .get }
    
    /// Constructs a `URLRequest` using the properties provided by the `APIRequest`.
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
        print("Final Request URL: \(request.url?.absoluteString ?? "NA")")
        print("Final HTTP Method: \(request.httpMethod ?? "NA")")
        print("Final Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let postData = request.httpBody, let jsonString = String(data: postData, encoding: .utf8) {
            print("Final Request Body: \(jsonString)")
        }
        return request
    }
}
