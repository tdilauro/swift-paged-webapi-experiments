//
//  Settings.swift
//  NewsApp
//
//  Created by Tim DiLauro on 1/3/20.
//  Copyright © 2020 Five Lions. All rights reserved.
//

import Foundation
import Combine


class Settings: ObservableObject {
    typealias Model = SettingsModel

    static let shared = Settings()

    @Published var model = Model()

    private var userDefaultsKey = Settings.settingsDefaultKey
    private var userDefaults = Settings.settingsDefaultStore
    private var encoder = Settings.defaultEncoder
    private var decoder = Settings.defaultDecoder

    private static let settingsDefaultStore = UserDefaults.standard
    private static let settingsDefaultKey: String = "Settings"
    private static let defaultDecoder = JSONDecoder()
    private static let defaultEncoder = JSONEncoder()

    private var cancellables = Set<AnyCancellable>()
    private var saveCancellable: AnyCancellable?

    // MARK: - Initializers

    private init(forKey key: String? = nil, store: UserDefaults? = nil, encoder: JSONEncoder? = nil, decoder: JSONDecoder? = nil) {
        if let key = key { self.userDefaultsKey = key }
        if let store = store { self.userDefaults = store }
        if let encoder = encoder { self.encoder = encoder }
        if let decoder = decoder { self.decoder = decoder }

        Self.load(forKey: key, store: store, decoder: decoder)
            .receive(on: RunLoop.main)
            .assign(to: \.model, on: self)
            .store(in: &cancellables)
    }

}

//MARK: - Serialization/Deserialization

extension Settings {

    static func load(forKey key: String? = nil, store: UserDefaults? = nil, decoder: JSONDecoder? = nil) -> AnyPublisher<Model, Never> {
        let store = store ?? Self.settingsDefaultStore
        let key = key ?? Self.settingsDefaultKey
        let decoder = decoder ?? Self.defaultDecoder

        return Result<Data?, Never>.Publisher(store.object(forKey: key) as? Data)
            .map { $0 == nil ? Data() : $0! }
            .decode(type: Model.self, decoder: decoder)
            .replaceError(with: Model())
            .eraseToAnyPublisher()
    }

    func save(_ model: Model, forKey key: String? = nil, store: UserDefaults? = nil, encoder: JSONEncoder? = nil) {

        let store = store ?? self.userDefaults
        let key = key ?? self.userDefaultsKey
        let encoder = encoder ?? self.encoder

        self.saveCancellable = self.$model
            .prefix(1)
            .encode(encoder: encoder)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Settings(): save pipeline encoding failed with error: \(error)")
                }
            }, receiveValue: { encoded in
                store.set(encoded, forKey: key)
            })
    }

}


// MARK: - Models

class SettingsModel: Codable {

    var apiKey: String

    init() {
        apiKey = ""
    }

    required init(from decoder: Decoder) throws {
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
