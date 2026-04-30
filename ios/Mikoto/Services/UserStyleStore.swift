import Foundation
import Observation
import SwiftUI
import Supabase

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

    var userId: String?
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
        persistLocally()
        guard let userId else { return }
        Task {
            do {
                let record = UserStyleRecord(userId: userId, styleData: data)
                try await supabase.from("user_styles").upsert(record, onConflict: "user_id").execute()
                NSLog("[UserStyleStore] synced to Supabase")
            } catch {
                NSLog("[UserStyleStore] sync failed: %@", error.localizedDescription)
            }
        }
    }

    func reset() {
        data = nil
        UserDefaults.standard.removeObject(forKey: key)
        guard let userId else { return }
        Task {
            do {
                try await supabase.from("user_styles").delete().eq("user_id", value: userId).execute()
            } catch {
                NSLog("[UserStyleStore] delete failed: %@", error.localizedDescription)
            }
        }
    }

    // MARK: - Supabase Sync

    @MainActor
    func loadFromSupabase(userId: String) async {
        self.userId = userId
        do {
            let records: [UserStyleRecord] = try await supabase
                .from("user_styles")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            guard let record = records.first else {
                NSLog("[UserStyleStore] no style found in Supabase")
                if data != nil {
                    save(data!)
                }
                return
            }

            data = record.styleData
            persistLocally()
            NSLog("[UserStyleStore] loaded from Supabase: %@", record.styleData.nameJP)
        } catch {
            NSLog("[UserStyleStore] load failed: %@", error.localizedDescription)
        }
    }

    // MARK: - Local Persistence

    private func persistLocally() {
        guard let data else { return }
        if let bytes = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(bytes, forKey: key)
        }
    }
}
