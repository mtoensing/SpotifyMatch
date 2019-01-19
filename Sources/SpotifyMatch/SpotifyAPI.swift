import Foundation

private let kJSONDecoder = JSONDecoder()

struct SpotifyAPI {
    private let session = URLSession(configuration: .default)
    private let authToken: String

    init(authToken: String) {
        self.authToken = authToken
    }

    /// Search the Spotify API using the provided query.
    /// https://developer.spotify.com/documentation/web-api/reference/search/search/
    ///
    /// - parameter query:      Query as defined in the above reference page.
    /// - parameter completion: Closure called on completion with all songs that were successfully found.
    func search(for query: String, completion: @escaping (_ songs: [Song]) -> Void) {
        let parameters = ["q": query, "type": "track", "limit": "1"]
        self.get(url: URL(string: "https://api.spotify.com/v1/search")!, parameters: parameters) { data in
            let result = data.flatMap { try? kJSONDecoder.decode(SearchResultResponse.self, from: $0) }
            completion(result?.tracks.items ?? [])
        }
    }

    /// Adds the list of songs to the authenticated user's library.
    ///
    /// - parameter songs:      The songs to add to the library.
    /// - parameter completion: Closure called with a boolean indicating if the request was successful.
    func addToLibrary(_ tracks: [Song], completion: @escaping (_ success: Bool) -> Void) {
        let body = ["ids": tracks.map { $0.id }]
        self.put(url: URL(string: "https://api.spotify.com/v1/me/tracks")!, body: body,
                 completion: completion)
    }

    // MARK: - Private

    private func get(url: URL, parameters: [String: String], completion: @escaping (Data?) -> Void) {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        self.addAuthorization(to: &request)

        let task = self.session.dataTask(with: request) { data, response, _ in
            if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode != 200 {
                print("Error in GET request, status: \(statusCode)")
            }

            completion(data)
        }

        task.resume()
    }

    private func put(url: URL, body: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let data = try? JSONSerialization.data(withJSONObject: body, options: []) else {
            return completion(false)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        self.addAuthorization(to: &request)

        let task = self.session.dataTask(with: request) { _, response, _ in
            if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode != 200 {
                print("Error in PUT request, status: \(statusCode)")
                return completion(false)
            }

            completion(true)
        }

        task.resume()
    }

    private func addAuthorization(to request: inout URLRequest) {
        request.addValue("Bearer \(self.authToken)", forHTTPHeaderField: "Authorization")
    }
}

// MARK: - Types

struct Song: Codable {
    let id: String
    let uri: String
    let name: String
}

extension SpotifyAPI {
    struct SearchResultResponse: Codable {
        let tracks: Track

        struct Track: Codable {
            let items: [Song]
        }
    }
}
