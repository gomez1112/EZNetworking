//
//  GenericAPIRequest.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

public struct GenericAPIRequest<Response: Codable>: APIRequest {
    public var baseURLComponents: URLComponents
    public var queryItems: [URLQueryItem]?
    public var method: HTTPMethod
    public var headers: [String : String]?
    public var postData: Data?
    
    public init<T: Codable>(
        baseURL: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        body: T? = nil // Optional body parameter
    ) {
        var components = URLComponents(string: baseURL)!
        components.path = path
        self.baseURLComponents = components
        self.queryItems = queryItems
        self.method = method
        self.headers = headers
        
        // Encode the body to JSON if provided
        if let body = body {
            self.postData = try? JSONEncoder().encode(body)
        } else {
            self.postData = nil
        }
    }
    
    // Existing initializer without a body
    public init(
        baseURL: String,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        postData: Data? = nil
    ) {
        var components = URLComponents(string: baseURL)!
        components.path = path
        self.baseURLComponents = components
        self.queryItems = queryItems
        self.method = method
        self.headers = headers
        self.postData = postData
    }
}
