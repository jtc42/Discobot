//
//  ContentView.swift
//  Discobot
//
//  Created by Joel Collins on 11/03/2023.
//

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
                ToolbarItemGroup(placement: .topBarLeading) {
                    Spacer()
                    Chip(isOn: $albumsOn) {
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
                    Spacer()
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
