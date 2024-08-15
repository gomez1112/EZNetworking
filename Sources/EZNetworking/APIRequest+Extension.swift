//
//  APIRequest+Extension.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

extension APIRequest {
    public var headers: [String: String]? { nil }
    public var postData: Data? { nil }
    public var method: HTTPMethod { .get }
    
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
