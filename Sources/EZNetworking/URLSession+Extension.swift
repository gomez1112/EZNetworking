//
//  URLSession+Extension.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

extension URLSession: HTTPDownloader {
    public func httpData(from url: URL) async throws -> Data {
        let (data, response) = try await data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.networkError }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpStatusCodeFailed(statusCode: httpResponse.statusCode, description: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
        }
        return data
    }
}
