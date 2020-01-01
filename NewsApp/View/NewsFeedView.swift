//
//  NewsFeedView.swift
//  NewsApp
//
//  Created by Tim DiLauro on 12/16/19.
//  Copyright © 2019 Five Lions. All rights reserved.
//

import SwiftUI

struct NewsFeedView: View {
    @ObservedObject var feedVM: FeedViewModel

    init(_ viewModel: FeedViewModel) {
        feedVM = viewModel
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Query")) {
                    HStack(alignment: .center) {
                        TextField("Query", text: $feedVM.queryString)
                            .modifier(ClearButton(text: $feedVM.queryString))
                            .multilineTextAlignment(.leading)
                    }
                }
                Section(header: Text("Results")) {
                    List {
                        ForEach(feedVM.itemViewModels, id: \.item.id) { (itemVM: FeedItemViewModel) in
                            NewsFeedListItemView(itemVM)
                                .padding()
                                .onAppear {
                                    self.feedVM.currentItem(itemVM.item)
                                }
                        }
                    }
                }
            }
            .onAppear { self.feedVM.loadData() }
            .navigationBarTitle(Text("NewsFeed"))
        }
    }
}


//struct NewsFeedView_Previews: PreviewProvider {
//    @ObservedObject static var feed = NewsFeed()
//
//    static var previews: some View {
//        NewsFeedView(FeedViewModel($feed))
//    }
//}
