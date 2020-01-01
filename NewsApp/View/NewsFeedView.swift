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
        NavigationView {
            Form {
                Section(header: Text("Query")) {
                    HStack(alignment: .center) {
                        TextField("Query", text: $newsFeed.queryString)
                            .modifier(ClearButton(text: $newsFeed.queryString))
                            .multilineTextAlignment(.leading)
                    }
                }
                Section(header: Text("Results")) {
                    List {
                        ForEach(newsFeed.newsItems) { (article: NewsItem) in
                            NewsFeedListItem(article: article)
                                .padding()
                                .onAppear {
                                    self.newsFeed.loadMoreData(ifListEndsWith: article)
                                }
                        }
                    }
                }
            }
            .onAppear { self.newsFeed.loadMoreData() }
            .navigationBarTitle(Text("NewsFeed"))
        }
    }
}

struct NewsFeedListItem: View {
    var article: NewsItem

    var body: some View {
        HStack {
            NewsFeedListItemImage(viewModel: ItemImageViewModel(imageUrl: article.imageURL))
            VStack(alignment: .leading) {
                Text(article.title)
                    .font(.headline)
                Text(article.author)
                    .font(.subheadline)
            }
        }
    }
}


struct NewsFeedView_Previews: PreviewProvider {
    static var previews: some View {
        NewsFeedView(newsFeed: NewsFeed())
    }
}
