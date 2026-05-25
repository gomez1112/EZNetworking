//
//  Client.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 8/14/24.
//

import Foundation
import os
/// A thread-safe client responsible for managing network requests and decoding responses.
///
/// The `Client` provides a safe and efficient way to fetch data from APIs,
/// ensuring that network requests, caching, and response decoding are handled safely.

/// `Client` is sendable because its configuration is immutable, cache mutation is isolated
/// inside `MemoryResponseCache`, and access to the shared decoder is serialized by `decoderLock`.
public final class Client: NetworkService, @unchecked Sendable {
    /// The `JSONDecoder` instance used for decoding responses.
    ///
    /// This decoder can be customized to allow different decoding strategies, such as handling different
    /// date formats or key naming conventions. By default, the decoder uses the `.deferredToDate` strategy
    /// for dates and the `.useDefaultKeys` strategy for keys.
    
    private let decoder: JSONDecoder
    private let decoderLock = NSLock()
    private let cachePolicy: CachePolicy
    private let cacheKeyConfiguration: CacheKeyConfiguration
    private let responseCache: MemoryResponseCache?
    private let middlewares: [any NetworkMiddleware]
    /// The downloader responsible for fetching data from URLs.
    ///
    /// The default implementation uses `URLSession.shared` as the downloader, but any type conforming to
    /// the `HTTPDownloader` protocol can be provided. This allows for flexibility in how the data is fetched,
    /// such as using a mock downloader for testing purposes.
    
    private let downloader: any HTTPDownloader
    /// Initializes a new client instance.
    ///
    /// This initializer allows you to specify a custom downloader and decoder, providing flexibility in
    /// how the client handles network requests and data decoding.
    ///
    /// - Parameters:
    ///   - downloader: The downloader to use for HTTP requests. Defaults to `URLSession.shared`.
    ///   - decoder: A custom `JSONDecoder` to use for decoding responses. Defaults to a decoder with `deferredToDate` and `useDefaultKeys` strategies.
    ///   - cachePolicy: The response cache policy to use.
    ///   - cacheKeyConfiguration: The request fields used to build cache keys.
    ///   - middlewares: Middleware components that can adapt requests and preprocess responses.
    
    public init(
        downloader: any HTTPDownloader = URLSession.shared,
        decoder: JSONDecoder = Client.defaultDecoder(),
        cachePolicy: CachePolicy = .none,
        cacheKeyConfiguration: CacheKeyConfiguration = .default,
        middlewares: [any NetworkMiddleware] = []
    ) {
        self.downloader = downloader
        self.decoder = decoder
        self.cachePolicy = cachePolicy
        self.cacheKeyConfiguration = cacheKeyConfiguration
        self.middlewares = middlewares
        switch cachePolicy {
        case .none:
            self.responseCache = nil
        case .memory:
            self.responseCache = MemoryResponseCache()
        }
        Logger.networking.info("Client initialized with custom decoder and downloader.")
    }

    public static func defaultDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .deferredToDate
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }
    /// Decodes the provided data into the specified type using the configured `JSONDecoder`.
    ///
    /// This method attempts to decode the given data into the expected type `T` using the `JSONDecoder`
    /// configured in the `Client`. If the decoding fails, it throws an `APIError.decodingError` with the
    /// underlying error.
    ///
    /// - Parameter data: The data to decode.
    /// - Returns: The decoded object of type `T`.
    /// - Throws: An `APIError.decodingError` if the data cannot be decoded, or `APIError.unknownError` for other unexpected errors.
    
    public func decode<T: Decodable>(_ data: Data) throws -> T {
        decoderLock.lock()
        defer { decoderLock.unlock() }

        do {
            let decodedObject = try decoder.decode(T.self, from: data)
            Logger.networking.debug("Decoded response as \(String(describing: T.self), privacy: .public)")
            return decodedObject
        } catch let error as DecodingError {
            Logger.networking.error("Decoding error: \(error.localizedDescription, privacy: .public)")
            throw APIError.decodingError(underlyingError: error)
        }
        catch {
            throw APIError.unknownError
        }
    }
    /// Downloads data for the given API request.
    ///
    /// This private method constructs a `URLRequest` from the `APIRequest` and then uses the downloader
    /// to fetch the data. If the URL is invalid or other errors occur during the download, the method
    /// throws the appropriate `APIError`.
    ///
    /// - Parameter request: The API request to download data for.
    /// - Returns: The downloaded data.
    /// - Throws: An `APIError.invalidURL` if the URL is invalid, or other errors related to the network or HTTP status.
    
    private func downloadData<T: APIRequest>(for request: T) async throws -> Data {
        guard let urlRequest = request.urlRequest else {
            Logger.networking.error("Invalid URLRequest")
            throw APIError.invalidURL
        }
        let preparedRequest = try await applyRequestMiddlewares(to: urlRequest)
        let cacheKey = cacheKey(for: preparedRequest)

        if let cacheKey, let responseCache {
            if let cachedData = await responseCache.value(for: cacheKey) {
                Logger.networking.debug("Returning cached data for \(preparedRequest.url?.absoluteString ?? "unknown URL")")
                return cachedData
            }
        }

        let payload = try await downloadResponse(for: preparedRequest)
        let context = try await applyResponseMiddlewares(
            to: NetworkResponseContext(
                request: preparedRequest,
                data: payload.data,
                response: payload.response
            )
        )
        Logger.networking.debug("Downloaded data for \(preparedRequest.url?.absoluteString ?? "unknown URL")")

        if case .memory(let ttl) = cachePolicy, let cacheKey, let responseCache {
            await responseCache.insert(context.data, for: cacheKey, ttl: ttl)
        }
        return context.data
    }
    /// Fetches data from the provided API request and decodes it into the specified response type.
    ///
    /// This method combines downloading the data and decoding it into the expected response type `T.Response`.
    /// It logs response metadata for debugging purposes, and throws an error if the data cannot be fetched or decoded.
    ///
    /// - Parameter request: The API request object.
    /// - Returns: The decoded response object of the associated type `T.Response`.
    /// - Throws: An error if the data cannot be fetched or decoded.
    
    public func fetchData<T: APIRequest>(from request: T) async throws -> T.Response {
        let data = try await downloadData(for: request)
        Logger.networking.debug("Data received: \(data.count) bytes")
        return try decode(data)
    }

    public func fetchData<R: Decodable>(from request: GenericAPIRequest<R>) async throws -> R {
        let data = try await downloadData(for: request)
        Logger.networking.debug("Data received: \(data.count) bytes")
        return try decode(data)
    }

    public func clearCache() async {
        guard let responseCache else {
            return
        }
        await responseCache.removeAll()
    }

    /// Fetches data using a retry policy with exponential backoff.
    ///
    /// This method retries failed requests based on the provided `RetryPolicy`, including delays between attempts.
    ///
    /// - Parameters:
    ///   - request: The API request object.
    ///   - retryPolicy: The retry policy that controls attempt counts and delays.
    /// - Returns: The decoded response object of the associated type `T.Response`.
    /// - Throws: The last error encountered if all retry attempts fail.
    public func fetchData<T: APIRequest>(
        from request: T,
        retryPolicy: RetryPolicy
    ) async throws -> T.Response {
        var attempt = 1

        while true {
            do {
                return try await fetchData(from: request)
            } catch {
                guard attempt < retryPolicy.maximumAttempts, retryPolicy.shouldRetry(error) else {
                    throw error
                }

                let delay = retryPolicy.delay(afterAttempt: attempt)
                Logger.networking.info(
                    "Retrying request (attempt \(attempt + 1) of \(retryPolicy.maximumAttempts)) after \(delay) due to error: \(error.localizedDescription, privacy: .public)"
                )
                let nanoseconds = UInt64(max(0, delay) * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanoseconds)
                attempt += 1
            }
        }
    }

    private func applyRequestMiddlewares(to request: URLRequest) async throws -> URLRequest {
        var adaptedRequest = request
        for middleware in middlewares {
            adaptedRequest = try await middleware.prepare(adaptedRequest)
        }
        return adaptedRequest
    }

    private func cacheKey(for request: URLRequest) -> CacheKey? {
        guard case .memory(let ttl) = cachePolicy, ttl > 0 else {
            return nil
        }
        return cacheKeyConfiguration.cacheKey(for: request)
    }

    private func applyResponseMiddlewares(
        to context: NetworkResponseContext
    ) async throws -> NetworkResponseContext {
        var processedContext = context
        for middleware in middlewares {
            processedContext = try await middleware.process(processedContext)
        }
        return processedContext
    }

    private func downloadResponse(for request: URLRequest) async throws -> HTTPResponsePayload {
        if let responseDownloader = downloader as? any HTTPResponseDownloader {
            return try await responseDownloader.httpResponse(from: request)
        }

        let data = try await downloader.httpData(from: request)
        return HTTPResponsePayload(data: data, response: nil)
    }
}
