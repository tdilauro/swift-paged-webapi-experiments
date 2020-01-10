//
//  ItemImageViewModel.swift
//  NewsApp
//
//  Created by Tim DiLauro on 12/31/19.
//  Copyright © 2019 Five Lions. All rights reserved.
//

import UIKit
import Combine


class ItemImageViewModel: ObservableObject {

    @Published var image: UIImage

    static private let defaultFeedImage = UIImage(named: "Default Feed Icon")!
    static private let brokenLinkImage = UIImage(named: "Broken Link Icon")!
    static private let constraintErrorImage = UIImage(systemName: "photo")!

    private var cancellable: AnyCancellable?

    init(imageUrl: String?) {
        image = Self.defaultFeedImage

        guard let url = imageUrl else { return }

        let lowDataImagesAllowed = SettingsManager.shared.settings.lowDataImages

        cancellable = UIImage.publish(downloadedFrom: url,
                                      loadInLowDataMode: lowDataImagesAllowed,
                                      loadOnExpensiveNetwork: lowDataImagesAllowed,
                                      loadOnCellularNetwork: lowDataImagesAllowed)
            .catch({ error -> Just<UIImage?> in
                if let error = error as? URLError,
                   let reason = error.networkUnavailableReason {
                    switch reason {
                    case .cellular, .constrained, .expensive: return Just(Self.constraintErrorImage)
                    default: return Just(nil)
                    }
                }
                return Just(nil)
            })
            .replaceNil(with: Self.brokenLinkImage)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] image in
                self?.image = image
            })
    }

}
