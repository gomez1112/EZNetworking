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

    init(request: URLRequest) {
        self.url = request.url ?? URL(string: "about:blank")!
        self.method = request.httpMethod ?? "GET"
        self.headers = request.allHTTPHeaderFields ?? [:]
        if let body = request.httpBody {
            self.bodyHash = body.base64EncodedString()
        } else {
            self.bodyHash = nil
        }
    }
}
