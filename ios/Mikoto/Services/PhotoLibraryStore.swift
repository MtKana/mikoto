import SwiftUI
import Observation
import Supabase

@Observable
final class PhotoLibraryStore {
    var photos: [GeneratedPhoto] = []

    var userId: String?
    private let indexKey = "mikoto.library.index.v1"
    private let dir: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = base.appendingPathComponent("MikotoLibrary", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }()

    init() {
        load()
    }

    func add(_ photo: GeneratedPhoto) {
        let url = dir.appendingPathComponent("\(photo.id.uuidString).jpg")
        try? photo.imageData.write(to: url, options: .atomic)
        photos.insert(photo, at: 0)
        saveIndex()
        guard let userId else { return }
        Task {
            do {
                let record = PhotoRecord(
                    id: photo.id.uuidString,
                    userId: userId,
                    styleId: photo.styleID,
                    createdAt: iso8601.string(from: photo.createdAt)
                )
                try await supabase.from("photos").insert(record).execute()
                NSLog("[PhotoLibrary] synced photo %@ to Supabase", photo.id.uuidString)
            } catch {
                NSLog("[PhotoLibrary] sync failed: %@", error.localizedDescription)
            }
        }
    }

    func remove(_ photo: GeneratedPhoto) {
        let url = dir.appendingPathComponent("\(photo.id.uuidString).jpg")
        try? FileManager.default.removeItem(at: url)
        photos.removeAll { $0.id == photo.id }
        saveIndex()
        Task {
            do {
                try await supabase.from("photos").delete().eq("id", value: photo.id.uuidString).execute()
            } catch {
                NSLog("[PhotoLibrary] delete sync failed: %@", error.localizedDescription)
            }
        }
    }

    func removeAll() {
        let snapshot = photos
        for photo in snapshot {
            let url = dir.appendingPathComponent("\(photo.id.uuidString).jpg")
            try? FileManager.default.removeItem(at: url)
        }
        photos.removeAll()
        saveIndex()
        guard let userId else { return }
        Task {
            do {
                try await supabase.from("photos").delete().eq("user_id", value: userId).execute()
            } catch {
                NSLog("[PhotoLibrary] delete all sync failed: %@", error.localizedDescription)
            }
        }
    }

    // MARK: - Supabase Sync

    @MainActor
    func loadFromSupabase(userId: String) async {
        self.userId = userId
        do {
            let records: [PhotoRecord] = try await supabase
                .from("photos")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value

            let remoteIds = Set(records.map(\.id))
            let localIds = Set(photos.map { $0.id.uuidString })
            let missingFromRemote = localIds.subtracting(remoteIds)

            for idStr in missingFromRemote {
                guard let photo = photos.first(where: { $0.id.uuidString == idStr }) else { continue }
                let record = PhotoRecord(
                    id: photo.id.uuidString,
                    userId: userId,
                    styleId: photo.styleID,
                    createdAt: iso8601.string(from: photo.createdAt)
                )
                try? await supabase.from("photos").insert(record).execute()
            }

            NSLog("[PhotoLibrary] synced %d local photos, %d remote records", photos.count, records.count)
        } catch {
            NSLog("[PhotoLibrary] load failed: %@", error.localizedDescription)
        }
    }

    // MARK: - Local Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: indexKey),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else {
            return
        }
        photos = entries.compactMap { entry in
            let url = dir.appendingPathComponent("\(entry.id.uuidString).jpg")
            guard let data = try? Data(contentsOf: url) else { return nil }
            return GeneratedPhoto(id: entry.id, imageData: data, styleID: entry.styleID, createdAt: entry.createdAt)
        }
    }

    private func saveIndex() {
        let entries = photos.map { Entry(id: $0.id, styleID: $0.styleID, createdAt: $0.createdAt) }
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: indexKey)
        }
    }

    nonisolated private struct Entry: Codable, Sendable {
        let id: UUID
        let styleID: String
        let createdAt: Date
    }
}
