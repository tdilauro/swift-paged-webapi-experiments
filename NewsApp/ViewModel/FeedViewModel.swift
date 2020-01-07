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
    @Published private var apiKey: String

    private var feed: NewsFeed?
    private let settingsManager: SettingsManager

    private var settingsSubscription: AnyCancellable?
    private var apiKeySubscription: AnyCancellable?
    private var itemsSubscription: AnyCancellable?
    private var querySubscription: AnyCancellable?


    init(settingsManager: SettingsManager? = nil) {
//        print("*** Initializing FeedViewModel")
        if settingsManager != nil {
            self.settingsManager = settingsManager!
        } else {
            self.settingsManager = SettingsManager.shared
        }

        self.apiKey = self.settingsManager.settings.apiKey

        startSubscriptions()
    }

    func startSubscriptions() {

        self.settingsSubscription = self.settingsManager.$settings
//            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .dropFirst()
            .map { $0.apiKey }
//            .print("FeedVM: apiKey from Model")
            .receive(on: RunLoop.main)
            .assign(to: \.apiKey, on: self)

        self.apiKeySubscription = self.$apiKey
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { apiKey in
//                print("FeedVM: api key updated (\(apiKey)). generating new feed.")
                self.restartFeed()
            })
    }

    func restartFeed() {
        // cancel any existing feed
        self.feed?.cancelSubscription()

        let feed = NewsFeed(apiKey: self.apiKey)
        self.feed = feed

        self.queryString = ""

        self.querySubscription = self.$queryString
            .sink(receiveValue: { feed.queryString = $0 })
        self.itemsSubscription = feed.$newsItems
            .map { $0.map { FeedItemViewModel($0) } }
            .assign(to: \.itemViewModels, on: self)
    }

}

extension FeedViewModel {

    func loadData() {
        feed?.loadMoreData()
    }

    func currentItem(_ item: NewsItem) {
        feed?.loadMoreData(ifListEndsWith: item)
    }

}
