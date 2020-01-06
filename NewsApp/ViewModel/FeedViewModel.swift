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

    @Published private var feed: NewsFeed
    private let settingsManager: SettingsManager

//    private var cancellables = Set<AnyCancellable>()
    private var settingsSubscription: AnyCancellable?
    private var apiKeySubscription: AnyCancellable?
    private var itemsSubscription: AnyCancellable?
    private var querySubscription: AnyCancellable?


    init(settingsManager: SettingsManager? = nil) {
        print("*** Initializing FeedViewModel")
        if settingsManager != nil {
            self.settingsManager = settingsManager!
        } else {
            self.settingsManager = SettingsManager.shared
        }

        let apiKey = self.settingsManager.settings.apiKey
        self.apiKey = apiKey
        self.feed = NewsFeed(apiKey: apiKey)

        self.settingsSubscription = self.settingsManager.$settings
//            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .dropFirst()
            .map { $0.apiKey }
            .print("FeedVM: apiKey from Model")
            .receive(on: RunLoop.main)
            .assign(to: \.apiKey, on: self)
//            .store(in: &cancellables)

        self.apiKeySubscription = self.$apiKey
            .receive(on: RunLoop.main)
            .sink(receiveValue: { apiKey in
                print("FeedVM: api key updated (\(apiKey)). generating new feed.")
                self.queryString = ""
                self.feed = NewsFeed(apiKey: apiKey)

                self.querySubscription = self.$queryString
                    .assign(to: \.queryString, on: self.feed)
                self.itemsSubscription = self.feed.$newsItems
                    .map { $0.map { FeedItemViewModel($0) } }
                    .assign(to: \.itemViewModels, on: self)


            })
//            .store(in: &cancellables)

//        $queryString
//            .assign(to: \.queryString, on: self.feed)
//            .store(in: &cancellables)

//        feed.$newsItems
//            .map { $0.map { FeedItemViewModel($0) } }
//            .assign(to: \.itemViewModels, on: self)
//            .store(in: &cancellables)
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
