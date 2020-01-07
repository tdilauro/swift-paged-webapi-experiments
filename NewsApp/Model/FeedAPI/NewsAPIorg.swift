//
//  NewsAPIorg.swift
//  NewsApp
//
//  Created by Tim DiLauro on 1/7/20.
//  Copyright © 2020 Five Lions. All rights reserved.
//

import Foundation

final class NewsAPIorg {

    static let title = "NewsAPI.org"
    private static let defaultBaseURL = URL(string: "https://newsapi.org/v2/everything")!

    private let apiKey: String
    private let baseURL: URL

    init(_ url: URL, apiKey: String) {
        //        print("*** Initializing NewsAPIorg model with API key (\(apiKey))")
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

//    deinit {
//        print("*** De-initializing NewsAPIorg model with API key (\(apiKey))")
//    }
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
//        print("setting X-Api-Key request header to (\(apiKey))")
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

}

// MARK: NewsAPI.org JSON decoding

extension NewsAPIorg {

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
        var url: String?
        var imageURL: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = ( try? container.decode(String.self, forKey: .title) ) ?? "(untitled)"
            author = ( try? container.decode(String.self, forKey: .author) ) ?? "(unattributed)"
            url = ( try? container.decode(String.self, forKey: .url))
            imageURL = ( try? container.decode(String.self, forKey: .imageURL))
        }

        enum CodingKeys: String, CodingKey {
            case title, author, url
            case imageURL = "urlToImage"
        }
    }

}
