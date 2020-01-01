//
//  NewsFeedListItemView.swift
//  NewsApp
//
//  Created by Tim DiLauro on 1/1/20.
//  Copyright © 2020 Five Lions. All rights reserved.
//

import SwiftUI

struct NewsFeedListItemView: View {
    var itemVM: FeedItemViewModel

    init(_ viewModel: FeedItemViewModel) {
        itemVM = viewModel
    }

    var body: some View {
        HStack {
            NewsFeedListItemImage(viewModel: itemVM.imageViewModel)
            VStack(alignment: .leading) {
                Text(itemVM.item.title)
                    .font(.headline)
                Text(itemVM.item.author)
                    .font(.subheadline)
            }
        }
    }
}


//struct NewsFeedListItem_Previews: PreviewProvider {
//    static var previews: some View {
//        NewsFeedListItem()
//    }
//}
