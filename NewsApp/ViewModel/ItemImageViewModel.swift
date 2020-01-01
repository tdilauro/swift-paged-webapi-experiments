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
    
    private var cancellable: AnyCancellable?

    init(imageUrl: String?) {
        guard let url = imageUrl else { return }

        cancellable = UIImage.publish(downloadedFrom: url)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { image in
                guard let image = image else { return }
                self.image = image
             })
    }

}
