//
//  ContentView.swift
//  NewsApp
//
//  Created by Tim DiLauro on 12/16/19.
//  Copyright © 2019 Five Lions. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    let apiKey = "d7ef8df2c2c744c08febf60eeb87579d"
    let feed = NewsFeed.self

    var body: some View {
        NewsFeedView( FeedViewModel(feed.init(apiKey: apiKey)) )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
