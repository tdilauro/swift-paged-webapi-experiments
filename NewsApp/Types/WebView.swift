//
//  WebView.swift
//  NewsApp
//
//  Created by Tim DiLauro on 1/1/20.
//  Copyright © 2020 Five Lions. All rights reserved.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    typealias UIViewType = WKWebView

    private let urlString: String

    init(url urlString: String) {
        self.urlString = urlString
    }

    func makeUIView(context: UIViewRepresentableContext<WebView>) -> WebView.UIViewType {
        let view = WKWebView()
        if let url = URL(string: self.urlString) {
            let request =  URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 3.0)
            view.load(request)
        }
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
    }

}

extension WebView {

    func makeCoordinator() -> WebView.Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {

        let parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

    }

}
