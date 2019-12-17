//
//  NewsFeedModels.swift
//  NewsApp
//
//  Created by Tim DiLauro on 12/16/19.
//  Copyright © 2019 Five Lions. All rights reserved.
//

import Foundation


class NewsFeed: ObservableObject, RandomAccessCollection {
    static let urlBase = "https://newsapi.org/v2/everything?q=apple&apiKey=<REDACTED>&language=en&page=1"

    typealias Element = NewsItem

    @Published var newsItems = [NewsItem]()

    var startIndex: Int { newsItems.startIndex }
    var endIndex: Int { newsItems.endIndex }

    subscript(position: Int) -> NewsItem {
        return newsItems[position]
    }

    func loadMoreArticles() {
        guard let url = URL(string: Self.urlBase) else {
            print("Invalid URL '\(Self.urlBase)'")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                print("Error \(error?.localizedDescription ?? "Unknown error") for URL '\(Self.urlBase)'")
                return
            }
            self.parseArticleJSON(json: data)
        }

//        guard let url = URL(
        task.resume()

    }

    func parseArticleJSON(json: Data) {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: json) else {
            print("Unable to parse JSON response")
            return
        }
        let topLevelMap = jsonObject as! [String: Any]
        guard topLevelMap["status"] as? String == "ok" else {
            print("Result 'status' not 'ok'")
            return
        }
        guard let articles = topLevelMap["articles"] as? [[String: Any]] else {
            print("No articles found.")
            return
        }

        var newArticles = [NewsItem]()
        for article in articles {
            guard let title = article["title"] as? String,
                let author = article["author"] as? String else {
                    continue
            }
            newArticles.append(NewsItem(title: title, author: author))
        }

        DispatchQueue.main.async {
            self.newsItems.append(contentsOf: newArticles)
        }

    }
}


class NewsItem: Identifiable {
    var uuid = UUID()

    var title: String
    var author: String

    init (title: String, author: String) {
        self.title = title
        self.author = author
    }
}
