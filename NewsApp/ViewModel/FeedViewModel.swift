//
//  FeedViewModel.swift
//  NewsApp
//
//  Created by Tim DiLauro on 1/1/20.
//  Copyright © 2020 Five Lions. All rights reserved.
//

import Foundation
import Combine

class FeedViewModel: ObservableObject {

    @Published private(set) var itemViewModels = [FeedItemViewModel]()
    @Published var queryString: String = ""

    private let feed: NewsFeed

    private var resultSubscription: AnyCancellable?
    private var querySubscription: AnyCancellable?

    init(_ feed: NewsFeed) {
        self.feed = feed
        querySubscription = $queryString
            .assign(to: \.queryString, on: feed)
        resultSubscription = feed.$newsItems
            .map { $0.map { FeedItemViewModel($0) } }
            .assign(to: \.itemViewModels, on: self)
    }
}

extension FeedViewModel {

    func loadData() {
        feed.loadMoreData()
    }

    func currentItem(_ item: NewsItem) {
        feed.loadMoreData(ifListEndsWith: item)
    }

}
