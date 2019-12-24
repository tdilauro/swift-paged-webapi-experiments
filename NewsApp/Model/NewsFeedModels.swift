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
    private static let query = "apple".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!

    private static let urlBase = "https://newsapi.org/v2/everything?q=\(NewsFeed.query)&apiKey=\(NewsFeed.apiKey)&language=en&page="
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

    func loadMoreData(ifListEndsWith: NewsItem? = nil) {
        guard case let .ready(nextPage) = loadStatus else { return }

        if let article = ifListEndsWith, !nFromEnd(offset: 4, item: article) {
            return
        }

        print("loading page \(nextPage)")

        let useRemote = true
        useRemote ? loadMoreArticlesRemote() : loadMoreArticlesLocal()
//        loadMoreArticlesRemote()
//        loadMoreArticlesLocal()
    }

    func nFromEnd(offset: Int, item: NewsItem) -> Bool {
        guard !newsItems.isEmpty else {
            return false
        }

        guard let itemIndex = firstIndex(where: { AnyHashable($0.id) == AnyHashable(item.id) }) else {
            return false
        }

        let distance = self.distance(from: itemIndex, to: endIndex)
        let offset = offset < count ? offset : count - 1
        return offset == (distance - 1)
    }


    func loadMoreArticlesRemote() {
        guard case let .ready(nextPage) = loadStatus else { return }

        loadStatus = .loading(page: nextPage)

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

        guard case let .ready(nextPage) = loadStatus else { return }

        loadStatus = .loading(page: nextPage)

        guard let path = Bundle.main.path(forResource: "\(Self.baseName)\(nextPage)", ofType: suffix) else {
            print("Error determining path for file '\(Self.baseName)\(nextPage).\(suffix)'")
            return
        }

        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else {
            print("Unable to read JSON data from '\(path)'")
            return
        }

        parseArticleJSON(json: jsonData)
    }

    func parseArticleJSON(json: Data) {
        guard let apiResponse = try? JSONDecoder().decode(NewsApiResponse.self, from: json) else {
            self.loadStatus = .error
            print("unable to parse response")
            return
        }

        guard apiResponse.status == "ok" else {
            self.loadStatus = .done
            print("response finished with status '\(apiResponse.status)'")
            return
        }

        DispatchQueue.main.async {
            self.newsItems.append(contentsOf: apiResponse.articles!)
            if case let .loading(page) = self.loadStatus {
                self.loadStatus = .ready(nextPage: page + 1)
            } else {
                self.loadStatus =  .done
            }
        }
    }
}

struct NewsApiResponse: Decodable {
    var status: String
    var articles: [NewsItem]?
}


struct NewsItem: Identifiable, Decodable {
    var id = UUID()

    var title: String
    var author: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = ( try? container.decode(String.self, forKey: .title) ) ?? "(untitled)"
        author = ( try? container.decode(String.self, forKey: .author) ) ?? "(unattributed)"
    }

    enum CodingKeys: String, CodingKey {
        case title, author
    }
}
