//
//  NetworkMiddleware.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 4/2/26.
//

import Foundation

/// The response payload returned by a downloader or middleware.
public struct HTTPResponsePayload: Sendable {
    public let data: Data
    public let response: URLResponse?

    public init(data: Data, response: URLResponse?) {
        self.data = data
        self.response = response
    }
}

/// The response context passed through middleware after a request completes.
public struct NetworkResponseContext: Sendable {
    public let request: URLRequest
    public let data: Data
    public let response: URLResponse?

    public init(request: URLRequest, data: Data, response: URLResponse?) {
        self.request = request
        self.data = data
        self.response = response
    }

    public func replacing(data: Data) -> NetworkResponseContext {
        NetworkResponseContext(request: request, data: data, response: response)
    }
}

/// A middleware component that can adapt requests and preprocess responses.
public protocol NetworkMiddleware: Sendable {
    /// Mutates a request before it is sent to the downloader.
    func prepare(_ request: URLRequest) async throws -> URLRequest

    /// Processes a response payload before decoding.
    func process(_ context: NetworkResponseContext) async throws -> NetworkResponseContext
}

public extension NetworkMiddleware {
    func prepare(_ request: URLRequest) async throws -> URLRequest {
        request
    }

    func process(_ context: NetworkResponseContext) async throws -> NetworkResponseContext {
        context
    }
}
