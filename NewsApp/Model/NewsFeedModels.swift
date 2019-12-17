//
//  NewsFeedModels.swift
//  NewsApp
//
//  Created by Tim DiLauro on 12/16/19.
//  Copyright © 2019 Five Lions. All rights reserved.
//

import Foundation


class NewsFeed: ObservableObject, RandomAccessCollection {
    private static let apiKey = "<REDACTED>"
    private static let urlBase = "https://newsapi.org/v2/everything?q=apple&apiKey=\(NewsFeed.apiKey)&language=en&page="
    private static let baseName = "feed-page"
    private var loadStatus = LoadStatus.ready(nextPage: 1)

    typealias Element = NewsItem

    @Published var newsItems = [NewsItem]()

    var startIndex: Int { newsItems.startIndex }
    var endIndex: Int { newsItems.endIndex }

    subscript(position: Int) -> NewsItem {
        return newsItems[position]
    }


    enum LoadStatus {
        case ready (nextPage: Int)
        case loading (page: Int)
        case error
        case done
    }

    func loadMoreArticlesRemote() {
        guard case let .ready(nextPage) = loadStatus else { return }

        guard let url = URL(string: "\(Self.urlBase)\(nextPage)") else {
            print("Invalid URL '\(Self.urlBase)\(nextPage)'")
                return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let jsonData = data else {
                print("Error \(error?.localizedDescription ?? "Unknown error") for URL '\(Self.urlBase)'")
                return
            }
            self.loadStatus = .loading(page: nextPage)
            self.parseArticleJSON(json: jsonData)

        }

        task.resume()

    }

    func loadMoreArticlesLocal() {
        let suffix = "json"

        print("Load more data?")

        guard case let .ready(nextPage) = loadStatus else { return }

        guard let path = Bundle.main.path(forResource: "\(Self.baseName)\(nextPage)", ofType: suffix) else {
            print("Error determining path for file '\(Self.baseName)\(nextPage).\(suffix)'")
            return
        }

        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else {
            print("Unable to read JSON data from '\(path)'")
            return
        }

        loadStatus = .loading(page: nextPage)
        parseArticleJSON(json: jsonData)
    }

    func parseArticleJSON(json: Data) {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: json) else {
            print("Unable to parse JSON response")
            loadStatus = .error
            return
        }
        let topLevelMap = jsonObject as! [String: Any]
        guard topLevelMap["status"] as? String == "ok" else {
            print("Result 'status' not 'ok'")
            loadStatus = .done
            return
        }
        guard let articles = topLevelMap["articles"] as? [[String: Any]] else {
            print("No articles found.")
            loadStatus = .error
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
            if case let .loading(page) = self.loadStatus {
                self.loadStatus = .ready(nextPage: page + 1)
            } else {
                self.loadStatus =  .done
            }
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
