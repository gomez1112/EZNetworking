//
//  NetworkService.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

public protocol NetworkService {
    func fetchData<T: APIRequest>(from request: T) async throws -> T.Response where T.Response: Codable
}
public protocol HTTPDownloader: Sendable {
    func httpData(from: URL) async throws -> Data
}
