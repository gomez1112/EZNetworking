import Foundation
import Testing
@testable import EZNetworking

// Mock HTTPDownloader for testing
struct MockHTTPDownloader: HTTPDownloader {
    var data: Data? = nil
    var error: Error? = nil

    func httpData(from request: URLRequest) async throws -> Data {
        if let error = error {
            throw error
        }
        return data ?? Data()
    }
}

actor CountingHTTPDownloader: HTTPDownloader {
    private var callCount = 0
    private let data: Data

    init(data: Data) {
        self.data = data
    }

    func httpData(from request: URLRequest) async throws -> Data {
        callCount += 1
        return data
    }

    func count() -> Int {
        callCount
    }
}

final class URLProtocolStub: URLProtocol {
    private static let idHeader = "X-URLProtocolStub-ID"

    private final class Storage: @unchecked Sendable {
        struct Entry {
            let response: URLResponse?
            let data: Data?
            let error: Error?
        }

        let lock = NSLock()
        var entries: [String: Entry] = [:]
    }

    private static let storage = Storage()

    static func setResponse(_ response: URLResponse?, data: Data?, error: Error?, for id: String) {
        storage.lock.lock()
        storage.entries[id] = Storage.Entry(response: response, data: data, error: error)
        storage.lock.unlock()
    }

    static func removeEntry(for id: String) {
        storage.lock.lock()
        storage.entries.removeValue(forKey: id)
        storage.lock.unlock()
    }

    private static func entry(for request: URLRequest) -> Storage.Entry {
        let id = request.value(forHTTPHeaderField: idHeader) ?? ""
        storage.lock.lock()
        let entry = storage.entries[id] ?? Storage.Entry(response: nil, data: nil, error: nil)
        storage.lock.unlock()
        return entry
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let entry = URLProtocolStub.entry(for: request)
        if let error = entry.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        if let response = entry.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        if let data = entry.data {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite("GenericAPIRequest Tests")
struct GenericAPIRequestTests {
    @Test("Initialize GenericAPIRequest with basic parameters")
    func testBasicInitialization() throws {
        let headers = ["Content-Type": "application/json"]
        let baseURL = "https://api.example.com/"
        let path = "users"
        let request = GenericAPIRequest<String>(baseURL: baseURL, path: path, headers: headers)
        
        #expect(request.url.deletingLastPathComponent().absoluteString == baseURL)
        #expect(request.method == .get)
        #expect(request.headers == headers)
        #expect(request.bodyData == nil)
    }
    @Test("Initialize GenericAPIRequest with all parameters")
    func testFullInitialization() throws {
        let queryItems = [URLQueryItem(name: "page", value: "1")]
        let headers = ["Authorization": "Bearer token"]
        let body = ["name": "John Doe"]
        
        let request = GenericAPIRequest<String>(
            baseURL: "https://api.example.com",
            path: "/users",
            queryItems: queryItems,
            method: .post,
            headers: headers,
            body: body
        )
        #expect(request.url.absoluteString == "https://api.example.com/users")
        #expect(request.queryItems?.count == 1)
        #expect(request.method == .post)
        #expect(request.headers?["Authorization"] == "Bearer token")
        #expect(request.bodyData != nil)
    }
    @Test("Add query item to GenericAPIRequest")
    func testAddQueryItem() throws {
        var request = GenericAPIRequest<String>(baseURL: "https://api.example.com", path: "/users")
        request.addQueryItem(URLQueryItem(name: "page", value: "1"))
        
        #expect(request.queryItems?.count == 1)
        #expect(request.queryItems?[0].name == "page")
        #expect(request.queryItems?[0].value == "1")
    }
}

@Suite("Client Tests")
struct ClientTests {
    @Test("Fetch data successfully")
    func testFetchDataSuccess() async throws {
        var mockDownloader = MockHTTPDownloader()
        mockDownloader.data = """
        {
            "name": "John Doe",
            "age": 30
        }
        """.data(using: .utf8)
        
        let client = Client(downloader: mockDownloader)
        let request = GenericAPIRequest<TestUser>(baseURL: "https://api.example.com", path: "/user")
        
        let user = try await client.fetchData(from: request)
        
        #expect(user.name == "John Doe")
        #expect(user.age == 30)
    }
    
    @Test("Fetch data with decoding error")
    func testFetchDataDecodingError() async throws {
        var mockDownloader = MockHTTPDownloader()
        mockDownloader.data = """
        {
            "invalid": "data"
        }
        """.data(using: .utf8)

        let client = Client(downloader: mockDownloader)
        let request = GenericAPIRequest<TestUser>(baseURL: "https://api.example.com", path: "/user")

        do {
            _ = try await client.fetchData(from: request)
            Issue.record("Expected decodingError to be thrown")
        } catch let error as APIError {
            if case .decodingError = error {
                // Test passed
            } else {
                Issue.record("Expected decodingError, but got \(error)")
            }
        }
    }

    @Test("Cache returns cached responses and clears on request")
    func testCacheBehavior() async throws {
        let payload = """
        {
            "name": "John Doe",
            "age": 30
        }
        """.data(using: .utf8) ?? Data()

        let downloader = CountingHTTPDownloader(data: payload)
        let client = Client(downloader: downloader, cachePolicy: .memory(ttl: 60))
        let request = GenericAPIRequest<TestUser>(baseURL: "https://api.example.com", path: "/user")

        _ = try await client.fetchData(from: request)
        _ = try await client.fetchData(from: request)
        let firstCount = await downloader.count()
        #expect(firstCount == 1)

        await client.clearCache()
        _ = try await client.fetchData(from: request)
        let secondCount = await downloader.count()
        #expect(secondCount == 2)
    }
}

@Suite("APIError Tests")
struct APIErrorTests {
    @Test("Error descriptions are user friendly")
    func testErrorDescriptions() {
        #expect(APIError.invalidURL.errorDescription == "The URL provided was invalid.")

        let httpError = APIError.httpStatusCodeFailed(statusCode: 404, description: "not found")
        #expect(httpError.errorDescription == "HTTP request failed with status code 404: not found.")

        let decoding = APIError.decodingError(underlyingError: NSError(domain: "Test", code: 1))
        #expect(decoding.errorDescription?.contains("Failed to decode the response") == true)

        #expect(APIError.networkError.errorDescription == "There was a network error.")
        #expect(APIError.unknownError.errorDescription == "An unknown error has occurred.")
    }
}

@Suite("RetryPolicy Tests")
struct RetryPolicyTests {
    @Test("Default retry predicate matches expected errors")
    func testDefaultRetryPredicate() {
        if #available(macOS 13.0, iOS 16.0, *) {
            #expect(RetryPolicy.defaultRetryPredicate(APIError.networkError) == true)
            #expect(RetryPolicy.defaultRetryPredicate(APIError.httpStatusCodeFailed(statusCode: 500, description: "server")) == true)
            #expect(RetryPolicy.defaultRetryPredicate(APIError.httpStatusCodeFailed(statusCode: 404, description: "client")) == false)
            #expect(RetryPolicy.defaultRetryPredicate(APIError.decodingError(underlyingError: NSError(domain: "Test", code: 2))) == false)
        }
    }

    @Test("Delay grows with attempts and respects caps")
    func testDelayProgression() {
        if #available(macOS 13.0, iOS 16.0, *) {
            let policy = RetryPolicy(maximumAttempts: 3, initialDelay: .seconds(1), maximumDelay: .seconds(2), multiplier: 2, jitter: .none)
            let first = policy.delay(afterAttempt: 1).components.seconds
            let second = policy.delay(afterAttempt: 2).components.seconds
            let third = policy.delay(afterAttempt: 3).components.seconds
            #expect(first == 1)
            #expect(second == 2)
            #expect(third == 2)
        }
    }
}

@Suite("URLSession Extension Tests")
struct URLSessionExtensionTests {
    @Test("Returns data for 200 responses")
    func testHTTPDataSuccess() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        let stubID = UUID().uuidString
        URLProtocolStub.setResponse(response, data: "ok".data(using: .utf8), error: nil, for: stubID)

        var request = URLRequest(url: url)
        request.setValue(stubID, forHTTPHeaderField: "X-URLProtocolStub-ID")
        let data = try await session.httpData(from: request)
        #expect(String(data: data, encoding: .utf8) == "ok")

        URLProtocolStub.removeEntry(for: stubID)
    }

    @Test("Throws for non-HTTP responses")
    func testHTTPDataNonHTTPResponse() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let url = URL(string: "https://example.com")!
        let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let stubID = UUID().uuidString
        URLProtocolStub.setResponse(response, data: Data(), error: nil, for: stubID)

        var request = URLRequest(url: url)
        request.setValue(stubID, forHTTPHeaderField: "X-URLProtocolStub-ID")
        do {
            _ = try await session.httpData(from: request)
            Issue.record("Expected APIError.networkError to be thrown")
        } catch let error as APIError {
            if case .networkError = error {
                #expect(true)
            } else {
                Issue.record("Expected networkError, but got \(error)")
            }
        }

        URLProtocolStub.removeEntry(for: stubID)
    }

    @Test("Throws for non-2xx responses")
    func testHTTPDataStatusCodeFailure() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)

        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil)
        let stubID = UUID().uuidString
        URLProtocolStub.setResponse(response, data: Data(), error: nil, for: stubID)

        var request = URLRequest(url: url)
        request.setValue(stubID, forHTTPHeaderField: "X-URLProtocolStub-ID")
        do {
            _ = try await session.httpData(from: request)
            Issue.record("Expected httpStatusCodeFailed to be thrown")
        } catch let error as APIError {
            if case .httpStatusCodeFailed(let statusCode, _) = error {
                #expect(statusCode == 500)
            } else {
                Issue.record("Expected httpStatusCodeFailed, but got \(error)")
            }
        }

        URLProtocolStub.removeEntry(for: stubID)
    }
}

// Helper structs for testing
struct TestUser: Codable {
    let name: String
    let age: Int
}
