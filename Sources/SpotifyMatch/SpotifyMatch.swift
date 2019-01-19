import AVFoundation
import Dispatch
import Foundation

private let kValidQueryChars = CharacterSet(charactersIn: " .'").union(.alphanumerics)

private extension String {
    func filteredForQuery() -> String {
        let filtered = self.unicodeScalars.map { kValidQueryChars.contains($0) ? $0 : " " }
        return String(String.UnicodeScalarView(filtered))
    }
}

struct SpotifyMatch {
    private let api: SpotifyAPI
    private let directory: URL

    init(api: SpotifyAPI, directory: URL) {
        self.api = api
        self.directory = directory
    }

    enum Result {
        case success(Song)
        case failure

        var value: Song? {
            if case .success(let value) = self {
                return value
            }

            return nil
        }
    }

    /// Looks up all tracks in the object's directory, calling the completion handler after receiving data
    /// for all requests.
    ///
    /// - parameter completion: Closure called on completion with the results from each lookup.
    func lookUpAllTracks(completion: @escaping ([Result]) -> Void) throws {
        let enumerator = FileManager.default.enumerator(at: self.directory, includingPropertiesForKeys: nil)!
        let dispatchGroup = DispatchGroup()

        print("Recursively searching '\(self.directory.path)'\n")

        var results = [Result]()
        var delay: TimeInterval = 0
        for case let file as URL in enumerator {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory),
                !isDirectory.boolValue else
            {
                continue
            }

            let metadata = AVAsset(url: file).metadata
            guard let name = (metadata.first { $0.commonKey?.rawValue == "title" }?.value as? String) else {
                print("Skipping '\(file.lastPathComponent)' (no title)")
                continue
            }

            let artist = (metadata.first { $0.commonKey?.rawValue == "artist" }?.value as? String)
                .map { $0.filteredForQuery() }
                .map { "artist:\($0)" }
            let query = [name.filteredForQuery(), artist]
                .compactMap { $0 }
                .joined(separator: " ")
                .replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)

            print("Looking up '\(query)'...")

            dispatchGroup.enter()
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + delay) {
                self.api.search(for: query) { response in
                    DispatchQueue.main.async {
                        if let item = response.first {
                            print("Matched '\(item.name)'")
                            results.append(.success(item))
                        } else {
                            print("Failed to match '\(query)'")
                            results.append(.failure)
                        }

                        dispatchGroup.leave()
                    }
                }
            }

            // Throttle requests to Spotify to avoid rate limiting
            delay += 0.1
        }

        dispatchGroup.notify(queue: .main) {
            completion(results)
        }
    }

    /// Adds the list of songs to the authenticated user's library.
    ///
    /// - parameter songs:      The songs to add to the library.
    /// - parameter completion: Closure called on completion after attempting all additions.
    func addSongsToLibrary(_ songs: [Song], completion: @escaping () -> Void) {
        // Spotify API caps additions to 50 per call
        let batch = Array(songs[0..<min(songs.count, 50)])
        print("Adding batch of \(batch.count) songs to Spotify library...")
        self.api.addToLibrary(batch) { success in
            guard success else {
                print("Failed to upload batch, exiting")
                return completion()
            }

            let nextBatch = Array(songs.dropFirst(batch.count))
            if nextBatch.isEmpty {
                print("Done adding songs!")
                return completion()
            }

            print("Added batch of \(batch.count) songs to Spotify library, \(nextBatch.count) remaining...")

            // Throttle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.addSongsToLibrary(nextBatch, completion: completion)
            }
        }
    }
}
