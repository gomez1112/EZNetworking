import Foundation
import Testing
@testable import EZNetworking

final class Downloader: HTTPDownloader {
    func httpData(from url: URL) async throws -> Data {
        try await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...500_000_000))
        return testUser
    }
    @Test func testClientDoesFetchUserData() async throws {
        let downloader = Downloader()
        let client = Client(downloader: downloader)
        let url = "https://randomuser.me"
        let path = "/api/"
        let request = GenericAPIRequest<User>(baseURL: url, path: path)
        let user = try await client.fetchData(from: request)
        #expect(user.results.count == 1)
    }
}

