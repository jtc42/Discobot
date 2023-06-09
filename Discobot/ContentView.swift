//
//  ContentView.swift
//  Discobot
//
//  Created by Joel Collins on 11/03/2023.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FeedView().tabItem {
                Label("Feed", systemImage: "play.square.stack")
            }
            // Hide the tab bar in this tab (for now, as we only have 1 tab so it's a bit pointless)
            .toolbar(.hidden, for: .tabBar)
        }
        .onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        } // Explicitly force background, see https://stackoverflow.com/questions/70867033/ios-tabview-in-swiftui-loses-background-when-content-of-the-navigationview-is
        // Display the welcome view when appropriate.
        .welcomeSheet()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
