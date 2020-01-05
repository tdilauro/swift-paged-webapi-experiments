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

        let store = Self.settingsDefaultStore
        let key = Self.settingsDefaultKey

        let manager = fromUserDefaults(store, forKey: key, encoder: encoder, decoder: decoder)
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

        let semaphore = DispatchSemaphore(value: 0)
        _ = Result<Data?, Never>.Publisher(userDefaults.object(forKey: key) as? Data)
            .map { $0 == nil ? Data() : $0! }
            .decode(type: SettingsModel.self, decoder: decoder)
            .replaceError(with: SettingsModel())
            .eraseToAnyPublisher()
            .receive(on: RunLoop.main)
            .sink(receiveValue: { settings in
                self.settings = settings
                semaphore.signal()
            })
        _ = semaphore.wait(wallTimeout: .now() + .milliseconds(1_000))
    }

    func update(_ settings: Settings) {
        self.settings = settings
    }

    func save() {
        let userDefaults = self.userDefaults
        let key = self.userDefaultsKey
        let encoder = self.encoder

        let semaphore = DispatchSemaphore(value: 0)
        _ = self.$settings
            .prefix(1)
            .encode(encoder: encoder)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Settings(): save pipeline encoding failed with error: \(error)")
                }
                semaphore.signal()
            }, receiveValue: { encoded in
                print("storing settings: \(String(decoding: encoded, as: UTF8.self))")
                userDefaults.set(encoded, forKey: key)
                semaphore.signal()
            })
        _ = semaphore.wait(wallTimeout: .now() + .milliseconds(1_000))
    }

}


// MARK: - Models

struct SettingsModel: Codable {

    var apiKey: String

    init() {
        apiKey = ""
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        apiKey = (try? container.decode(String.self, forKey: .apiKey)) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(apiKey, forKey: .apiKey)
    }

    enum CodingKeys: String, CodingKey {
        case apiKey
    }
    
}
