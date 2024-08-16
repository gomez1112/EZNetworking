import Foundation
import Testing
@testable import EZNetworking

// Mock HTTPDownloader for testing
class MockHTTPDownloader: HTTPDownloader, @unchecked Sendable {
    var data: Data? = nil
    var error: Error? = nil
    
    func httpData(from request: URLRequest) async throws -> Data {
        if let error = error {
            throw error
        }
        return data ?? Data()
    }
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
        let mockDownloader = MockHTTPDownloader()
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
        let mockDownloader = MockHTTPDownloader()
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
}
// Helper structs for testing
struct TestUser: Codable {
    let name: String
    let age: Int
}
