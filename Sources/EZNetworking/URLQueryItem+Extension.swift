//
//  URLQueryItem+Extension.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 5/25/26.
//

import Foundation

public extension URLQueryItem {
    /// Creates a query item whose value is a separated list of values.
    ///
    /// Returns `nil` when `values` is `nil` or empty, which is useful for optional filters.
    static func separated(
        name: String,
        values: [String]?,
        separator: String = ","
    ) -> URLQueryItem? {
        guard let values, !values.isEmpty else {
            return nil
        }
        return URLQueryItem(name: name, value: values.joined(separator: separator))
    }

    /// Creates a query item whose value is a comma-separated list of values.
    static func commaSeparated(name: String, values: [String]?) -> URLQueryItem? {
        separated(name: name, values: values, separator: ",")
    }
}

public extension Array where Element == URLQueryItem {
    /// Creates query items with a single comma-separated value.
    ///
    /// This returns `nil` when `values` is `nil` or empty so it can be passed directly
    /// to request APIs that accept optional query items.
    static func commaSeparated(name: String, values: [String]?) -> [URLQueryItem]? {
        URLQueryItem.commaSeparated(name: name, values: values).map { [$0] }
    }

    /// Creates query items with a single separated value.
    static func separated(
        name: String,
        values: [String]?,
        separator: String
    ) -> [URLQueryItem]? {
        URLQueryItem.separated(name: name, values: values, separator: separator).map { [$0] }
    }
}
