# Restaurant: Integrating EZNetworking into an App

Integrate EZNetworking into an iOS app for downloading and uploading content.

@Metadata {
    @CallToAction(purpose: link, url: "https://github.com/gomez1112/EZNetworking")
    @PageKind(sampleCode)
    @PageImage(purpose: card, source: "restaurantCardImage", alt: "Two people eating")
}

## Overview

This sample creates _Restaurant_, an app for representing food from a restaurant. The app demonstrates how to integrate EZNetworking to fetch menu data from a remote API, handle network errors gracefully, and display restaurant information in a SwiftUI interface.

The Restaurant app showcases:
- Making asynchronous network requests using EZNetworking's `Client` actor
- Decoding JSON responses into Swift model types
- Handling network errors with proper user feedback
- Integrating network operations with SwiftUI's async/await patterns
- Creating custom API requests for restaurant-specific endpoints

## Key Features

### Network Layer Integration
The app leverages EZNetworking's protocol-oriented design to create clean, maintainable network code:

```swift
import EZNetworking

actor RestaurantService {
    private let client = Client()
    
    func fetchMenu() async throws -> Menu {
        let request = GenericAPIRequest<Menu>(
            baseURL: "https://api.restaurant-demo.com",
            path: "/menu"
        )
        return try await client.fetchData(from: request)
    }
    
    func fetchRestaurantInfo() async throws -> Restaurant {
        let request = GenericAPIRequest<Restaurant>(
            baseURL: "https://api.restaurant-demo.com",
            path: "/info"
        )
        return try await client.fetchData(from: request)
    }
}
```

### Data Models
The app defines Codable models that represent restaurant data:

```swift
struct Restaurant: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let address: Address
    let cuisine: [String]
    let rating: Double
    let imageURL: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, address, cuisine, rating
        case imageURL = "image_url"
    }
}

struct Menu: Codable {
    let categories: [MenuCategory]
    let lastUpdated: Date
}

struct MenuCategory: Codable, Identifiable {
    let id: String
    let name: String
    let items: [MenuItem]
}

struct MenuItem: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let imageURL: String?
    let allergens: [String]
    let isVegetarian: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, price, allergens
        case imageURL = "image_url"
        case isVegetarian = "is_vegetarian"
    }
}

struct Address: Codable {
    let street: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    
    enum CodingKeys: String, CodingKey {
        case street, city, state, country
        case zipCode = "zip_code"
    }
}
```

### SwiftUI Integration
The app's user interface is built with SwiftUI and integrates seamlessly with EZNetworking's async/await patterns:

```swift
import SwiftUI
import EZNetworking

@MainActor
class RestaurantViewModel: ObservableObject {
    @Published var restaurant: Restaurant?
    @Published var menu: Menu?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let restaurantService = RestaurantService()
    
    func loadRestaurantData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let restaurantData = restaurantService.fetchRestaurantInfo()
            async let menuData = restaurantService.fetchMenu()
            
            self.restaurant = try await restaurantData
            self.menu = try await menuData
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct ContentView: View {
    @StateObject private var viewModel = RestaurantViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading restaurant data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(message: errorMessage) {
                        Task {
                            await viewModel.loadRestaurantData()
                        }
                    }
                } else {
                    RestaurantView(
                        restaurant: viewModel.restaurant,
                        menu: viewModel.menu
                    )
                }
            }
            .navigationTitle("Restaurant")
            .task {
                await viewModel.loadRestaurantData()
            }
        }
    }
}
```

### Error Handling
The app implements comprehensive error handling using EZNetworking's `APIError` enum:

```swift
struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

### Custom Networking Configuration
The app demonstrates how to customize EZNetworking's `Client` with specific requirements:

```swift
extension RestaurantService {
    static func createClient() -> Client {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return Client(decoder: decoder)
    }
}
```

## Architecture Benefits

### Actor-Based Safety
By using EZNetworking's `Client` actor, the Restaurant app ensures thread-safe network operations without data races or concurrent access issues.

### Protocol-Oriented Design
The app leverages EZNetworking's protocol-based architecture to create testable, flexible network code that can be easily mocked for unit testing.

### Swift Concurrency Integration
The seamless integration with async/await patterns makes the code more readable and maintainable compared to traditional callback-based networking.

## Testing
The Restaurant app includes comprehensive testing using Swift Testing framework:

```swift
import Testing
@testable import Restaurant
@testable import EZNetworking

@Suite("Restaurant Service Tests")
struct RestaurantServiceTests {
    
    @Test("Fetch menu successfully")
    func fetchMenuSuccess() async throws {
        let mockClient = MockClient()
        let service = RestaurantService(client: mockClient)
        
        let menu = try await service.fetchMenu()
        
        #expect(menu.categories.count > 0)
        #expect(menu.categories.first?.items.count > 0)
    }
    
    @Test("Handle network error gracefully")
    func handleNetworkError() async {
        let mockClient = MockClient(shouldFail: true)
        let service = RestaurantService(client: mockClient)
        
        do {
            _ = try await service.fetchMenu()
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            #expect(error is APIError)
        }
    }
}

final class MockClient: NetworkService {
    let shouldFail: Bool
    
    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }
    
    func fetchData<T: APIRequest>(from request: T) async throws -> T.Response where T.Response: Codable & Sendable {
        if shouldFail {
            throw APIError.networkError
        }
        
        // Return mock data based on request type
        if T.Response.self == Menu.self {
            return mockMenuData() as! T.Response
        } else if T.Response.self == Restaurant.self {
            return mockRestaurantData() as! T.Response
        }
        
        throw APIError.unknownError
    }
    
    private func mockMenuData() -> Menu {
        // Return mock menu data
        Menu(
            categories: [
                MenuCategory(
                    id: "appetizers",
                    name: "Appetizers",
                    items: [
                        MenuItem(
                            id: "1",
                            name: "Bruschetta",
                            description: "Grilled bread with tomatoes and basil",
                            price: 8.99,
                            imageURL: nil,
                            allergens: ["gluten"],
                            isVegetarian: true
                        )
                    ]
                )
            ],
            lastUpdated: Date()
        )
    }
    
    private func mockRestaurantData() -> Restaurant {
        // Return mock restaurant data
        Restaurant(
            id: "1",
            name: "Sample Restaurant",
            description: "A great place to eat",
            address: Address(
                street: "123 Main St",
                city: "Anytown",
                state: "CA",
                zipCode: "12345",
                country: "USA"
            ),
            cuisine: ["Italian"],
            rating: 4.5,
            imageURL: "https://example.com/restaurant.jpg"
        )
    }
}
```

## Getting Started

To integrate EZNetworking into your own restaurant or food service app:

1. **Add EZNetworking to your project** using Swift Package Manager
2. **Define your data models** conforming to `Codable`
3. **Create a service layer** using EZNetworking's `Client` actor
4. **Integrate with SwiftUI** using `@StateObject` and async/await
5. **Implement error handling** with proper user feedback
6. **Add comprehensive tests** using mock networking

The Restaurant sample app provides a complete reference implementation showing best practices for integrating EZNetworking into a real-world iOS application.


