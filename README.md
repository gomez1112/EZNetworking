# EZNetworking

EZNetworking is a Swift package designed to simplify network requests and API interactions in your iOS and macOS applications. It provides a clean and easy-to-use abstraction over `URLSession` for handling HTTP requests, response decoding, and error handling.

## Features

- **Protocol-Oriented Design**: Leverage protocols like `APIRequest` and `HTTPDownloader` to create customizable network requests and responses.
- **Default Implementations**: Simplify your network code with default headers, body data, and HTTP method handling.
- **Customizable JSON Decoding**: Inject your own `JSONDecoder` to handle various decoding strategies.
- **Error Handling**: Comprehensive error handling with detailed localized error descriptions.
- **Extensible Request Building**: Create and modify API requests with flexible query items and HTTP methods.
- **Actor-Based Networking**: Utilize Swift's `actor` model to safely manage concurrent network requests.
- **Automatic Retry with Exponential Backoff**: Configure resilient requests with built-in retry policies and jittered delays.
- **In-Memory Response Caching**: Opt-in caching with TTL and manual cache clearing.

## Installation

### Swift Package Manager

To integrate EZNetworking into your project using Swift Package Manager, add the following dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/EZNetworking.git", from: "1.5.1")
]
```
## Usage

### Creating a Client
The Client actor is the primary component for making network requests. You can customize it with your own `HTTPDownloader` and `JSONDecoder` if needed.

```swift
import EZNetworking

let client = Client()

```
Or with custom configurations
```swift
let customDecoder = JSONDecoder()
customDecoder.dateDecodingStrategy = .iso8601

let client = Client(decoder: customDecoder)
```

### Making a Request
Create a request using `GenericAPIRequest`:
```swift
let url = "https://randomuser.me"
let path = "/api/"
let request = GenericAPIRequest<User>(baseURL: url, path: path)
```

### Fetching Data
Use the `Client` to fetch data from the API:
```swift
Task {
    do {
        let user = try await client.fetchData(from: request)
        print(user.results.first?.name.first ?? "No name")
    } catch {
        print("Failed to fetch data: \(error.localizedDescription)")
    }
}
```
### Using an API Key
If your API requires an API key, you can include it in the headers of your request:
```swift
let url = "https://api.example.com"
let path = "/data"
let headers = ["Authorization": "Bearer YOUR_API_KEY"]

let request = GenericAPIRequest<MyDataModel>(
    baseURL: url,
    path: path,
    headers: headers
)
```
### Using Query Items
If you need to include query parameters in your API request, you can use the queryItems property:
```swift
let url = "https://api.example.com"
let path = "/search"
let queryItems = [
    URLQueryItem(name: "query", value: "Swift"),
    URLQueryItem(name: "limit", value: "10")
]

let request = GenericAPIRequest<MySearchResults>(
    baseURL: url,
    path: path,
    queryItems: queryItems
)
```
### Error Handling
EZNetworking provides detailed error handling through the `APIError` enum:
```swift
enum APIError: Error, LocalizedError {
    case invalidURL
    case httpStatusCodeFailed(statusCode: Int, description: String)
    case decodingError(underlyingError: Error)
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .httpStatusCodeFailed(let statusCode, let description):
            return "HTTP request failed with status code \(statusCode): \(description)."
        case .decodingError(let underlyingError):
            return "Failed to decode the response: \(underlyingError)."
        case .networkError:
            return "There was a network error."
        case .unknownError:
            return "An unknown error has occurred."
        }
    }
}
```
### Retrying Requests with Backoff (New)
You can automatically retry failed requests with exponential backoff and jittered delays:
```swift
let retryPolicy = RetryPolicy(
    maximumAttempts: 4,
    initialDelay: .seconds(0.5),
    maximumDelay: .seconds(6),
    multiplier: 2,
    jitter: .fractional(0.2)
)

Task {
    do {
        let user = try await client.fetchData(from: request, retryPolicy: retryPolicy)
        print(user.results.first?.name.first ?? "No name")
    } catch {
        print("Request failed after retries: \(error.localizedDescription)")
    }
}
```
### Caching Responses (New)
You can enable in-memory caching with a TTL and clear it when needed:
```swift
let client = Client(cachePolicy: .memory(ttl: 60))

Task {
    let user = try await client.fetchData(from: request)
    print(user.results.first?.name.first ?? "No name")
}

Task {
    await client.clearCache()
}
```
### Testing
EZNetworking includes a simple testing setup to mock network responses:

```swift
import Testing
@testable import EZNetworking

final class Downloader: HTTPDownloader {
    func httpData(from url: URL) async throws -> Data {
        try await Task.sleep(for: .milliseconds(Int.random(in: 100...500)))
        return testUser
    }
    
    @Test
    func testClientDoesFetchUserData() async throws {
        let downloader = Downloader()
        let client = Client(downloader: downloader)
        let request = GenericAPIRequest<User>(baseURL: "https://randomuser.me", path: "/api/")
        let user = try await client.fetchData(from: request)
        #expect(user.results.count == 1)
    }
}
```
![Static Badge](https://img.shields.io/badge/platform-iOS%20%7C%20macOS-purple?style=flat&logo=swift&logoColor=purple) ![Static Badge](https://img.shields.io/badge/swift-6.0%20%7C%205.10%20%7C%205.9%20%7C%205.8-purple?style=flat&logo=swift&logoColor=purple)



## Contributing
Contributions are welcome! Please feel free to submit a pull request or open an issue to help improve EZNetworking.
