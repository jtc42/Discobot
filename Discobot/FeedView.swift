//
//  SongsViewModel.swift
//  Discobot
//
//  Created by Joel Collins on 11/03/2023.
//
// TODO: Support playlists
// TODO: Support landscape layout
// TODO: Support iPad
// TODO: Handle loading more items at end of scroll

import AVFoundation
import Combine
import MusicKit
import SwiftUI
import SwiftUIPageView

struct FeedItem: Identifiable, Hashable {
    var id = UUID()
    let recommendationReason: String?
    let recommendationTitle: String?
    let album: Album
}

struct FeedView: View {
    @State var musicAuthorizationStatus: MusicAuthorization.Status?

    /// If the first request is currently loading
    @State var isLoading: Bool = true
    /// If the request resulted in an error
    @State var isError: Bool = false

    /// Flattened array of feed itemsß
    @State var flatItems: [FeedItem] = []

    /// Page index of the item currently playing in the system player
    @State var nowPlayingIndex: Int? = nil
    /// Page index of the item currently in view
    @State var currentIndex: Int = 0

    @State var previewMuted: Bool = true
    let previewPlayer: AVQueuePlayer = .init()

    // Track if the user has changed page yet (used to auto-unmute)
    @State var firstPageMove: Bool = true

    // Padding between pages
    let itemPadding = 40.0

    /// The color scheme of the environment.
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            if isLoading || musicAuthorizationStatus == nil {
                ProgressView().progressViewStyle(CircularProgressViewStyle())
            } else if isError {
                VStack(spacing: 10.0) {
                    Text("Error loading recommendations").font(.body)
                    Button(action: {
                        Task {
                            await fetchMusic()
                        }
                    }) {
                        Text("Try again").font(.body)
                    }
                }
            } else {
                mainFeedView
            }
        }
        // As soon as we know the users auth status, decide if we should fetch content
        .onReceive(WelcomeView.PresentationCoordinator.shared.$musicAuthorizationStatus, perform: { status in
            musicAuthorizationStatus = status
            if musicAuthorizationStatus == .authorized {
                Task {
                    await fetchMusic()
                    if !previewMuted {
                        await startPreviewFor(item: flatItems[currentIndex].album)
                    }
                }
            }
        })
    }

    private var mainFeedView: some View {
        GeometryReader { geometry in
            PageViewReader { proxy in
                VPageView(alignment: .top, pageHeight: geometry.size.height * 0.9, spacing: 24, index: $currentIndex) {
                    ForEach(Array(flatItems.enumerated()), id: \.element) { index, item in
                        AlbumCardView(
                            album: item.album,
                            pageIndex: index,
                            recommendationTitle: item.recommendationTitle,
                            recommendationReason: item.recommendationReason,
                            nowPlayingIndex: $nowPlayingIndex,
                            currentIndex: $currentIndex,
                            previewMuted: $previewMuted
                        )
                        .onTapGesture {
                            // Tapping before first page change will unmute
                            initiatePreviews()
                            // Tapping will move to the tapped page
                            withAnimation {
                                proxy.moveTo(index)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                // When page changes
                .onChange(of: currentIndex, perform: { newIndex in
                    // If it's the first time the user has changed page, unmute
                    initiatePreviews()
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
            }
        }
    }

    private func initiatePreviews() {
        if firstPageMove {
            firstPageMove = false
            previewMuted = false
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
        // TODO: Handle MusicAuthorization
        let status = await MusicAuthorization.request()

        switch status {
        case .authorized:
            // Request -> Response
            do {
                isLoading = true
                var request = MusicPersonalRecommendationsRequest()
                // TODO: Add loading extra items but running this function again with a new offset
                request.limit = 25
                request.offset = 0

                let result = try await request.response()
                flatItems = flattenRecommendations(recommendations: result.recommendations)

                isLoading = false
                isError = false
            } catch {
                isLoading = false
                isError = true
            }
        default:
            break
        }
    }

    private func flattenRecommendations(
        recommendations: MusicItemCollection<MusicPersonalRecommendation>,
        simple: Bool = false,
        maxGroupSize: Int = 3
    ) -> [FeedItem] {
        if simple {
            return recommendations.flatMap { recommendation in
                recommendation.albums.map { album in
                    FeedItem(
                        recommendationReason: recommendation.reason,
                        recommendationTitle: recommendation.title,
                        album: album
                    )
                }
            }
        } else {
            // Items to show at the top of the feed
            var items: [FeedItem] = []
            // Spares to put at the end of the feed
            var spares: [FeedItem] = []

            // For each recommendation group
            for recommendation in recommendations {
                // Keep count of how many items in this recommendation
                var groupCount = 0
                // For each recommendation in the group
                for album in recommendation.albums {
                    // Iterate the group counter
                    groupCount += 1

                    // Create a feed item
                    let item = FeedItem(
                        recommendationReason: recommendation.reason,
                        recommendationTitle: recommendation.title,
                        album: album
                    )
                    // If we've not hit the max group size
                    if groupCount <= maxGroupSize {
                        // Add the item to the top of the feed
                        items.append(item)
                    } else {
                        // Add the item to the spares at the bottom
                        spares.append(item)
                    }
                }
            }

            // Shuffle spares
            spares.shuffle()

            // Join spare items to the bottom of the feed
            return items + spares
        }
    }
}

struct SongsViewModel_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
