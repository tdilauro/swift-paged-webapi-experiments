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
    @ObservedObject var feedVM = FeedViewModel()
    @State var presentingSettings = false

    var body: some View {
        NavigationView {
            NewsFeedView( feedVM )
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
