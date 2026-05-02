import Foundation
import Observation
import SwiftUI

nonisolated struct UserStyleData: Codable, Sendable {
    let nameJP: String
    let nameRomaji: String
    let nameEN: String
    let tagline: String
    let description: String
    let explanation: String
    let prompt: String
    let mood: String
    let symbol: String
    let swatchHex: [String]

    func toStyle() -> PhotoStyle {
        let colors = swatchHex.compactMap { Color(hex: $0) }
        let safeColors: [Color] = colors.isEmpty
            ? [Theme.coral, Theme.lavender]
            : colors
        return PhotoStyle(
            id: "custom",
            nameJP: nameJP,
            nameRomaji: nameRomaji,
            nameEN: nameEN,
            tagline: tagline,
            description: description,
            prompt: prompt,
            swatch: safeColors,
            symbol: symbol.isEmpty ? "sparkles" : symbol,
            mood: mood
        )
    }
}

@Observable
final class UserStyleStore {
    var data: UserStyleData?

    private var userId: String?
    private var key: String { "mikoto.userstyle.\(userId ?? "default").v1" }

    var style: PhotoStyle? { data?.toStyle() }
    var explanation: String? { data?.explanation }

    func switchUser(_ userId: String) {
        self.userId = userId
        reload()
    }

    func save(_ data: UserStyleData) {
        self.data = data
        persist()
    }

    func reset() {
        data = nil
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func reload() {
        if let bytes = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode(UserStyleData.self, from: bytes) {
            data = saved
        } else {
            data = nil
        }
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
