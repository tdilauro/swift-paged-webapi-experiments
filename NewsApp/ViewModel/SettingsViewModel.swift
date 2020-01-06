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

    private let settingsManager: SettingsManager
    private var settings: SettingsManager.Settings

    @Published var apiKey: String = ""

    private var cancellables = Set<AnyCancellable>()

    init(settingsManager: SettingsManager? = nil) {
        if settingsManager != nil {
            self.settingsManager = settingsManager!
        } else {
            self.settingsManager = SettingsManager.shared
        }
        settings = self.settingsManager.settings

        apiKey = settings.apiKey
        print("initial API key value: (\(apiKey))")
        trackCentralSettings()
        trackLocalChanges()
    }

    func trackCentralSettings() {

        // update local properties when centralized model changes
        self.settingsManager.$settings
            .receive(on: RunLoop.main)
            .sink(receiveValue: { settings in
                print("centralized model changed (\(settings.apiKey))")
                self.apiKey = settings.apiKey
            })
            .store(in: &cancellables)
    }

    func trackLocalChanges() {

        // update local copy of model with UI updated
        $apiKey
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .receive(on: RunLoop.main)
            .sink(receiveValue: {
                print("settingsVM apiKey changed (\($0))")
                self.settings.apiKey = $0 })
            .store(in: &cancellables)
    }

    func save() {
        settingsManager.update(settings)
        settingsManager.save()
    }
}
