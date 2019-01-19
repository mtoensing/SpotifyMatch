# SpotifyMatch

## Overview

I wrote this tool in an afternoon as a quick way to add all the songs from my iTunes library (or any local directory of music files) to my Spotify account so that they could be streamed from all my devices.

What it does:
- Attempts to read song metadata (title and artist) from files in a given directory
- Looks up song data with Spotify's API to try to find a match
- Outputs the name, Spotify ID, and Spotify URI of all matches
- Prompts as to whether to add all the matches to the authenticated user's Spotify library

## Usage

**Note:** Because this was a quick task, I didn't implement the full OAuth dance as part of this tool. To use it, you'll need to generate your own authorization token. This can be done through a web browser:

1. Create a Spotify app in their [developer portal](https://developer.spotify.com/dashboard/applications). You can use a localhost variant as your redirect URI for simplicity
1. Obtain an authorization token with the `user-library-modify` scope included. The authorization URL should look something like this:

```
https://accounts.spotify.com/authorize?client_id=YOUR_CLIENT_ID&scope=user-library-modify&response_type=token&redirect_uri=YOUR_REDIRECT_URI
```

Once you have the token:

1. Clone this repository
1. Build and run the tool, specifying the token and path to the songs you'd like to match:

```
$ ./run.sh ACCESS_TOKEN PATH_TO_SONG_DIRECTORY
```
```
Looking up 'Back in Black artist:AC DC'...
Looking up 'Thunderstruck artist:AC DC'...
Matched 'Back In Black'
Matched 'Thunderstruck'

Results:
'Back In Black', 08mG3Y1vljYA6bvDt4Wqkj, spotify:track:08mG3Y1vljYA6bvDt4Wqkj
'Thunderstruck', 57bgtoPSgt236HzfBOd8kj, spotify:track:57bgtoPSgt236HzfBOd8kj

Done: Matched 2/2 tracks
```
```
Add songs to Spotify library? (y/n)
$ y
Adding to library...
Adding batch of 2 songs to Spotify library...
Done adding songs!
```
