//
//  SongsViewModel.swift
//  Discobot
//
//  Created by Joel Collins on 11/03/2023.
//

import MusicKit
import SwiftUI
import SwiftUISnappingScrollView

struct Item: Identifiable, Hashable {
    var id: UUID
    let name: String
    let artist: String
    let imageUrl: URL?
}

struct AlbumCardView: View {
    var album: Album

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
                ).frame(maxWidth: .infinity)

                // Everything other than album art
                VStack(alignment: .leading, spacing: 16.0) {
                    // OPTIONAL: Initial spacer to push item info down
                    Spacer()

                    // Item info
                    VStack(alignment: .leading, spacing: 8.0) {
                        Text(album.title)
                            .font(Font.system(.headline))
                            .foregroundColor(Color(album.artwork?.primaryTextColor ?? UIColor.black.cgColor))
                        Text(album.artistName)
                            .font(.system(.subheadline))
                            .foregroundColor(Color(album.artwork?.secondaryTextColor ?? UIColor.black.cgColor))
                    }.padding(.top, 8.0)

                    // Push all remaining content to the bottom of the available space
                    Spacer()

                    // Item card - Full width and horizontally centered
                    VStack(spacing: 16.0) {
                        // Play button
                        Text("PLAY")
                            .font(Font.system(.title3))
                            .foregroundColor(Color(album.artwork?.tertiaryTextColor ?? UIColor.black.cgColor))
                    }.frame(maxWidth: .infinity, alignment: .center)
                }
                // Padding, for a e s t h e t i c
                .padding([.horizontal, .bottom], 10.0)
                // Lock height as the difference between the artwork height and the full available height
                .frame(width: geometry.size.width, height: geometry.size.height - geometry.size.width, alignment: .topLeading)
            }
            .background(Color(album.artwork?.backgroundColor ?? UIColor.systemGray6.cgColor))
            .cornerRadius(12.0)
            .shadow(radius: 16.0)
        }
    }
}

struct SongsViewModel: View {
    @State var items: MusicItemCollection<MusicPersonalRecommendation> = []

    let itemPadding = 40.0

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { reader in
                SnappingScrollView(.vertical, decelerationRate: .fast, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(items) { reccommendation in
                            ForEach(reccommendation.albums) { album in
                                let itemId = reccommendation.id.rawValue + album.id.rawValue
                                AlbumCardView(album: album)
                                    // Pad and set scroll anchor
                                    // NOTE: I have no idea why this weird layout works, but it does
                                    .padding(.bottom, itemPadding - 1)
                                    .scrollSnappingAnchor(.bounds).id(itemId)
                                    .padding(.bottom, 1)
                                    // Set the total frame height to 90% of the viewport (used by AlbumCardView for child sizing)
                                    .frame(maxWidth: .infinity, minHeight: geometry.size.height * 0.9)
                                    .onTapGesture {
                                        withAnimation {
                                            reader.scrollTo(itemId, anchor: .top)
                                        }
                                    }
                            }
                        }
                    }.padding([.horizontal], 20.0)
                }.onAppear {
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
                    print(String(describing: self.items))
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
