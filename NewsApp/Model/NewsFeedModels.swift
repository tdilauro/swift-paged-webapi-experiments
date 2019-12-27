//
//  NewsFeedModels.swift
//  NewsApp
//
//  Created by Tim DiLauro on 12/16/19.
//  Copyright © 2019 Five Lions. All rights reserved.
//

import Foundation
import Combine


enum NewsFeedError: Error {
    case pageError
}


enum FileError: Error {
    case `default`
}


class NewsFeed: ObservableObject, RandomAccessCollection {

    enum LoadStatus {
        case ready (nextPage: Int)
        case loading (page: Int)
        case error
        case done

        var isReady: Bool {
            switch self {
            case .ready: return true
            default: return false
            }
        }
    }

    private static let apiKey = "d7ef8df2c2c744c08febf60eeb87579d"
    private static let query = "Donald Trump".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!

    private static let urlBase = "https://newsapi.org/v2/everything?q=\(NewsFeed.query)&apiKey=\(NewsFeed.apiKey)&language=en&page="
    private static let baseName = "feed-page"

    private var loadStatus = LoadStatus.ready(nextPage: 1)
    private var cancellable: AnyCancellable?

    typealias Element = NewsItem

    @Published var newsItems = [NewsItem]()

    var startIndex: Int { newsItems.startIndex }
    var endIndex: Int { newsItems.endIndex }

    subscript(position: Int) -> NewsItem {
        return newsItems[position]
    }

    private let itemSubject = PassthroughSubject<NewsItem?, Error>()
    private lazy var pagePublisher: AnyPublisher<Data, Error> = {
        print("setting up pagePublisher")
        return itemSubject
            .filter({ article -> Bool in
                guard case let .ready(nextPage) = self.loadStatus else { return false }

                if let article = article, !self.nFromEnd(offset: 4, item: article) {
                    return false
                }

                print("filter: \(self.loadStatus) \(self.loadStatus.isReady)")
                self.loadStatus = .loading(page: nextPage)
                return true
            })
            .tryMap({ _ -> String in
                guard case let .loading(page) = self.loadStatus else {
                    throw NewsFeedError.pageError
                }
                return "\(Self.urlBase)\(page)"
            })
            .flatMap { urlString in
                URLSession.shared.dataTaskPublisher(for: URL(string: urlString)!)
                    .mapError { $0 as Error }
            }
            .map { $0.data }
            .eraseToAnyPublisher()
    }()


    init() {
        cancellable = pagePublisher
            .decode(type: NewsApiResponse.self, decoder: JSONDecoder())
            .mapError({ error -> Error in
                self.loadStatus = .error
                print("unable to parse response")
                return error
            })
            .filter({ apiResponse -> Bool in
                if apiResponse.status == "ok" {
                    return true
                } else {
                    self.loadStatus = .done
                    print("response finished with status '\(apiResponse.status)'")
                    return false
                }
            })
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error): print("subscription ended in error: \(error) - \(error.localizedDescription)")
                case .finished: print("subscription finished")
                }
            },
                  receiveValue: { data in
                    self.newsItems.append(contentsOf: data.articles!)
                    if case let .loading(page) = self.loadStatus {
                        self.loadStatus = .ready(nextPage: page + 1)
                    } else {
                        self.loadStatus = .done
                    }
            }
            )

    }

    func loadMoreData(ifListEndsWith: NewsItem? = nil) {
        itemSubject.send(ifListEndsWith)
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


//    static func readContent(forResource fileName: String, ofType: String?) throws -> Data {
//        print("reading from \(fileName).\(ofType!)")
//        if let path = Bundle.main.path(forResource: fileName, ofType: ofType),
//            let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) {
//            return data
//        } else {
//            throw FileError.default
//        }
//    }
//
//    func loadMoreArticlesLocal() {
//        let suffix = "json"
//
//        guard case let .ready(nextPage) = loadStatus else { return }
//
//        loadStatus = .loading(page: nextPage)
//
//        guard let path = Bundle.main.path(forResource: "\(Self.baseName)\(nextPage)", ofType: suffix) else {
//            print("Error determining path for file '\(Self.baseName)\(nextPage).\(suffix)'")
//            return
//        }
//
//        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else {
//            print("Unable to read JSON data from '\(path)'")
//            return
//        }
//
//        parseArticleJSON(json: jsonData)
//    }
}


class NewsAPIorg {

    private let defaultBaseURL = URL(string: "https://newsapi.org/v2/everything")!

    private let apiKey: String
    private let baseURL: URL

    init(_ url: URL, apiKey: String) {
        self.apiKey = apiKey
        self.baseURL = url
    }

    convenience init?(url: String, apiKey: String) {
        guard let url = URL(string: url) else {
            return nil
        }
        self.init(url, apiKey: apiKey)
    }

}

extension NewsAPIorg {

    func buildQueryURL(_ query: String, language: String = "en", from baseURL: String) -> URL? {
        guard var components = URLComponents(string: baseURL) else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "q", value: query)
        ]
        return components.url
    }

    static func getPageURL(_ page: Int, from baseURL: URL) -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.queryItems = components.queryItems?.filter { $0.name != "page" }
        components.queryItems!.append(URLQueryItem(name: "page", value: "\(page)"))
        return components.url
    }

    static func requestWithXApiKeyHeader(_ apiKey: String, from url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        return request
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
