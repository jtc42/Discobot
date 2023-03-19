//
//  SongsViewModel.swift
//  Discobot
//
//  Created by Joel Collins on 11/03/2023.
//
// TODO: Add preview queue indicators and skip
// TODO: Support playlists
// TODO: Support landscape layout
// TODO: Support iPad
// TODO: Handle loading more items at end of scroll

import AVFoundation
import Combine
import MusicKit
import SwiftUI
import SwiftUIPageView

struct FeedPage: Identifiable, Hashable {
    var id = UUID()
    let recommendationReason: String?
    let recommendationTitle: String?
    let item: MusicPersonalRecommendation.Item
}

struct FeedView: View {
    @State var musicAuthorizationStatus: MusicAuthorization.Status?

    /// If the first request is currently loading
    @State var isLoading: Bool = true
    /// If the request resulted in an error
    @State var isError: Bool = false

    /// Flattened array of feed itemsß
    @State var flatPages: [FeedPage] = []

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
                        await startPreviewFor(item: flatPages[currentIndex].item)
                    }
                }
            }
        })
    }

    private var mainFeedView: some View {
        GeometryReader { geometry in
            PageViewReader { proxy in
                VPageView(alignment: .top, pageHeight: geometry.size.height * 0.9, spacing: 24, index: $currentIndex) {
                    ForEach(Array(flatPages.enumerated()), id: \.element) { index, page in
                        FeedItemCardView(
                            item: page.item,
                            pageIndex: index,
                            recommendationTitle: page.recommendationTitle,
                            recommendationReason: page.recommendationReason,
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
                            await startPreviewFor(item: flatPages[newIndex].item)
                        }
                    }
                })
                // When preview mute changes
                .onChange(of: previewMuted, perform: { newPreviewMuted in
                    Task {
                        if newPreviewMuted {
                            previewPlayer.pause()
                        } else {
                            await startPreviewFor(item: flatPages[currentIndex].item)
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

    private func startPreviewFor(item: MusicPersonalRecommendation.Item) async {
        do {
            switch item {
            case .album(let album):
                let fullAlbum = try await album.with(.tracks)
                if let tracks = fullAlbum.tracks {
                    let previewUrlStrings = tracks.compactMap {
                        $0.previewAssets?.first?.url?.absoluteString
                    }
                    startPreviewQueue(previewUrlStrings: previewUrlStrings)
                }
            case .playlist(let playlist):
                let fullPlaylist = try await playlist.with(.tracks)
                if let tracks = fullPlaylist.tracks {
                    let previewUrlStrings = tracks.compactMap {
                        $0.previewAssets?.first?.url?.absoluteString
                    }
                    startPreviewQueue(previewUrlStrings: previewUrlStrings)
                }
            case .station: break
            @unknown default: break
            }

        } catch {
            print("Failed to load item tracks")
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
                flatPages = flattenRecommendations(recommendations: result.recommendations)

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
        maxGroupSize: Int = 3
    ) -> [FeedPage] {
        // Items to show at the top of the feed
        var items: [FeedPage] = []
        // Spares to put at the end of the feed
        var spares: [FeedPage] = []

        // For each recommendation group
        for recommendation in recommendations {
            // Keep count of how many items in this recommendation
            var groupCount = 0
            // For each recommendation in the group
            for item in recommendation.items {
                // Iterate the group counter
                groupCount += 1

                switch item {
                case .album, .playlist:
                    // Create a feed item
                    let item = FeedPage(
                        recommendationReason: recommendation.reason,
                        recommendationTitle: recommendation.title,
                        item: item
                    )
                    // If we've not hit the max group size
                    if groupCount <= maxGroupSize {
                        // Add the item to the top of the feed
                        items.append(item)
                    } else {
                        // Add the item to the spares at the bottom
                        spares.append(item)
                    }

                case .station: break
                @unknown default: break
                }
            }
        }
        // Shuffle spares
        spares.shuffle()

        // Join spare items to the bottom of the feed
        return items + spares
    }
}

struct SongsViewModel_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
