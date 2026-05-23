//
//  CachePolicy.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 2/17/26.
//

import Foundation

public enum CachePolicy: Sendable {
    case none
    case memory(ttl: TimeInterval)
}

/// Configuration that controls which request details participate in response cache keys.
public struct CacheKeyConfiguration: Sendable {
    /// The default cache key behavior.
    public static let `default` = CacheKeyConfiguration()

    /// Header fields that should participate in cache identity.
    ///
    /// Header names are normalized case-insensitively.
    public let includedHeaderFields: Set<String>

    /// A Boolean value that indicates whether requests with authentication-related headers can be cached.
    public let allowsCachingAuthenticatedRequests: Bool

    /// Creates a cache key configuration.
    ///
    /// - Parameters:
    ///   - includedHeaderFields: Header fields that should participate in cache identity.
    ///   - allowsCachingAuthenticatedRequests: Whether authenticated requests can be cached.
    public init(
        includedHeaderFields: Set<String> = [],
        allowsCachingAuthenticatedRequests: Bool = false
    ) {
        self.includedHeaderFields = Set(includedHeaderFields.map(Self.normalizedHeaderFieldName))
        self.allowsCachingAuthenticatedRequests = allowsCachingAuthenticatedRequests
    }

    func cacheKey(for request: URLRequest) -> CacheKey? {
        let normalizedHeaders = Self.normalizedHeaders(from: request.allHTTPHeaderFields ?? [:])
        let hasSensitiveHeaders = normalizedHeaders.keys.contains { Self.sensitiveHeaderFields.contains($0) }

        guard allowsCachingAuthenticatedRequests || !hasSensitiveHeaders else {
            return nil
        }

        var selectedHeaderFields = includedHeaderFields
        if allowsCachingAuthenticatedRequests {
            selectedHeaderFields.formUnion(Self.sensitiveHeaderFields)
        }

        let cacheHeaders = normalizedHeaders.filter { selectedHeaderFields.contains($0.key) }
        return CacheKey(request: request, headers: cacheHeaders)
    }

    private static let sensitiveHeaderFields: Set<String> = [
        "authorization",
        "proxy-authorization",
        "cookie",
        "x-api-key",
        "api-key",
        "x-auth-token"
    ]

    private static func normalizedHeaderFieldName(_ field: String) -> String {
        field.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func normalizedHeaders(from headers: [String: String]) -> [String: String] {
        headers.reduce(into: [:]) { result, header in
            result[normalizedHeaderFieldName(header.key)] = header.value
        }
    }
}

actor MemoryResponseCache {
    struct Entry: Sendable {
        let data: Data
        let expiration: Date
    }

    private var storage: [CacheKey: Entry] = [:]

    func value(for key: CacheKey) -> Data? {
        guard let entry = storage[key] else {
            return nil
        }
        if entry.expiration < Date() {
            storage.removeValue(forKey: key)
            return nil
        }
        return entry.data
    }

    func insert(_ data: Data, for key: CacheKey, ttl: TimeInterval) {
        let expiration = Date().addingTimeInterval(ttl)
        storage[key] = Entry(data: data, expiration: expiration)
    }

    func removeAll() {
        storage.removeAll()
    }
}

struct CacheKey: Hashable, Sendable {
    let url: URL
    let method: String
    let headers: [String: String]
    let bodyHash: String?

    init(request: URLRequest, headers: [String: String]) {
        self.url = request.url ?? URL(string: "about:blank")!
        self.method = request.httpMethod ?? "GET"
        self.headers = headers
        if let body = request.httpBody {
            self.bodyHash = body.base64EncodedString()
        } else {
            self.bodyHash = nil
        }
    }
}
