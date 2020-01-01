//
//  ContentView.swift
//  NewsApp
//
//  Created by Tim DiLauro on 12/16/19.
//  Copyright © 2019 Five Lions. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    let newsFeed = NewsFeed()

    var body: some View {
        NewsFeedView(FeedViewModel(newsFeed))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
