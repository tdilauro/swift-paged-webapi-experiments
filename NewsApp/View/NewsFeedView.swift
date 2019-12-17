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
        List(newsFeed.newsItems) { (article: NewsItem) in
            NewsFeedListItem(article: article)
                .padding()
                .onAppear {
                    self.newsFeed.loadMoreData(ifListEndsWith: article)
            }
        }
        .onAppear {
            self.newsFeed.loadMoreData()
        }
    }
}

struct NewsFeedListItem: View {
    var article: NewsItem

    var body: some View {
        VStack(alignment: .leading) {
            Text(article.title)
                .font(.headline)
            Text(article.author)
                .font(.subheadline)
        }
    }
}


struct NewsFeedView_Previews: PreviewProvider {
    static var previews: some View {
        NewsFeedView()
    }
}
