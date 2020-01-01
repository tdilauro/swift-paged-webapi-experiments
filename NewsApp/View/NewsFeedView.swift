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
                            NewsFeedListItemView(FeedItemViewModel(article))
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


struct NewsFeedView_Previews: PreviewProvider {
    static var previews: some View {
        NewsFeedView(newsFeed: NewsFeed())
    }
}
