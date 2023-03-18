//
//  SongsViewModel.swift
//  Discobot
//
//  Created by Joel Collins on 11/03/2023.
//
// TODO: Fix landscape
// TODO: Handle previews, see https://developer.apple.com/forums/thread/685311
// TODO: Handle subscription state, see https://developer.apple.com/documentation/musickit/using_musickit_to_integrate_with_apple_music
// TODO: Handle loading more items at end of scroll
// TODO: Show reccommendation.title on card somewhere

import AVFoundation
import MusicKit
import SwiftUI
import SwiftUIPageView

let cardCornerRadius = 20.0

struct AlbumCardView: View {
    // MARK: - Initialisation

    /// Album object for this view instance
    var album: Album
    /// Page index of this instance
    let pageIndex: Int

    /// Binding to the parent view's currently active playbackId
    @Binding public var nowPlayingIndex: Int?

    /// Binding to the parent view's currently in-view page index
    @Binding public var currentIndex: Int

    /// Binding to whether the preview is muted or not
    @Binding public var previewMuted: Bool

    /// Binding to the parent views map of preview links
    // @Binding public var previewLinkMap: [Int: [String]]

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
        return (nowPlayingIndex == pageIndex)
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
                // Try playing with the system music player
                try await player.play()
                // Mute previews now something is actually playing
                previewMuted = true
                // Update the shared state for which item is playing
                nowPlayingIndex = pageIndex
            } catch {
                print("Failed to prepare to play with error: \(error).")
            }
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
                .overlay(alignment: .topTrailing) {
                    Button(action: {
                        previewMuted = !previewMuted
                    }) {
                        Image(systemName: previewMuted ? "speaker.slash.fill" : "speaker.fill")
                            .padding(8)
                            .background(.black.opacity(0.5))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }.padding(12)
                }

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
                    }.frame(maxWidth: .infinity, alignment: .center)
                }
                // Padding, for a e s t h e t i c
                .padding([.horizontal, .bottom], 20.0)
                // Lock height as the difference between the artwork height and the full available height
                .frame(width: geometry.size.width, height: geometry.size.height - geometry.size.width, alignment: .topLeading)
            }
            .background(Color(album.artwork?.backgroundColor ?? UIColor.systemGray6.cgColor))
            .cornerRadius(cardCornerRadius)
            .overlay( /// Rounded border
                RoundedRectangle(cornerRadius: cardCornerRadius).stroke(Color(UIColor.systemGray4), lineWidth: 0.5)
            )
            .shadow(radius: 16.0)
        }
    }
}

struct FeedItem: Identifiable, Hashable {
    var id = UUID()
    let recommendationReason: String?
    let recommendationTitle: String?
    let album: Album
}

struct SongsViewModel: View {
    @State var items: MusicItemCollection<MusicPersonalRecommendation> = []
    @State var flatItems: [FeedItem] = []

    @State var nowPlayingIndex: Int? = nil
    @State var currentIndex: Int = 0

    @State var previewMuted: Bool = false
    let previewPlayer: AVQueuePlayer = .init()

    let itemPadding = 40.0

    var body: some View {
        GeometryReader { geometry in
            PageViewReader { _ in
                VPageView(alignment: .center, pageHeight: geometry.size.height * 0.9, spacing: 24, index: $currentIndex) {
                    ForEach(Array(flatItems.enumerated()), id: \.element) { index, item in
                        AlbumCardView(album: item.album, pageIndex: index, nowPlayingIndex: $nowPlayingIndex, currentIndex: $currentIndex, previewMuted: $previewMuted)
                    }
                }
                .padding(.horizontal, 12)
                // When page changes
                .onChange(of: currentIndex, perform: { newIndex in
                    Task {
                        if !previewMuted {
                            await startPreviewFor(item: flatItems[newIndex].album)
                        }
                    }
                })
                // When preview mute changes
                .onChange(of: previewMuted, perform: { newPreviewMuted in
                    Task {
                        if newPreviewMuted {
                            previewPlayer.pause()
                        } else {
                            await startPreviewFor(item: flatItems[currentIndex].album)
                        }
                        previewPlayer.isMuted = newPreviewMuted
                    }
                })
                // On load, fetch music and start playing
                .task {
                    await fetchMusic()
                    if !previewMuted {
                        await startPreviewFor(item: flatItems[currentIndex].album)
                    }
                }
            }
        }
    }

    private func startPreviewQueue(previewUrlStrings: [String]) {
        previewPlayer.pause()
        previewPlayer.removeAllItems()

        for urlString in previewUrlStrings {
            if let url = URL(string: urlString) {
                previewPlayer.insert(AVPlayerItem(url: url), after: nil)
            }
        }
        previewPlayer.play()
    }

    private func startPreviewFor(item: Album) async {
        do {
            let fullAlbum = try await item.with(.tracks)
            if let tracks = fullAlbum.tracks {
                let previewUrlStrings = tracks.compactMap {
                    $0.previewAssets?.first?.url?.absoluteString
                }
                startPreviewQueue(previewUrlStrings: previewUrlStrings)
            }
        } catch {
            print("Failed to load album tracks")
        }
    }

    private func fetchMusic() async {
        // Request permission
        // TODO: Move to a login screen
        let status = await MusicAuthorization.request()

        switch status {
        case .authorized:
            // Request -> Response
            do {
                var request = MusicPersonalRecommendationsRequest()
                // TODO: Add loading extra items but running this function again with a new offset
                request.limit = 25
                request.offset = 0

                let result = try await request.response()
                items = result.recommendations

                flatItems = result.recommendations.flatMap { recommendation in
                    recommendation.albums.map { album in
                        FeedItem(
                            recommendationReason: recommendation.reason,
                            recommendationTitle: recommendation.title,
                            album: album
                        )
                    }
                }
            } catch {
                print(String(describing: error))
            }

        // Assign songs
        default:
            break
        }
    }
}

struct SongsViewModel_Previews: PreviewProvider {
    static var previews: some View {
        SongsViewModel()
    }
}
