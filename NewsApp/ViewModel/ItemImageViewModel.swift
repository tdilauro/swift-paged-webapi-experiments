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

    @Published var image: UIImage = UIImage()

    static private let defaultFeedImage = UIImage(named: "Default Feed Icon")!
    static private let brokenLinkImage = UIImage(named: "Broken Link Icon")!

    private var cancellable: AnyCancellable?

    init(imageUrl: String?) {
        image = Self.defaultFeedImage

        guard let url = imageUrl else { return }

        cancellable = UIImage.publish(downloadedFrom: url)
            .map { $0 == nil ? Self.brokenLinkImage : $0! }
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] image in
                guard let self = self else { return }
                self.image = image
             })
    }

}
