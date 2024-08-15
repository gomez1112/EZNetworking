//
//  APIRequest.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

public protocol APIRequest: Sendable {
    associatedtype Response: Codable
    
    var baseURLComponents: URLComponents { get }
    var queryItems: [URLQueryItem]? { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var postData: Data? { get }
}

public enum HTTPMethod: String, Sendable {
    case delete, get, patch, post, put
    
    public var title: String {
        rawValue.uppercased()
    }
}
