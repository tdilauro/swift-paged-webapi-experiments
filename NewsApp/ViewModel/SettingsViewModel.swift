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
    let model: Settings.Model

    @Published var apiKey: String = ""

    private var cancellables = Set<AnyCancellable>()

    init() {
        settings = Settings.shared
        model = settings.model

        apiKey = model.apiKey

        // update local properties when centralized model changes
        settings.$model
            .receive(on: RunLoop.main)
            .sink(receiveValue: { model in
                self.apiKey = model.apiKey
            })
            .store(in: &cancellables)

        // update local copy of model with UI updated
        $apiKey
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .receive(on: RunLoop.main)
            .assign(to: \.apiKey, on: self.model)
            .store(in: &cancellables)
    }

    func save() {
        settingsManager.update(settings)
    }
}
