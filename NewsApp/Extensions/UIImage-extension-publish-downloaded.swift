//
//  UIImage-extension-publish-downloaded.swift
//  NewsApp
//
//  Created by Tim DiLauro on 1/1/20.
//  Copyright © 2020 Five Lions. All rights reserved.
//

import UIKit
import Combine


enum ImageError: Error {
    case urlError(String)
}


extension UIImage {

    static func publish(downloadedFrom urlString: String,
                        loadInLowDataMode: Bool = true,
                        loadOnExpensiveNetwork: Bool = true,
                        loadOnCellularNetwork: Bool = true) -> AnyPublisher<UIImage?, Never> {

        func createURLRequest(url: URL) -> URLRequest {
            var request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
            request.allowsConstrainedNetworkAccess = loadInLowDataMode
            request.allowsExpensiveNetworkAccess = loadOnExpensiveNetwork
            request.allowsCellularAccess = loadOnCellularNetwork
            return request
        }

        return Result<String, Error>.Publisher(urlString)
            .tryMap({ urlString in
                guard let url = URL(string: urlString) else { throw ImageError.urlError(urlString) }
                return url
            })
            .map { createURLRequest(url: $0) }
            .flatMap({ request in
                URLSession.shared.dataTaskPublisher(for: request)
                    .mapError { $0 as Error }
            })
            .map { $0.data }
            .map { UIImage(data: $0) }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

}
