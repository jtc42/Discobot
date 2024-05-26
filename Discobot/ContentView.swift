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
            .padding(.top, 16.0)
            .navigationBarHidden(false)
            .toolbarBackground(.visible)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Chip(isOn: $albumsOn) {
                        Spacer() // Fix for bizarre padding/spacing issue
                        HStack {
                            Image(systemName: "square.stack").imageScale(.medium)
                            Text("Albums")
                        }
                    }.chipStyle(MyCustomeChipStyle())
                    Chip(isOn: $playlistsOn) {
                        HStack {
                            Image(systemName: "music.note.list").imageScale(.medium)
                            Text("Playlists")
                        }
                    }.chipStyle(MyCustomeChipStyle())
                    Chip(isOn: $stationsOn) {
                        HStack {
                            Image(systemName: "dot.radiowaves.left.and.right").imageScale(.medium)
                            Text("Stations")
                        }
                    }.chipStyle(MyCustomeChipStyle())
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
