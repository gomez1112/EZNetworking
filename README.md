# EZNetworking

EZNetworking is a small Swift package for building HTTP clients without repeating `URLSession` boilerplate. It handles request construction, response validation, JSON decoding, raw data downloads, retries, in-memory caching, and middleware.

## Features

- Simple `Client(baseURL:)` setup for API services.
- Direct JSON helpers with `client.fetch(path:)`.
- Raw byte helpers with `client.data(path:)` for images, files, and empty responses.
- `Decodable` response models with no required `Sendable`, `Codable`, `nonisolated`, or `@preconcurrency` app-side workarounds.
- Encodable request bodies with optional custom `JSONEncoder`.
- Typed `APIError` failures for invalid URLs, HTTP status codes, decoding, encoding, and network errors.
- Optional retry policies with exponential backoff and jitter.
- Optional in-memory response caching with TTL.
- Middleware for auth, signing, request adaptation, response preprocessing, analytics, and envelope unwrapping.
- Testable networking through `HTTPDownloader`.

## Installation

Add EZNetworking with Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/EZNetworking.git", from: "1.5.1")
]
```

Then add `EZNetworking` to your target dependencies.

## Quick Start

```swift
import Foundation
import EZNetworking

struct Habit: Decodable {
    let name: String
    let category: Category
    let info: String
}

struct Category: Decodable {
    let name: String
    let color: HSBColor
}

struct HSBColor: Decodable {
    let h: Double
    let s: Double
    let b: Double
}

let client = try Client(baseURL: "http://localhost:8080")

let habits: [Habit] = try await client.fetch(path: "habits")
```

Your response models only need to be `Decodable`.

## A Complete Service Example

```swift
import Foundation
import EZNetworking

final class HabitService {
    private let client: Client

    init(client: Client) {
        self.client = client
    }

    func fetchHabits() async throws -> ActivityDictionary {
        try await client.fetch(path: HabitEndpoint.habits.path)
    }

    func fetchUsers() async throws -> UserDictionary {
        try await client.fetch(path: HabitEndpoint.users.path)
    }

    func fetchImageData(named imageName: String) async throws -> Data {
        try await client.data(path: HabitEndpoint.images(imageName).path, headers: nil)
    }

    func fetchUserStats(ids: [String]? = nil) async throws -> UserHabitDataList {
        try await client.fetch(
            path: HabitEndpoint.userStats.path,
            queryItems: .commaSeparated(name: "ids", values: ids)
        )
    }

    func fetchHabitStats(names: [String]? = nil) async throws -> HabitUserDataList {
        try await client.fetch(
            path: HabitEndpoint.habitStats.path,
            queryItems: .commaSeparated(name: "names", values: names)
        )
    }

    func fetchCombinedStats() async throws -> CombinedStatisticsResponse {
        try await client.fetch(path: HabitEndpoint.combinedStats.path)
    }

    func fetchLeadingStats(for userID: String) async throws -> UserHabitData {
        try await client.fetch(path: HabitEndpoint.userLeadingStats(userID).path)
    }

    func logHabit(userID: String, habitName: String, timestamp: Date = Date()) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        _ = try await client.data(
            path: HabitEndpoint.loggedHabit.path,
            body: LoggedHabit(userID: userID, habitName: habitName, timestamp: timestamp),
            bodyEncoder: encoder
        )
    }
}

enum HabitEndpoint {
    case users
    case habits
    case images(String)
    case userStats
    case habitStats
    case combinedStats
    case userLeadingStats(String)
    case loggedHabit

    var path: String {
        switch self {
        case .users:
            "users"
        case .habits:
            "habits"
        case .images(let imageName):
            "images/\(imageName)"
        case .userStats:
            "userStats"
        case .habitStats:
            "habitStats"
        case .combinedStats:
            "combinedStats"
        case .userLeadingStats(let userID):
            "userLeadingStats/\(userID)"
        case .loggedHabit:
            "loggedhabit"
        }
    }
}
```

Usage:

```swift
do {
    let client = try Client(baseURL: "http://localhost:8080")
    let service = HabitService(client: client)
    let habits = try await service.fetchHabits()
    print(habits)
} catch {
    print(error.localizedDescription)
}
```

## Client Setup

Use a throwing string initializer when the base URL comes from configuration:

```swift
let client = try Client(baseURL: "https://api.example.com")
```

Use the non-throwing `URL` initializer when a caller already gives you a validated URL:

```swift
func makeClient(baseURL: URL) -> Client {
    Client(baseURL: baseURL)
}
```

Customize decoding:

```swift
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

let client = try Client(
    baseURL: "https://api.example.com",
    decoder: decoder
)
```

## Requests

Fetch decoded JSON:

```swift
let users: [User] = try await client.fetch(path: "users")
```

Add query items:

```swift
let results: SearchResults = try await client.fetch(
    path: "search",
    queryItems: [
        URLQueryItem(name: "query", value: "Swift"),
        URLQueryItem(name: "limit", value: "10")
    ]
)
```

Add headers:

```swift
let profile: Profile = try await client.fetch(
    path: "profile",
    headers: ["Authorization": "Bearer \(token)"]
)
```

Send an encodable body:

```swift
struct CreateHabitRequest: Encodable {
    let name: String
    let categoryID: String
}

struct CreateHabitResponse: Decodable {
    let id: String
    let name: String
}

let response: CreateHabitResponse = try await client.fetch(
    path: "habits",
    body: CreateHabitRequest(name: "Run", categoryID: "fitness")
)
```

Download raw data:

```swift
let imageData = try await client.data(path: "images/avatar.png", headers: nil)
```

Send a request that does not need a decoded response:

```swift
_ = try await client.data(
    path: "loggedhabit",
    body: LoggedHabit(userID: userID, habitName: habitName, timestamp: Date())
)
```

## Manual Request Objects

You can still build a `GenericAPIRequest` directly when that fits your architecture:

```swift
let request = try GenericAPIRequest<User>(
    baseURL: "https://api.example.com",
    path: "users/123"
)

let user = try await client.fetchData(from: request)
```

## Error Handling

EZNetworking throws `APIError` for common failure modes:

```swift
do {
    let users: [User] = try await client.fetch(path: "users")
    print(users)
} catch APIError.invalidBaseURL(let url) {
    print("Invalid base URL: \(url)")
} catch APIError.invalidURL {
    print("Could not build the request URL.")
} catch APIError.httpStatusCodeFailed(let statusCode, let description) {
    print("HTTP \(statusCode): \(description)")
} catch APIError.decodingError(let underlyingError) {
    print("Decoding failed: \(underlyingError)")
} catch APIError.encodingError(let underlyingError) {
    print("Encoding failed: \(underlyingError)")
} catch APIError.networkError {
    print("Network request failed.")
} catch {
    print("Unexpected error: \(error)")
}
```

## Retry

```swift
let retryPolicy = RetryPolicy(
    maximumAttempts: 4,
    initialDelay: 0.5,
    maximumDelay: 6,
    multiplier: 2,
    jitter: .fractional(0.2)
)

let request = try client.request(User.self, path: "users/123")
let user = try await client.fetchData(from: request, retryPolicy: retryPolicy)
```

## Caching

```swift
let client = try Client(
    baseURL: "https://api.example.com",
    cachePolicy: .memory(ttl: 60)
)

let users: [User] = try await client.fetch(path: "users")
await client.clearCache()
```

By default, requests with authentication-related headers bypass the cache. You can opt in to stable header fields when they should participate in cache identity:

```swift
let client = try Client(
    baseURL: "https://api.example.com",
    cachePolicy: .memory(ttl: 60),
    cacheKeyConfiguration: CacheKeyConfiguration(
        includedHeaderFields: ["Accept-Language"]
    )
)
```

## Middleware

Middleware can adapt outbound requests and preprocess inbound responses.

```swift
struct AuthorizationMiddleware: NetworkMiddleware {
    let token: String

    func prepare(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}

struct User: Codable {
    let name: String
    let age: Int
}

struct UserEnvelopeMiddleware: NetworkMiddleware {
    struct Envelope: Decodable {
        let payload: User
    }

    func process(_ context: NetworkResponseContext) async throws -> NetworkResponseContext {
        let envelope = try JSONDecoder().decode(Envelope.self, from: context.data)
        let payloadData = try JSONEncoder().encode(envelope.payload)
        return context.replacing(data: payloadData)
    }
}
```

```swift
let client = try Client(
    baseURL: "https://api.example.com",
    middlewares: [
        AuthorizationMiddleware(token: token),
        UserEnvelopeMiddleware()
    ]
)
```

## Testing

Inject an `HTTPDownloader` to test without real network calls:

```swift
import Foundation
import Testing
@testable import EZNetworking

struct MockDownloader: HTTPDownloader {
    let data: Data

    func httpData(from request: URLRequest) async throws -> Data {
        data
    }
}

@Test
func clientFetchesUser() async throws {
    let data = Data("""
    {
        "name": "Jane Doe",
        "age": 28
    }
    """.utf8)

    let client = try Client(
        baseURL: "https://api.example.com",
        downloader: MockDownloader(data: data)
    )

    let user: User = try await client.fetch(path: "user")

    #expect(user.name == "Jane Doe")
    #expect(user.age == 28)
}
```

## Requirements

- Swift 6.2 tools
- iOS 15+
- macOS 12+

![Static Badge](https://img.shields.io/badge/platform-iOS%20%7C%20macOS-purple?style=flat&logo=swift&logoColor=purple)

## Contributing

Contributions are welcome. Open an issue or submit a pull request to help improve EZNetworking.
