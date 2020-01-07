//
//  FeedManager.swift
//  NewsApp
//
//  Created by Tim DiLauro on 12/16/19.
//  Copyright © 2019 Five Lions. All rights reserved.
//

import Foundation
import Combine


enum FeedError: Error {
    case pageError
    case queryError
    case requestError
}

enum ResponseStatus {
    case hasItems
    case other (explanation: String)
}

typealias FeedAPI = NewsAPIorg
typealias FeedItem = FeedAPI.Item
typealias ApiResponse = FeedAPI.ApiResponse

class FeedManager: ObservableObject {

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

    @Published var feedItems = [FeedItem]()
    @Published var queryString: String = ""
    private(set) var feedTitle: String

    private var loadStatus: LoadStatus = .ready(nextPage: 1)
    private var cancellable: AnyCancellable?

    private let feedAPI: FeedAPI
    private var apiKey: String
    private let itemSubject = PassthroughSubject<FeedItem?, Error>()
    private var urlSessionConfig = URLSessionConfiguration.default
    private var session: URLSession


    required init(apiKey: String) {
//        print("*** Initializing NewsFeed model with API key (\(apiKey))")
        self.apiKey = apiKey
        feedAPI = NewsAPIorg(apiKey: apiKey)
        feedTitle = type(of: feedAPI).title
        let sessionConfig = Self.setupURLSessionConfig(URLSessionConfiguration.default)
        session = URLSession(configuration: sessionConfig)
        cancellable = feedSubscription(feed: feedAPI, queryString: self.$queryString, session: self.session)
    }

//    deinit {
//        print("*** De-initializing NewsFeed model with API key (\(self.apiKey))")
//    }

}

extension FeedManager {

    func newQuery() {
        feedItems.removeAll()
        loadMoreData()
    }

    func loadMoreData(ifListEndsWith: FeedItem? = nil) {
        itemSubject.send(ifListEndsWith)
    }

    func nFromEnd(offset: Int, item: FeedItem) -> Bool {
        guard !feedItems.isEmpty else {
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
        config.requestCachePolicy = .reloadRevalidatingCacheData

        return config
    }
}

extension FeedManager {


    func cancelSubscription() {
        self.cancellable = nil
    }

    private func queryStringUpdatePublisher(queryString: Published<String>.Publisher) -> AnyPublisher<String, Never> {
        queryString
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .filter { "" != $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .eraseToAnyPublisher()
    }

    private func itemListExhaustedPublisher(distance fromExhaustion: Int) -> AnyPublisher<Void, Error> {
        self.itemSubject
            .filter({ item in
                if let item = item, !self.nFromEnd(offset: fromExhaustion, item: item) {
                    return false
                }
                return true
            })
            .removeDuplicates()
            .map { _ in }
            .eraseToAnyPublisher()
    }

    private func feedSubscription(feed api: FeedAPI, queryString: Published<String>.Publisher, session: URLSession) -> AnyCancellable {

        let queryPublisher = queryStringUpdatePublisher(queryString: queryString)
        let pageAdvanceEventPublisher = itemListExhaustedPublisher(distance: 4)

        let subscription = queryPublisher
            .tryMap({ queryString -> FeedAPI.Query in
                guard let query = api.queryFromString(queryString) else {
                    throw FeedError.queryError
                }
                self.loadStatus = .ready(nextPage: 1)
                self.newQuery()
                return query
            })
            .combineLatest(pageAdvanceEventPublisher) { query, _ in return query }
            .filter({ _ in
                guard case let .ready(nextPage) = self.loadStatus else { return false }

                self.loadStatus = .loading(page: nextPage)
                return true
            })
            .tryMap({ query -> URLRequest in
                guard case let .loading(page) = self.loadStatus else {
                    throw FeedError.pageError
                }
                guard let request = query.requestForPage(page) else {
                    throw FeedError.queryError
                }
                return request
            })
            .flatMap({ request in
                session.dataTaskPublisher(for: request)
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
                    case .finished: self.loadStatus = .done
                    }
                 },
                  receiveValue: { apiResponse in
                    self.feedItems.append(contentsOf: apiResponse.responseItems)
                    if case let .loading(page) = self.loadStatus {
                        self.loadStatus = .ready(nextPage: page + 1)
                    } else {
                        self.loadStatus = .done
                    }
                }
            )

        return subscription
    }

}

extension FeedManager: RandomAccessCollection {

    typealias Element = FeedItem
    var startIndex: Int { feedItems.startIndex }
    var endIndex: Int { feedItems.endIndex }

    subscript(position: Int) -> FeedItem {
        return feedItems[position]
    }

}
