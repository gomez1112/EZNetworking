# EZNetworking

EZNetworking is a Swift package designed to simplify network requests and API interactions in your iOS and macOS applications. It provides a clean and easy-to-use abstraction over `URLSession` for handling HTTP requests, response decoding, and error handling.

## Features

- **Flexible Network Service**: Easily fetch data from APIs using a protocol-oriented approach.
- **Customizable JSON Decoding**: Inject your own `JSONDecoder` to handle various decoding strategies.
- **Error Handling**: Comprehensive error handling with detailed localized error descriptions.
- **Extensible Request Building**: Create and modify API requests with flexible query items and HTTP methods.

## Installation

### Swift Package Manager

To integrate EZNetworking into your project using Swift Package Manager, add the following dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/EZNetworking.git", from: "1.0.0")
]
```
## Usage

### Creating a Client
The `Client` actor is the primary component for making network requests. You can customize it with your own `HTTPDownloader` and `JSONDecoder` if needed.

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
### Testing
EZNetworking includes a simple testing setup to mock network responses:

```swift
import Testing
@testable import EZNetworking

final class Downloader: HTTPDownloader {
    func httpData(from url: URL) async throws -> Data {
        try await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...500_000_000))
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

## License
MIT License

Copyright (c) [2024] [Gerard Gomez]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
