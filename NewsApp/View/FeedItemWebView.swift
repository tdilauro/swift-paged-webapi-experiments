//
//  FeedItemWebView.swift
//  NewsApp
//
//  Created by Tim DiLauro on 1/1/20.
//  Copyright © 2020 Five Lions. All rights reserved.
//

import SwiftUI

struct FeedItemWebView: View {
    var url: String

    var body: some View {
        WebView(url: url)
     }
}

struct FeedItemWebView_Previews: PreviewProvider {
    static var previews: some View {
        FeedItemWebView(url: "http://example.com")
    }
}
