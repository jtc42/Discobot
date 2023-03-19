//
//  AlbumCardView.swift
//  Discobot
//
//  Created by Joel Collins on 19/03/2023.
//

import AVFoundation
import FluidGradient
import MusicKit
import SkeletonUI
import SwiftUI
import SwiftUIPageView

let cardCornerRadius = 20.0

struct AlbumAddButton: View {
    let album: Album

    var body: some View {
        Button(action: {
            Task {
                do {
                    let newAlbum = try await album.with()
                    print(newAlbum.libraryAddedDate ?? "Not added")
                    try await MusicLibrary.shared.add(album)
                } catch {
                    print("Error reloading album info")
                }
            }
        }) {
            Image(systemName: "plus")
                .padding(8)
                .background(.black.opacity(0.5))
                .foregroundColor(.white)
                .clipShape(Circle())
        }
    }
}

struct AlbumCardView: View {
    // MARK: - Initialisation

    /// Album object for this view instance
    var album: Album
    /// Page index of this instance
    let pageIndex: Int

    /// Recommendation info
    let recommendationTitle: String?
    let recommendationReason: String?

    /// Binding to the parent view's currently active playbackId
    @Binding public var nowPlayingIndex: Int?

    /// Binding to the parent view's currently in-view page index
    @Binding public var currentIndex: Int

    /// Binding to whether the preview is muted or not
    @Binding public var previewMuted: Bool

    // MARK: - Colours, UI etc

    private var cardCgColor: CGColor {
        return album.artwork?.backgroundColor ?? UIColor.systemGray6.cgColor
    }

    var cardColour: Color {
        return Color(cardCgColor)
    }

    var primaryTextColor: Color {
        return Color(album.artwork?.primaryTextColor ?? UIColor.black.cgColor)
    }

    var secondaryTextColor: Color {
        return Color(album.artwork?.tertiaryTextColor ?? UIColor.gray.cgColor)
    }

    var buttonBackgroundColor: Color {
        return Color(album.artwork?.secondaryTextColor ?? UIColor.systemGray2.cgColor)
    }

    var buttonLabelColor: Color {
        return Color(album.artwork?.backgroundColor ?? UIColor.systemGray6.cgColor)
    }

    private var backgroundGradientColors: [Color] {
        let colors: [UIColor] =
            [
                UIColor(cgColor: cardCgColor).shiftHSB(hueBy: 0.12, saturationBy: 0.2, brightnessBy: -0.1),
                UIColor(cgColor: cardCgColor).shiftHSB(hueBy: 0.05, saturationBy: -0.1, brightnessBy: 0.0),
                UIColor(cgColor: cardCgColor).shiftHSB(hueBy: -0.05, saturationBy: 0.1, brightnessBy: 0.0),
                UIColor(cgColor: cardCgColor).shiftHSB(hueBy: -0.12, saturationBy: 0.2, brightnessBy: 0.1),
            ]

        return colors.map { uiColor in
            Color(cgColor: uiColor.cgColor)
        }
    }

    // MARK: - Display state

    var isNearby: Bool {
        return pageIndex == currentIndex || pageIndex == currentIndex + 1 || pageIndex == currentIndex - 1
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

    /// A declaration of the Play/Pause button, and (if appropriate) the Join button, side by side.
    private var primaryButtons: some View {
        HStack {
            // Open in Apple Music button
            Button(action: {
                if let url = album.url {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }) {
                HStack {
                    Image(systemName: "arrow.up.forward.app")
                    Text("Open")
                }
                .frame(maxWidth: .infinity, maxHeight: 18)
            }
            .padding(15)
            .background(self.buttonBackgroundColor.cornerRadius(8))

            // Play button
            Button(action: handlePlayButtonSelected) {
                HStack {
                    Image(systemName: isPlayingThisAlbum ? "pause.fill" : "play.fill")
                    Text(isPlayingThisAlbum ? "Pause" : "Play")
                }
                .frame(maxWidth: .infinity, maxHeight: 18)
            }
            .padding(15)
            .background(self.buttonBackgroundColor.cornerRadius(8))
            .animation(.easeInOut(duration: 0.1), value: isPlayingThisAlbum)

        }.font(.body.bold()).foregroundColor(self.buttonLabelColor)
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
            LazyVStack(alignment: .leading, spacing: 0.0) {
                // Get art size from the parent geometry multiplied by display scale
                let artSize = geometry.size.width * UIScreen().scale
                AsyncImage(
                    url: album.artwork?.url(width: Int(artSize), height: Int(artSize)),
                    content: { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    },
                    placeholder: {
                        Rectangle()
                            .fill(cardColour)
                            .frame(width: geometry.size.width, height: geometry.size.width)
                    }
                )
                .frame(width: geometry.size.width)
                .background(cardColour)
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
                ZStack {
                    // Only show gradient if page is in view
                    if isNearby {
                        FluidGradient(blobs: self.backgroundGradientColors,
                                      // Faster animation if this card is active and the preview is unmuted
                                      speed: currentIndex == pageIndex && !previewMuted ? 0.5 : 0.1,
                                      blur: 0.85).ignoresSafeArea()
                    }

                    VStack(alignment: .leading, spacing: 16.0) {
                        // Initial spacer to push item info down
                        Spacer()

                        // Recommendation info
                        VStack(alignment: .leading, spacing: 8.0) {
                            if let recommendationTitle = recommendationTitle {
                                Text(recommendationTitle)
                                    .font(Font.system(.caption))
                            }
                            if let recommendationReason = recommendationReason {
                                Text(recommendationReason)
                                    .font(.system(.caption2))
                            }
                        }.foregroundColor(self.secondaryTextColor)

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
                            // Buttons seem to make the PageView scroll lag like heck,
                            // so only render them if the page is in view
                            if isNearby {
                                primaryButtons
                            }
                        }.frame(maxWidth: .infinity, alignment: .center)
                    }
                    // Padding, for a e s t h e t i c
                    .padding([.horizontal, .bottom], 20.0)
                }
                // Lock height as the difference between the artwork height and the full available height
                .frame(width: geometry.size.width, height: geometry.size.height - geometry.size.width, alignment: .topLeading)
                // Apply a gradient background to the bottom half of the card
                .background(cardColour)
            }
            .cornerRadius(cardCornerRadius)
            .overlay( /// Rounded border
                RoundedRectangle(cornerRadius: cardCornerRadius).stroke(Color(UIColor.systemGray4), lineWidth: 0.5)
            )
            .shadow(radius: 16.0)
        }
    }
}
