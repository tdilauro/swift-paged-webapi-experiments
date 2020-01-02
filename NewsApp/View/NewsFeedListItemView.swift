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
    @State var hasURL: Bool = false

    init(_ viewModel: FeedItemViewModel) {
        self.itemVM = viewModel
        hasURL = itemVM.hasURL
    }

    var body: some View {
        HStack {
            NavigationLink(destination: WebView(url: itemVM.item.url!), isActive: self.$hasURL) {
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
}


//struct NewsFeedListItem_Previews: PreviewProvider {
//    static var previews: some View {
//        NewsFeedListItem()
//    }
//}
