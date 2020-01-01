//
//  NewsFeedListItemImage.swift
//  NewsApp
//
//  Created by Tim DiLauro on 1/1/20.
//  Copyright © 2020 Five Lions. All rights reserved.
//

import SwiftUI

struct NewsFeedListItemImage: View {
    @ObservedObject var viewModel: ItemImageViewModel
    
    var body: some View {
        Image(uiImage: viewModel.image)
            .resizable()
            .scaledToFit()
            .frame(width: 75)
    }
}

struct NewsFeedListItemImage_Previews: PreviewProvider {
    static var previews: some View {
        NewsFeedListItemImage(viewModel: ItemImageViewModel(imageUrl: "https://i.kinja-img.com/gawker-media/image/upload/c_fill,f_auto,fl_progressive,g_center,h_675,pg_1,q_80,w_1200/qe1minplawr9ybbhlxue.png"))
    }
}
