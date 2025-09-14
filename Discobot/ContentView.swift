//
//  ContentView.swift
//  Discobot
//
//  Created by Joel Collins on 11/03/2023.
//

import SwiftUI

struct ContentView: View {
    @State var albumsOn = UserDefaults.standard.valueExists(forKey: "albumsOn") ? UserDefaults.standard.bool(forKey: "albumsOn") : true
    @State var playlistsOn = UserDefaults.standard.valueExists(forKey: "playlistsOn") ? UserDefaults.standard.bool(forKey: "playlistsOn") : true
    @State var stationsOn = UserDefaults.standard.valueExists(forKey: "stationsOn") ? UserDefaults.standard.bool(forKey: "stationsOn") : false

    var body: some View {
        NavigationView {
            FeedView(
                albumsOn: $albumsOn,
                playlistsOn: $playlistsOn,
                stationsOn: $stationsOn
            )
//            .padding(.top, 16.0)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", action: {
                        albumsOn = true
                        playlistsOn = true
                        stationsOn = true
                    })
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Albums", systemImage: "square.stack", action: {
                        albumsOn = !albumsOn
                    }).tint(albumsOn ? .accentColor : .none)
                    Button("Playlists", systemImage: "music.note.list", action: {
                        playlistsOn = !playlistsOn
                    }).tint(playlistsOn ? .accentColor : .none)
                    Button("Stations", systemImage: "dot.radiowaves.left.and.right", action: {
                        stationsOn = !stationsOn
                    }).tint(stationsOn ? .accentColor : .none)
                }
            }
        }
        .onChange(of: albumsOn) {
            UserDefaults.standard.set(albumsOn, forKey: "albumsOn")
        }
        .onChange(of: playlistsOn) {
            UserDefaults.standard.set(playlistsOn, forKey: "playlistsOn")
        }
        .onChange(of: stationsOn) {
            UserDefaults.standard.set(stationsOn, forKey: "stationsOn")
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
