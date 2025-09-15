import AVFoundation

// Singleton AVQueuePlayer instance for the application.
// Analogous to ApplicationMusicPlayer.shared
final class PreviewPlayer {
    static let shared = PreviewPlayer()
    let player = AVQueuePlayer()

    private init() {}
}
