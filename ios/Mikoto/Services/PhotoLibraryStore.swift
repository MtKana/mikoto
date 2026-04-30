import SwiftUI
import Observation

@Observable
final class PhotoLibraryStore {
    var photos: [GeneratedPhoto] = []

    var onAdd: ((GeneratedPhoto) -> Void)?
    var onRemove: ((GeneratedPhoto) -> Void)?

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
        onAdd?(photo)
    }

    func insertFromRemote(_ photo: GeneratedPhoto) {
        guard !photos.contains(where: { $0.id == photo.id }) else { return }
        let url = dir.appendingPathComponent("\(photo.id.uuidString).jpg")
        try? photo.imageData.write(to: url, options: .atomic)
        photos.append(photo)
        photos.sort { $0.createdAt > $1.createdAt }
        saveIndex()
    }

    func remove(_ photo: GeneratedPhoto) {
        let url = dir.appendingPathComponent("\(photo.id.uuidString).jpg")
        try? FileManager.default.removeItem(at: url)
        photos.removeAll { $0.id == photo.id }
        saveIndex()
        onRemove?(photo)
    }

    func removeAll() {
        let snapshot = photos
        for photo in snapshot {
            let url = dir.appendingPathComponent("\(photo.id.uuidString).jpg")
            try? FileManager.default.removeItem(at: url)
        }
        photos.removeAll()
        saveIndex()
        for photo in snapshot { onRemove?(photo) }
    }

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
