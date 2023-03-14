//
//  SongsViewModel.swift
//  Discobot
//
//  Created by Joel Collins on 11/03/2023.
//
// TODO: Handle previews, see https://developer.apple.com/forums/thread/685311
// TODO: Handle subscription state, see https://developer.apple.com/documentation/musickit/using_musickit_to_integrate_with_apple_music
// TODO: Handle loading more items at end of scroll

import AVFoundation
import MusicKit
import SwiftUI

struct AlbumCardView: View {
    // MARK: - Initialisation

    /// Album object for this view instance
    var album: Album
    /// Playback ID of this instance, to check if this album is currently active
    let playbackId: String
    /// Binding to the parent view's currently active playbackId
    @Binding public var nowPlayingId: String?
    /// Player for previews
    let previewPlayer: AVQueuePlayer

    // MARK: - Colours, UI etc

    var cardColour: Color {
        return Color(album.artwork?.backgroundColor ?? UIColor.systemGray6.cgColor)
    }

    var primaryTextColor: Color {
        return Color(album.artwork?.primaryTextColor ?? UIColor.black.cgColor)
    }

    var buttonBackgroundColor: Color {
        return Color(album.artwork?.secondaryTextColor ?? UIColor.systemGray2.cgColor)
    }

    var buttonLabelColor: Color {
        return Color(album.artwork?.backgroundColor ?? UIColor.systemGray6.cgColor)
    }

    // MARK: - System music playback

    /// The MusicKit player to use for Apple Music playback.
    private let player = SystemMusicPlayer.shared
    /// The state of the MusicKit player to use for Apple Music playback.
    @ObservedObject private var playerState = SystemMusicPlayer.shared.state

    /// `true` when the player is playing.
    private var isPlaying: Bool {
        return (playerState.playbackStatus == .playing)
    }

    /// `true` when this album is currently active (may be paused).
    private var nowPlayingThisAlbum: Bool {
        return (nowPlayingId == playbackId)
    }

    /// `true` when this album is currently active  and playing
    private var isPlayingThisAlbum: Bool {
        return isPlaying && nowPlayingThisAlbum
    }

    /// `true` when the album detail view needs to disable the Play/Pause button.
//    private var isPlayButtonDisabled: Bool {
//        let canPlayCatalogContent = musicSubscription?.canPlayCatalogContent ?? false
//        return !canPlayCatalogContent
//    }
    var isPlayButtonDisabled: Bool = false

    /// A declaration of the Play/Pause button, and (if appropriate) the Join button, side by side.
    private var playButton: some View {
        HStack {
            Button(action: handlePlayButtonSelected) {
                HStack {
                    Image(systemName: isPlayingThisAlbum ? "pause.fill" : "play.fill")
                    Text(isPlayingThisAlbum ? "Pause" : "Play")
                }
                .frame(maxWidth: .infinity, maxHeight: 20)
            }.font(.title3.bold())
                .foregroundColor(self.buttonLabelColor)
                .padding()
                .background(self.buttonBackgroundColor.cornerRadius(8))
                .disabled(isPlayButtonDisabled)
                .animation(.easeInOut(duration: 0.1), value: isPlayingThisAlbum)

//            if shouldOfferSubscription {
//                subscriptionOfferButton
//            }
        }
    }

    /// The action to perform when the user taps the Play/Pause button.
    private func handlePlayButtonSelected() {
        // If this album isn't actively playing
        if !isPlayingThisAlbum {
            // If this album isn't active
            if !nowPlayingThisAlbum {
                // Set this album as the queue and start playing
                player.queue = [album]
                beginPlaying()
            } else { // If this album is active, but not playing right now
                // Resume
                Task {
                    do {
                        try await player.play()
                    } catch {
                        print("Failed to resume playing with error: \(error).")
                    }
                }
            }
        } else {
            player.pause()
        }
    }

    /// A convenience method for beginning music playback and setting the nowPlayingId.
    ///
    /// Call this instead of `MusicPlayer`’s `play()`
    /// method whenever the playback queue is reset.
    private func beginPlaying() {
        Task {
            do {
                try await player.play()
                nowPlayingId = playbackId
            } catch {
                print("Failed to prepare to play with error: \(error).")
            }
        }
    }

    // MARK: - Preview playback

    @State private var previewUrlStrings: [String]?

    func fetchPreviewAssets() async {
        do {
            let fullAlbum = try await album.with(.tracks)
            if let tracks = fullAlbum.tracks {
                previewUrlStrings = tracks.compactMap {
                    $0.previewAssets?.first?.url?.absoluteString
                }
            }
        } catch {
            print("Failed to load album tracks")
        }
    }

    func startPreviewQueue() async {
        print("Previewing: \(album.title)")
        // Fetch previews if we haven't already
        if previewUrlStrings == nil {
            await fetchPreviewAssets()
        }

        previewPlayer.pause()
        previewPlayer.removeAllItems()

        if let previewUrlStrings = previewUrlStrings {
            for urlString in previewUrlStrings {
                if let url = URL(string: urlString) {
                    previewPlayer.insert(AVPlayerItem(url: url), after: nil)
                }
            }
            previewPlayer.play()
        }
    }

    // MARK: - View body

    var body: some View {
        GeometryReader { geometry in
            // Height of VStack is determined by it's children, and the height of the children
            // are in turn determined by the available height set by the frame of this view (measured by GeometryReader)
            LazyVStack(alignment: .leading) {
                // Get art size from the parent geometry multiplied by display scale
                let artSize = geometry.size.width * UIScreen().scale
                AsyncImage(
                    url: album.artwork?.url(width: Int(artSize), height: Int(artSize)),
                    content: { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    },
                    placeholder: {
                        Image(systemName: "a.square") // TODO: Replace with a better placeholder
                            // Make placeholder resizable
                            .resizable()
                            // Force to a square, so cards with placeholders are roughly the right size
                            .aspectRatio(1, contentMode: .fit)
                    }
                )
                .frame(width: geometry.size.width)
//                .task { // Async task to run when artwork first appears
//                    await fetchPreviewAssets()
//                }

                // Everything other than album art
                VStack(alignment: .leading, spacing: 16.0) {
                    // OPTIONAL: Initial spacer to push item info down
                    Spacer()

                    // Item info
                    VStack(alignment: .leading, spacing: 8.0) {
                        Text(album.title)
                            .font(Font.system(.headline))
                        Text(album.artistName)
                            .font(.system(.subheadline))
                    }
                    .foregroundColor(self.primaryTextColor)
                    .padding(.top, 8.0)

                    // Push all remaining content to the bottom of the available space
                    Spacer()

                    // Item card - Full width and horizontally centered
                    VStack(spacing: 16.0) {
                        // Play button
                        playButton
//                            .task {
//                                await startPreviewQueue()
//                            }
                    }.frame(maxWidth: .infinity, alignment: .center)
                }
                // Padding, for a e s t h e t i c
                .padding([.horizontal, .bottom], 20.0)
                // Lock height as the difference between the artwork height and the full available height
                .frame(width: geometry.size.width, height: geometry.size.height - geometry.size.width, alignment: .topLeading)
            }
            .background(Color(album.artwork?.backgroundColor ?? UIColor.systemGray6.cgColor))
        }
    }
}

struct SongsViewModel: View {
    @State var items: MusicItemCollection<MusicPersonalRecommendation> = []
    @State var nowPlayingId: String? = nil

    let previewPlayer: AVQueuePlayer = .init()

    let itemPadding = 40.0

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { _ in
                TabView {
                    ForEach(items) { reccommendation in
                        ForEach(reccommendation.albums) { album in
                            let itemId = reccommendation.id.rawValue + album.id.rawValue
                            AlbumCardView(album: album, playbackId: itemId, nowPlayingId: $nowPlayingId, previewPlayer: previewPlayer)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .onAppear {
                    fetchMusic()
                }
            }
        }
    }

    private let request: MusicPersonalRecommendationsRequest = {
        var request = MusicPersonalRecommendationsRequest()

        // request.limit = 5
        // request.offset = 0

        return request
    }()

    private func fetchMusic() {
        Task {
            // Request permission
            // TODO: Move to a login screen
            let status = await MusicAuthorization.request()

            switch status {
            case .authorized:
                // Request -> Response
                do {
                    let result = try await request.response()

                    self.items = result.recommendations
                } catch {
                    print(String(describing: error))
                }

            // Assign songs
            default:
                break
            }
        }
    }
}

struct SongsViewModel_Previews: PreviewProvider {
    static var previews: some View {
        SongsViewModel()
    }
}
