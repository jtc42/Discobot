//
//  ContentView.swift
//  Discobot
//
//  Created by Joel Collins on 11/03/2023.
//

import Chip
import SwiftUI

struct ContentView: View {
    @State var albumsOn = true
    @State var playlistsOn = true
    @State var stationsOn = false

    var body: some View {
        NavigationView {
            FeedView(
                albumsOn: $albumsOn,
                playlistsOn: $playlistsOn,
                stationsOn: $stationsOn
            )
            .padding(.top, 16.0)
            .navigationBarHidden(false)
            .toolbarBackground(.visible)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Chip("Albums", isOn: $albumsOn)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Chip("Playlists", isOn: $playlistsOn)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Chip("Stations", isOn: $stationsOn)
                }
            }
        }
        // Display the welcome view when appropriate.
        .welcomeSheet()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
