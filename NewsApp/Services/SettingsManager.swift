//
//  Settings.swift
//  NewsApp
//
//  Created by Tim DiLauro on 1/3/20.
//  Copyright © 2020 Five Lions. All rights reserved.
//

import Foundation
import Combine


class SettingsManager: ObservableObject {
    typealias Settings = SettingsModel

    @Published var settings = Settings()

    static let shared = sharedUserDefaults()

    private var userDefaultsKey = SettingsManager.settingsDefaultKey
    private var userDefaults = SettingsManager.settingsDefaultStore
    private var encoder = SettingsManager.defaultEncoder
    private var decoder = SettingsManager.defaultDecoder

    private static let settingsDefaultStore = UserDefaults.standard
    private static let settingsDefaultKey: String = "Settings"
    private static let defaultDecoder = JSONDecoder()
    private static let defaultEncoder = JSONEncoder()


    // MARK: - Initializers

    private init(_ userDefaults: UserDefaults, forKey key: String, encoder: JSONEncoder, decoder: JSONDecoder) {

        self.userDefaults = userDefaults
        self.userDefaultsKey = key
        self.encoder = encoder
        self.decoder = decoder

    }

}

//MARK: - Factory Methods

extension SettingsManager {

    private static func sharedUserDefaults(encoder: JSONEncoder? = nil, decoder: JSONDecoder? = nil) -> SettingsManager {

        let userDefaults = Self.settingsDefaultStore
        let key = Self.settingsDefaultKey

        let manager = fromUserDefaults(userDefaults, forKey: key, encoder: encoder, decoder: decoder)
        manager.load()
        return manager
    }

    private static func fromUserDefaults(_ userDefaults: UserDefaults? = nil, forKey key: String? = nil, encoder: JSONEncoder? = nil, decoder: JSONDecoder? = nil) -> SettingsManager {
        let store = userDefaults ?? Self.settingsDefaultStore
        let key = key ?? Self.settingsDefaultKey
        let decoder = decoder ?? Self.defaultDecoder
        let encoder = encoder ?? Self.defaultEncoder

        return SettingsManager(store, forKey: key, encoder: encoder, decoder: decoder)
    }

}


// MARK: - Load/save

extension SettingsManager {

    func load() {
        let userDefaults = self.userDefaults
        let key = self.userDefaultsKey
        let decoder = self.decoder

        guard let data = userDefaults.object(forKey: key) as? Data else { return }
        guard let settings = try? decoder.decode(Settings.self, from: data) else { return }

        self.settings = settings
    }

    func update(_ settings: Settings) {
        self.settings = settings
    }

    func save() {
        do {
            let encoded = try self.encoder.encode(self.settings)
            self.userDefaults.set(encoded, forKey: self.userDefaultsKey)
        } catch {
            print("Error encoding settings data: '\(error)'")
        }
    }

}


// MARK: - Models

struct SettingsModel {

    var apiKey: String
    var lowDataImages: Bool

    init() {
        apiKey = ""
        lowDataImages = true
    }

}

extension SettingsModel: Codable {

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        apiKey = (try? container.decode(String.self, forKey: .apiKey)) ?? ""
        lowDataImages = (try? container.decode(Bool.self, forKey: .lowDataImages)) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(apiKey, forKey: .apiKey)
        try container.encode(lowDataImages, forKey: .lowDataImages)
    }

    enum CodingKeys: String, CodingKey {
        case apiKey
        case lowDataImages
    }

}
