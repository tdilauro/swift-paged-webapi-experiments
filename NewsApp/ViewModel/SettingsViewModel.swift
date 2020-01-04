//
//  SettingsViewModel.swift
//  NewsApp
//
//  Created by Tim DiLauro on 1/3/20.
//  Copyright © 2020 Five Lions. All rights reserved.
//

import Foundation
import Combine


class SettingsViewModel: ObservableObject {

    let settings: Settings

    @Published var apiKey: String

    private var cancellables = Set<AnyCancellable>()

    init() {
        settings = Settings.shared
        self.apiKey = settings.model.apiKey
    }

    func save() {
        $apiKey
            .receive(on: RunLoop.main)
            .assign(to: \.apiKey, on: settings.model)
            .store(in: &cancellables)
        self.settings.save()
    }
}
