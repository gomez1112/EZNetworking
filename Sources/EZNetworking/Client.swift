//
//  Client.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation

public actor Client: NetworkService {
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .deferredToDate
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    private let downloader: any HTTPDownloader
    
    public init(downloader: any HTTPDownloader = URLSession.shared) {
        self.downloader = downloader
    }
    private func decodeData<T: Codable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw APIError.decodingError(underlyingError: error)
        }
        catch {
            throw APIError.unknownError
        }
    }
    private func downloadData<T: APIRequest>(from request: T) async throws -> Data {
        guard let url = request.urlRequest?.url else { throw APIError.invalidURL }
        return try await downloader.httpData(from: url)
    }
    public func fetchData<T: APIRequest>(from request: T) async throws -> T.Response where T.Response: Codable & Sendable {
        let data = try await downloadData(from: request)
        return try decodeData(data)
    }
}
