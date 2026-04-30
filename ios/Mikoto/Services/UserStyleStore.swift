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

    var onChange: (() -> Void)?
    private var suppressOnChange: Bool = false

    private let key = "mikoto.userstyle.v1"

    init() {
        if let bytes = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode(UserStyleData.self, from: bytes) {
            self.data = saved
        }
    }

    var style: PhotoStyle? {
        data?.toStyle()
    }

    var explanation: String? {
        data?.explanation
    }

    func save(_ data: UserStyleData) {
        self.data = data
        if let bytes = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(bytes, forKey: key)
        }
        if !suppressOnChange { onChange?() }
    }

    func reset() {
        data = nil
        UserDefaults.standard.removeObject(forKey: key)
        if !suppressOnChange { onChange?() }
    }

    func applyRemote(_ data: UserStyleData) {
        suppressOnChange = true
        defer { suppressOnChange = false }
        save(data)
    }
}
