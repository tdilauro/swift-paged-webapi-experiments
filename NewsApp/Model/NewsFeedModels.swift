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
    case queryError
    case requestError
}

enum ResponseStatus {
    case hasItems
    case other (explanation: String)
}

typealias FeedAPI = NewsAPIorg
typealias NewsItem = FeedAPI.NewsItem
typealias ApiResponse = FeedAPI.NewsApiResponse

class NewsFeed: ObservableObject {

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

    @Published var newsItems = [NewsItem]()
    @Published var queryString: String = ""

    private var loadStatus: LoadStatus = .ready(nextPage: 1)
    private var cancellable: AnyCancellable?

    private let feedAPI: FeedAPI
    private let itemSubject = PassthroughSubject<NewsItem?, Error>()
    private var urlSessionConfig = URLSessionConfiguration.default
    private var session: URLSession


    required init(apiKey: String) {
        feedAPI = NewsAPIorg(apiKey: apiKey)
        let sessionConfig = Self.setupURLSessionConfig(URLSessionConfiguration.default)
        session = URLSession(configuration: sessionConfig)
        cancellable = feedSubscription(feed: feedAPI, queryString: self.$queryString, session: self.session)
    }

}

extension NewsFeed {

    func newQuery() {
        newsItems.removeAll()
        loadStatus = .ready(nextPage: 1)
        loadMoreData()
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

    static func setupURLSessionConfig(_ config: URLSessionConfiguration) -> URLSessionConfiguration {
        config.allowsCellularAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.requestCachePolicy = .returnCacheDataElseLoad

        return config
    }
}

extension NewsFeed {

    private func feedSubscription(feed api: FeedAPI, queryString: Published<String>.Publisher, session: URLSession? = nil) -> AnyCancellable {

        let urlSession = session ?? self.session

        let queryPublisher = queryString
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .filter { "" != $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .tryMap { queryString -> FeedAPI.Query in
                guard let query = self.feedAPI.queryFromString(queryString) else {
                    throw NewsFeedError.queryError
                }
                self.newQuery()
                return query
            }
            .eraseToAnyPublisher()

        let pagePublisher = self.itemSubject
            .filter({ item in
                if let item = item, !self.nFromEnd(offset: 4, item: item) {
                    return false
                }
                return true
            })
            .removeDuplicates()
            .eraseToAnyPublisher()

        let publisher = queryPublisher
            .combineLatest(pagePublisher) { query, item in return (query, item) }
            .filter({ _, item -> Bool in
                guard case let .ready(nextPage) = self.loadStatus else { return false }

                self.loadStatus = .loading(page: nextPage)
                return true
            })
            .tryMap({ query, _ -> URLRequest in
                guard case let .loading(page) = self.loadStatus else {
                    throw NewsFeedError.pageError
                }
                guard let request = query.requestForPage(page) else {
                    throw NewsFeedError.queryError
                }
                return request
            })
            .flatMap({ request in
                urlSession.dataTaskPublisher(for: request)
                    .mapError { $0 as Error }
            })
            .map { $0.data }
            .decode(type: ApiResponse.self, decoder: JSONDecoder())
            .mapError({ error -> Error in
                self.loadStatus = .error
                print("unable to parse response")
                return error
            })
            .filter({ apiResponse -> Bool in
                switch apiResponse.responseStatus {
                case .hasItems: return true
                case .other (let message):
                    print(message)
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
                  receiveValue: { apiResponse in
                    self.newsItems.append(contentsOf: apiResponse.responseItems)
                    if case let .loading(page) = self.loadStatus {
                        self.loadStatus = .ready(nextPage: page + 1)
                    } else {
                        self.loadStatus = .done
                    }
                }
            )

        return publisher
    }

}

extension NewsFeed: RandomAccessCollection {

    typealias Element = NewsItem
    var startIndex: Int { newsItems.startIndex }
    var endIndex: Int { newsItems.endIndex }

    subscript(position: Int) -> NewsItem {
        return newsItems[position]
    }

}


class NewsAPIorg {

    private static let defaultBaseURL = URL(string: "https://newsapi.org/v2/everything")!

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

    convenience init(apiKey: String) {
        self.init(Self.defaultBaseURL, apiKey: apiKey)
    }

}

extension NewsAPIorg {

    public func requestFor(query: String? = nil, page: Int) -> URLRequest? {
        guard
            let queryURL = buildQueryURL(query),
            let pageURL = Self.getPageURL(page, from: queryURL)
            else { return nil }
        return requestWithXApiKeyHeader(from: pageURL)
    }

    private func buildQueryURL(_ query: String?, language: String = "en") -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "language", value: "en"),
        ]
        if let query = query {
            components.queryItems?.append( URLQueryItem(name: "q", value: query) )
        }
        return components.url
    }

    private static func getPageURL(_ page: Int, from baseURL: URL) -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.queryItems = components.queryItems?.filter { $0.name != "page" }
        components.queryItems!.append(URLQueryItem(name: "page", value: "\(page)"))
        return components.url
    }

    private func requestWithXApiKeyHeader(from url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        return request
    }

}


extension NewsAPIorg {

    // MARK: Query

    struct Query {
        let feedAPI: NewsAPIorg
        var string: String
        var url: URL

        func requestForPage(_ page: Int) -> URLRequest? {
            guard let pageURL = getPageURL(page, from: url) else { return nil }
            return feedAPI.requestWithXApiKeyHeader(from: pageURL)
        }
    }

    func queryFromString(_ queryString: String) -> Query? {
        guard let queryURL = buildQueryURL(queryString) else { return nil }
        return Query(feedAPI: self, string: queryString, url: queryURL)
    }


    // MARK: NewsAPI.org JSON decoding

    struct NewsApiResponse: Decodable {
        var status: String
        var message: String?
        var articles: [NewsItem]?

        // MARK - Paged WebAPI (todo: Protocol?)
        var responseItems: [NewsItem] { return self.articles ?? [] }
        var responseStatus: ResponseStatus {
            switch self.status {
            case "ok": return .hasItems
            case "error": return .other(explanation: self.message ?? "response finished with status '\(self.status)'")
            default: return .other(explanation: "response finished with status '\(self.status)'")
            }
        }
    }

    struct NewsItem: Identifiable, Decodable, Equatable {
        var id = UUID()

        var title: String
        var author: String
        var imageURL: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = ( try? container.decode(String.self, forKey: .title) ) ?? "(untitled)"
            author = ( try? container.decode(String.self, forKey: .author) ) ?? "(unattributed)"
            imageURL = ( try? container.decode(String.self, forKey: .imageURL))
        }

        enum CodingKeys: String, CodingKey {
            case title, author
            case imageURL = "urlToImage"
        }
    }

}
