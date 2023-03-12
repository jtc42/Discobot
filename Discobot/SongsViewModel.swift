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
        HStack {
            AsyncImage(url: album.artwork?.url(width: 75, height: 75)).frame(width: 75, height: 75)
            VStack(alignment: .leading) {
                Text(album.title).font(.title3)
                Text(album.artistName).font(.footnote)
            }.padding(4.0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(8.0)
        // .padding(4.0)
    }
}

struct SongsViewModel: View {
    @State var items: MusicItemCollection<MusicPersonalRecommendation> = []

    var body: some View {
        ScrollView {
            VStack {
                ForEach(items) { reccommendation in
                    ForEach(reccommendation.albums) { album in
                        AlbumCardView(album: album)
                    }
                }
            }.padding([.horizontal], 40.0)
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
