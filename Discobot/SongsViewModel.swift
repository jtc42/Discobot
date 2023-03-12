//
//  SongsViewModel.swift
//  Discobot
//
//  Created by Joel Collins on 11/03/2023.
//

import MusicKit
import SwiftUI

struct Item: Identifiable, Hashable {
    var id: UUID
    let name: String
    let artist: String
    let imageUrl: URL?
}

struct AlbumCardView: View {
    var album: Album

    var body: some View {
        VStack(alignment: .leading) {
            let artSize = 200.0 // geometry.size.width
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
            VStack(alignment: .leading, spacing: 8.0) {
                Text(album.title).font(Font.system(.headline))
                Text(album.artistName).font(.system(.subheadline))
            }.padding([.horizontal, .bottom], 8.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(12.0)
    }
}

struct SongsViewModel: View {
    @State var items: MusicItemCollection<MusicPersonalRecommendation> = []

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20.0) {
                ForEach(items) { reccommendation in
                    ForEach(reccommendation.albums) { album in
                        AlbumCardView(album: album)
                    }
                }
            }.padding([.horizontal], 20.0)
        }.onAppear {
            fetchMusic()
        }
    }

    private let request: MusicPersonalRecommendationsRequest = {
        var request = MusicPersonalRecommendationsRequest()

        request.limit = 5
        request.offset = 0

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
