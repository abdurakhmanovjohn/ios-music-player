import AVFoundation
import Combine
import MediaPlayer
import UIKit

enum RepeatMode: String, CaseIterable, Identifiable {
    case off
    case all
    case one

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .off, .all:
            return "repeat"
        case .one:
            return "repeat.1"
        }
    }

    mutating func advance() {
        switch self {
        case .off:
            self = .all
        case .all:
            self = .one
        case .one:
            self = .off
        }
    }
}

final class AudioPlayerService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var currentSong: Song?
    @Published private(set) var isPlaying = false
    @Published private(set) var progress: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var queue: [Song] = []
    @Published var repeatMode: RepeatMode = .off {
        didSet {
            updateNowPlayingInfo()
        }
    }
    @Published var isShuffleEnabled = false

    private var player: AVAudioPlayer?
    private var progressTimer: Timer?
    private var currentIndex: Int?
    private var originalQueue: [Song] = []

    override init() {
        super.init()
        configureAudioSession()
        configureRemoteCommands()
        observeAudioSessionNotifications()
    }

    deinit {
        progressTimer?.invalidate()
    }
    
    private func observeAudioSessionNotifications() {
        let center = NotificationCenter.default
        let session = AVAudioSession.sharedInstance()

        center.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: session
        )
        center.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: session
        )
    }

    /// Phone calls, Siri, alarms, other apps taking over audio.
    @objc private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0

        DispatchQueue.main.async { [weak self] in
            switch type {
            case .began:
                self?.pause()
            case .ended:
                if AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                    self?.play()
                }
            @unknown default:
                break
            }
        }
    }

    /// Pause when headphones are unplugged or Bluetooth disconnects.
    @objc private func handleRouteChange(_ notification: Notification) {
        guard
            let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue),
            reason == .oldDeviceUnavailable
        else { return }

        DispatchQueue.main.async { [weak self] in
            self?.pause()
        }
    }

    func load(_ song: Song, queue newQueue: [Song]? = nil, autoplay: Bool = true) {
        if let newQueue, !newQueue.isEmpty {
            queue = newQueue
            originalQueue = newQueue
        } else if queue.isEmpty || !queue.contains(where: { $0.id == song.id }) {
            queue = [song]
            originalQueue = [song]
        }

        currentIndex = queue.firstIndex(where: { $0.id == song.id })
        currentSong = song

        guard preparePlayer(for: song) else {
            return
        }

        if autoplay {
            recordPlaybackStart(for: song)
            play()
        } else {
            updateNowPlayingInfo()
        }
    }

    func play() {
        guard let player else {
            if let currentSong {
                load(currentSong, queue: queue, autoplay: true)
            }
            return
        }

        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Musica could not activate the audio session: \(error.localizedDescription)")
        }

        player.play()
        isPlaying = true
        startProgressTimer()
        updateNowPlayingInfo()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopProgressTimer()
        updateNowPlayingInfo()
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func stop() {
        player?.stop()
        player = nil
        currentSong = nil
        currentIndex = nil
        progress = 0
        duration = 0
        isPlaying = false
        stopProgressTimer()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func seek(to time: TimeInterval) {
        guard let player else {
            return
        }

        let clampedTime = min(max(time, 0), max(player.duration, 0))
        player.currentTime = clampedTime
        progress = clampedTime
        updateNowPlayingInfo()
    }

    func next() {
        guard !queue.isEmpty else {
            stop()
            return
        }

        if isShuffleEnabled, queue.count > 1 {
            let candidates = queue.filter { $0.id != currentSong?.id }
            if let randomSong = candidates.randomElement() {
                load(randomSong, queue: queue, autoplay: true)
            }
            return
        }

        guard let currentIndex else {
            load(queue[0], queue: queue, autoplay: true)
            return
        }

        let nextIndex = currentIndex + 1
        if queue.indices.contains(nextIndex) {
            load(queue[nextIndex], queue: queue, autoplay: true)
        } else if repeatMode == .all {
            load(queue[0], queue: queue, autoplay: true)
        } else {
            pause()
            seek(to: duration)
        }
    }

    func previous() {
        if progress > 4 {
            seek(to: 0)
            return
        }

        guard !queue.isEmpty else {
            stop()
            return
        }

        guard let currentIndex else {
            load(queue[0], queue: queue, autoplay: true)
            return
        }

        let previousIndex = currentIndex - 1
        if queue.indices.contains(previousIndex) {
            load(queue[previousIndex], queue: queue, autoplay: true)
        } else if repeatMode == .all, let lastSong = queue.last {
            load(lastSong, queue: queue, autoplay: true)
        } else {
            seek(to: 0)
        }
    }

    func toggleShuffle() {
        guard let currentSong else {
            isShuffleEnabled.toggle()
            return
        }

        isShuffleEnabled.toggle()

        if isShuffleEnabled {
            originalQueue = queue
            let remainingSongs = queue.filter { $0.id != currentSong.id }.shuffled()
            queue = [currentSong] + remainingSongs
            currentIndex = 0
        } else if !originalQueue.isEmpty {
            queue = originalQueue
            currentIndex = queue.firstIndex(where: { $0.id == currentSong.id })
        }
    }

    func toggleRepeatMode() {
        repeatMode.advance()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.handlePlaybackCompletion()
        }
    }

    private func preparePlayer(for song: Song) -> Bool {
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: song.localFileURL)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            player = audioPlayer
            duration = audioPlayer.duration > 0 ? audioPlayer.duration : song.duration
            progress = 0
            if duration > 0 {
                song.duration = duration
            }
            return true
        } catch {
            print("Musica could not load \(song.fileName): \(error.localizedDescription)")
            player = nil
            isPlaying = false
            stopProgressTimer()
            return false
        }
    }

    private func handlePlaybackCompletion() {
        progress = duration

        if repeatMode == .one {
            seek(to: 0)
            play()
            return
        }

        next()
    }

    private func recordPlaybackStart(for song: Song) {
        song.playCount += 1
        song.lastPlayedDate = Date()
    }

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else {
                return
            }

            self.progress = player.currentTime
            self.duration = player.duration
            self.updateNowPlayingInfo()
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
        } catch {
            print("Musica could not configure background playback: \(error.localizedDescription)")
        }
    }

    private func configureRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.play()
            }
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.pause()
            }
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.togglePlayPause()
            }
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.next()
            }
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.previous()
            }
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }

            DispatchQueue.main.async {
                self?.seek(to: positionEvent.positionTime)
            }
            return .success
        }
    }

    private var cachedArtwork: (songID: UUID, artwork: MPMediaItemArtwork)?
    
    func refreshNowPlayingInfo() {
        cachedArtwork = nil
        updateNowPlayingInfo()
    }

    private func updateNowPlayingInfo() {
        guard let currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: currentSong.title,
            MPMediaItemPropertyArtist: currentSong.displayArtist,
            MPMediaItemPropertyAlbumTitle: currentSong.displayAlbum,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: progress,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        if cachedArtwork?.songID != currentSong.id {
            let image = currentSong.artworkData.flatMap(UIImage.init(data:))
                ?? PlaceholderArtwork.image(for: currentSong.title)
            cachedArtwork = (currentSong.id, Self.makeArtwork(from: image))
        }
        info[MPMediaItemPropertyArtwork] = cachedArtwork?.artwork

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private nonisolated static func makeArtwork(from image: UIImage) -> MPMediaItemArtwork {
        MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }
}
