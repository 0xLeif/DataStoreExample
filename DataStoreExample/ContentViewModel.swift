//
//  ContentViewModel.swift
//  DataStoreExample
//
//  Created by Leif on 7/22/23.
//

import DataStore
import Network
import SwiftUI

// https://jsonplaceholder.typicode.com/posts

/*
 {
     "userId": 1,
     "id": 1,
     "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
     "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto"
 }
 */
struct NetworkPost: Codable, Identifiable {
    let id: UInt
    let userId: UInt
    let title: String
    let body: String
}

struct DevicePost: OnDeviceData {
    let id: UInt
    let userID: UInt
    let title: String
    let body: String
    
    init(from: NetworkPost) {
        id = from.id
        userID = from.userId
        title = from.title
        body = from.body
    }

    init(stored: StoredPost) {
        id = stored.id
        userID = stored.userID
        title = stored.title
        body = stored.body
    }
}

class PostLoader: DataLoading {
    typealias LoadedData = NetworkPost
    typealias DeviceData = DevicePost

    enum LoadingError: Error {
        case missingPost(UInt)
    }

    let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!

    func load() async throws -> [NetworkPost] {
        let dataResponse = try await Network().get(url: url)

        guard let data = dataResponse.data else { return [] }

        let posts = try JSONDecoder().decode([NetworkPost].self, from: data)

        return posts
    }

    func load(id: UInt) async throws -> NetworkPost {
        let dataResponse = try await Network().get(url: url.appendingPathComponent("\(id)"))

        guard let data = dataResponse.data else { throw LoadingError.missingPost(id) }

        let post = try JSONDecoder().decode(NetworkPost.self, from: data)

        return post
    }
}

class MockPostLoader: PostLoader {
    override func load() async throws -> [NetworkPost] {
        [
            NetworkPost(id: 1, userId: 1, title: "Mock Title", body: "Mock Body")
        ]
    }

    override func load(id: UInt) async throws -> NetworkPost {
        NetworkPost(id: id, userId: 1, title: "Mock #\(id)", body: "Mock Body")
    }
}

struct StoredPost: StorableData {
    let id: UInt
    let userID: UInt
    let title: String
    let body: String

    init(from: DevicePost) {
        id = from.id
        userID = from.userID
        title = from.title
        body = from.body
    }
}

class ContentViewModel: ConsumingObservableObject {
    private let dataStore: DataStore<PostLoader, StoredPost>

    @Published var isLoading: Bool

    var posts: [DevicePost] {
        dataStore.fetch()
    }

    init(postLoader: PostLoader) {
        self.dataStore = DataStore(loader: postLoader)
        self.isLoading = false

        super.init()

        consume(object: dataStore)
    }

    func load() {
        isLoading = true

        Task {
            do {
                try await dataStore.load()

                await MainActor.run {
                    isLoading = false
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
