//
//  FeedItemViewModel.swift
//  NewsApp
//
//  Created by Tim DiLauro on 1/1/20.
//  Copyright © 2020 Five Lions. All rights reserved.
//

import Foundation

class FeedItemViewModel {

    var item: NewsItem

    init(_ feedItem: NewsItem) {
        self.item = feedItem
    }

}

extension FeedItemViewModel {

    var imageViewModel: ItemImageViewModel {
        ItemImageViewModel(imageUrl: item.imageURL)
    }

    var hasURL: Bool {
        item.url == nil ? false : true
    }

}
