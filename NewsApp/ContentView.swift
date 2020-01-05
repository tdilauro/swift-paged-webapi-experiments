//
//  ContentView.swift
//  NewsApp
//
//  Created by Tim DiLauro on 12/16/19.
//  Copyright © 2019 Five Lions. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var settingsVM = SettingsViewModel()
    @State var presentingSettings = false

//    let apiKey = "d7ef8df2c2c744c08febf60eeb87579d"
    let feed = NewsFeed.self

    var body: some View {
        NavigationView {
            NewsFeedView( FeedViewModel(feed.init(apiKey: settingsVM.apiKey)) )
                .sheet(isPresented: $presentingSettings) {
                    SettingsView(settingsVM: self.settingsVM)
            }
            .navigationBarTitle(Text("NewsFeed"))
            .navigationBarItems(
                trailing: Button(action: { self.presentingSettings = true }) { Text("Settings") }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
