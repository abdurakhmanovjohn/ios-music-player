# Musica

A local music player for iPhone, built with SwiftUI. Import audio files you own, build your library, and play everything offline, with a dark-first interface inspired by Apple Music and a few ideas from Spotify.

<!--
Add screenshots here, for example:
<p align="center">
  <img src="docs/home.png" width="240" />
  <img src="docs/now-playing.png" width="240" />
  <img src="docs/library.png" width="240" />
</p>
-->

## Features

**Library**
- Import MP3, M4A, AAC and WAV files from the Files app
- Files are copied into the app's own storage, so they play offline
- Title, artist, album, duration and embedded artwork are read from file metadata
- Songs, Albums and Artists views, with albums and artists derived from your songs (no duplicated data)
- Playlists
- Rename a song's title, artist and album: long-press any song and choose **Edit Info**
- Generated gradient artwork for songs that have none

**Playback**
- Play, pause, seek, next, previous
- Queue with a "now playing" indicator
- Shuffle and repeat
- Background audio
- Lock screen and Control Center controls, with artwork
- Pauses on phone calls and when headphones are disconnected

**Interface**
- Home with Recently Played, Recently Added, Favorites and Playlists
- Search across song title, artist and album
- Mini-player docked above the tab bar (Liquid Glass on iOS 26+)
- Full-screen Now Playing with large artwork, progress slider and queue
- Dark-mode-first design, SF Symbols, rounded cards and subtle animations

## Tech stack

- Swift and SwiftUI
- SwiftData for persistence
- AVFoundation for playback and metadata
- MediaPlayer for lock screen and remote controls
- MVVM where it makes sense
- No third-party dependencies

## Requirements

- iOS 18.0 or later
- A recent version of Xcode with the matching iOS SDK
- An Apple ID for signing, if you want to run on a real device (a free account works)

## Getting started

```bash
git clone https://github.com/abdurakhmanovjohn/ios-music-player.git
cd ios-music-player
open Musica.xcodeproj
```

1. In Xcode, select the **Musica** target and open **Signing & Capabilities**.
2. Choose your **Team** and set a unique **Bundle Identifier**.
3. Pick a simulator or your iPhone and press **Cmd+R**.

On a device with a free Apple ID, the app expires after 7 days. Run it from Xcode again to reinstall.

### Adding music

1. Get some audio files onto the device, for example via AirDrop, "Save to Files", or iCloud Drive. In the simulator, drag a file onto the window and save it to **On My iPhone**.
2. Open Musica and tap the import button (or **Import Music** on Home).
3. Select one or more files. They appear in your library and are ready to play.

## Project structure

```
Musica/
├── App/                  App entry point, root tab view, theme
├── Models/               Song, Playlist, library summaries (albums, artists)
├── Services/
│   ├── AudioPlayer/      AudioPlayerService, placeholder artwork
│   ├── Library/          Library organizing (albums and artists from songs)
│   └── Import/           File import and metadata extraction
├── ViewModels/           Home, Library and Search view models
├── Views/
│   ├── Home/
│   ├── Library/
│   ├── Search/
│   ├── Playlists/
│   ├── NowPlaying/       Mini-player and full-screen player
│   └── Shared/           Artwork, song rows, edit sheet, file picker
└── Resources/            Info.plist and assets
```

## Design notes

- **`AudioPlayerService`** is an observable object that owns playback, the queue, shuffle, repeat, audio session handling and Now Playing info. Views only read its state and call its methods.
- **Songs store a relative file path** (for example `Music/Song.mp3`), not an absolute URL. The app's container path can change between installs and updates, so the full URL is resolved at access time.
- **Importing is modular.** Everything goes through `MusicImportService`, so other legitimate import sources can be added later without touching the player or UI.
- **Metadata loading uses the async AVFoundation APIs**, so importing doesn't block the main thread.

## Roadmap

Ideas for future work:

- Playlist editing: reorder, remove and rename songs
- Album and artist detail pages
- Custom artwork for songs and playlists
- Queue editing: reorder, remove, "Play Next"
- Additional import sources
- Sleep timer and playback speed

## A note on content

Musica plays files that you already own or have permission to use. It does not download music from streaming or video sites and does not bypass any service's restrictions.

## License

No license has been chosen yet. Until one is added, all rights are reserved by the author.
