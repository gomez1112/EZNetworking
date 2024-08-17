# Getting Started with EZNetworking

In this tutorial, you will learn how to use the EZNetworking package to make a simple API request.

@Metadata {
    @PageImage(purpose: card, source: "networkCardImage", alt: "The images of a network.")
}

## Step 1: Create a Request

First, create a `GenericAPIRequest` instance:

```swift
let request = GenericAPIRequest<String>(baseURL: "https://api.example.com", path: "/data")
```
## Step 2: Fetch Data

Next, use the `Client` actor to fetch data:
```swift
private let client = Client()
let response = try await client.fetchData(from: request)
```
## Step 3: Handle Errors

Finally, handle any errors that might occur during the request:

```swift
do {
let response = try await client.fetchData(from: request)
} catch let error as APIError {
print("Failed with error: \(error.localizedDescription)")
}
```
