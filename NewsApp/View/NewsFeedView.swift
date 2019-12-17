//
//  NewsFeedView.swift
//  NewsApp
//
//  Created by Tim DiLauro on 12/16/19.
//  Copyright © 2019 Five Lions. All rights reserved.
//

import SwiftUI

struct NewsFeedView: View {
    @ObservedObject var newsFeed = NewsFeed()

    var body: some View {
        List(newsFeed.newsItems) { article in
            VStack(alignment: .leading) {
                Text(article.title)
                    .font(.headline)
                Text(article.author)
                    .font(.subheadline)
            }
            .padding()
        }
//        .onAppear(perform: newsFeed.loadMoreArticlesRemote)
        .onAppear(perform: newsFeed.loadMoreArticlesLocal)
    }
}

struct NewsFeedView_Previews: PreviewProvider {
    static var previews: some View {
        NewsFeedView()
    }
}
