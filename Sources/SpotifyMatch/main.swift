import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())

guard arguments.count == 2 else {
    print("Usage: '$ SpotifyMatch ACCESS_TOKEN PATH_TO_SONG_DIRECTORY")
    exit(EXIT_FAILURE)
}

let api = SpotifyAPI(authToken: arguments[0])
let directory = URL(fileURLWithPath: arguments[1])
let matcher = SpotifyMatch(api: api, directory: directory)

do {
    try matcher.lookUpAllTracks { results in
        print("\nResults:")
        let songs = results.compactMap { $0.value }
        for song in songs {
            print("'\(song.name)', \(song.id), \(song.uri)")
        }

        print("\nDone: Matched \(songs.count)/\(results.count) songs\n")

        if songs.isEmpty {
            exit(EXIT_SUCCESS)
        }

        print("Add songs to Spotify library? (y/n)")
        if readLine(strippingNewline: true) == "y" {
            print("Adding to library...")
            matcher.addSongsToLibrary(songs) { exit(EXIT_SUCCESS) }
        } else {
            exit(EXIT_SUCCESS)
        }
    }
} catch {
    print("Error: \(error)")
    exit(EXIT_FAILURE)
}

RunLoop.main.run()
