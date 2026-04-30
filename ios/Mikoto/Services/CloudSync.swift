import Foundation
import Observation

@Observable
final class CloudSync {
    var isSyncing: Bool = false
    var lastError: String?
    var lastSyncedAt: Date?

    private let supabaseURL: String
    private let anonKey: String
    private weak var library: PhotoLibraryStore?
    private weak var credits: CreditStore?
    private weak var userStyle: UserStyleStore?
    private var currentUserID: String?

    private var profilePushTask: Task<Void, Never>?
    private var stylePushTask: Task<Void, Never>?

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    init() {
        let url = Config.EXPO_PUBLIC_SUPABASE_URL
        self.supabaseURL = url.isEmpty ? "https://nmunmpgljrtljithkjic.supabase.co" : url
        let key = Config.EXPO_PUBLIC_SUPABASE_ANON_KEY
        self.anonKey = key.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5tdW5tcGdsanJ0bGppdGhramljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczODE1NDgsImV4cCI6MjA5Mjk1NzU0OH0.AeS7jZILVz52tGxhMLJCGB4kYCKeqDRVWCy3u3oLo-I" : key
    }

    @MainActor
    func attach(library: PhotoLibraryStore, credits: CreditStore, userStyle: UserStyleStore) {
        self.library = library
        self.credits = credits
        self.userStyle = userStyle

        library.onAdd = { [weak self] photo in self?.uploadPhoto(photo) }
        library.onRemove = { [weak self] photo in self?.deletePhoto(photo) }
        credits.onChange = { [weak self] in self?.schedulePushProfile() }
        userStyle.onChange = { [weak self] in self?.schedulePushStyle() }
    }

    @MainActor
    func userDidChange(_ userID: String?) {
        currentUserID = userID
        if userID != nil {
            Task { await pullAll() }
        }
    }

    // MARK: - Pull on login

    @MainActor
    func pullAll() async {
        guard accessToken != nil else { return }
        isSyncing = true
        defer { isSyncing = false }

        await pullProfile()
        await pullStyle()
        await pullPhotos()

        lastSyncedAt = Date()
    }

    @MainActor
    private func pullProfile() async {
        guard let userID = currentUserID else { return }
        let path = "/rest/v1/profiles?id=eq.\(userID)&select=*"
        do {
            let (data, http) = try await request(path: path)
            guard http.statusCode == 200 else { return }
            let rows = try JSONDecoder().decode([ProfileRow].self, from: data)
            guard let row = rows.first, let credits else { return }

            credits.applyRemote(
                plan: CreditStore.Plan(rawValue: row.plan) ?? .free,
                cycle: CreditStore.BillingCycle(rawValue: row.cycle) ?? .monthly,
                balance: row.balance,
                trialActive: row.trial_active,
                trialEndsAt: row.trial_ends_at.flatMap { Self.iso.date(from: $0) },
                renewalDate: Self.iso.date(from: row.renewal_date) ?? Date(),
                totalGenerated: row.total_generated
            )
        } catch {
            lastError = error.localizedDescription
        }
    }

    @MainActor
    private func pullStyle() async {
        guard let userID = currentUserID else { return }
        let path = "/rest/v1/user_styles?user_id=eq.\(userID)&select=data"
        do {
            let (data, http) = try await request(path: path)
            guard http.statusCode == 200 else { return }
            struct Row: Decodable { let data: UserStyleData }
            if let row = (try JSONDecoder().decode([Row].self, from: data)).first {
                userStyle?.applyRemote(row.data)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    @MainActor
    private func pullPhotos() async {
        guard let userID = currentUserID, let library else { return }
        let path = "/rest/v1/photos?user_id=eq.\(userID)&select=*&order=created_at.desc"
        do {
            let (data, http) = try await request(path: path)
            guard http.statusCode == 200 else { return }
            let rows = try JSONDecoder().decode([PhotoRow].self, from: data)
            let localIDs = Set(library.photos.map { $0.id })

            for row in rows {
                guard let uuid = UUID(uuidString: row.id), !localIDs.contains(uuid) else { continue }
                guard let imageData = await downloadObject(path: row.storage_path) else { continue }
                let createdAt = Self.iso.date(from: row.created_at) ?? Date()
                let photo = GeneratedPhoto(id: uuid, imageData: imageData, styleID: row.style_id, createdAt: createdAt)
                library.insertFromRemote(photo)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Push profile (debounced)

    @MainActor
    private func schedulePushProfile() {
        profilePushTask?.cancel()
        profilePushTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await self?.pushProfile()
        }
    }

    @MainActor
    private func pushProfile() async {
        guard let userID = currentUserID, let credits, accessToken != nil else { return }
        let payload: [String: Any] = [
            "id": userID,
            "plan": credits.plan.rawValue,
            "cycle": credits.cycle.rawValue,
            "balance": credits.balance,
            "trial_active": credits.trialActive,
            "trial_ends_at": credits.trialEndsAt.map { Self.iso.string(from: $0) } as Any,
            "renewal_date": Self.iso.string(from: credits.renewalDate),
            "total_generated": credits.totalGenerated,
            "updated_at": Self.iso.string(from: Date())
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        _ = try? await request(
            path: "/rest/v1/profiles?on_conflict=id",
            method: "POST",
            body: body,
            prefer: "resolution=merge-duplicates,return=minimal"
        )
    }

    // MARK: - Push style (debounced)

    @MainActor
    private func schedulePushStyle() {
        stylePushTask?.cancel()
        stylePushTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await self?.pushStyle()
        }
    }

    @MainActor
    private func pushStyle() async {
        guard let userID = currentUserID, accessToken != nil else { return }
        guard let data = userStyle?.data else {
            // delete row
            _ = try? await request(
                path: "/rest/v1/user_styles?user_id=eq.\(userID)",
                method: "DELETE"
            )
            return
        }
        guard let dataJSON = try? JSONEncoder().encode(data),
              let dataObj = try? JSONSerialization.jsonObject(with: dataJSON) else { return }
        let payload: [String: Any] = [
            "user_id": userID,
            "data": dataObj,
            "updated_at": Self.iso.string(from: Date())
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        _ = try? await request(
            path: "/rest/v1/user_styles?on_conflict=user_id",
            method: "POST",
            body: body,
            prefer: "resolution=merge-duplicates,return=minimal"
        )
    }

    // MARK: - Photo upload / delete

    @MainActor
    private func uploadPhoto(_ photo: GeneratedPhoto) {
        guard let userID = currentUserID, accessToken != nil else { return }
        let path = "\(userID)/\(photo.id.uuidString).jpg"
        Task.detached { [supabaseURL, anonKey, weak self] in
            guard let token = await self?.accessToken else { return }
            var req = URLRequest(url: URL(string: "\(supabaseURL)/storage/v1/object/photos/\(path)")!)
            req.httpMethod = "POST"
            req.setValue(anonKey, forHTTPHeaderField: "apikey")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            req.setValue("3600", forHTTPHeaderField: "Cache-Control")
            req.setValue("true", forHTTPHeaderField: "x-upsert")
            req.httpBody = photo.imageData
            _ = try? await URLSession.shared.data(for: req)

            // Insert metadata row
            let payload: [String: Any] = [
                "id": photo.id.uuidString,
                "user_id": userID,
                "style_id": photo.styleID,
                "storage_path": path,
                "created_at": CloudSync.iso.string(from: photo.createdAt)
            ]
            guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
            var insertReq = URLRequest(url: URL(string: "\(supabaseURL)/rest/v1/photos?on_conflict=id")!)
            insertReq.httpMethod = "POST"
            insertReq.setValue(anonKey, forHTTPHeaderField: "apikey")
            insertReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            insertReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
            insertReq.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
            insertReq.httpBody = body
            _ = try? await URLSession.shared.data(for: insertReq)
        }
    }

    @MainActor
    private func deletePhoto(_ photo: GeneratedPhoto) {
        guard let userID = currentUserID, accessToken != nil else { return }
        let path = "\(userID)/\(photo.id.uuidString).jpg"
        Task.detached { [supabaseURL, anonKey, weak self] in
            guard let token = await self?.accessToken else { return }
            var req = URLRequest(url: URL(string: "\(supabaseURL)/storage/v1/object/photos/\(path)")!)
            req.httpMethod = "DELETE"
            req.setValue(anonKey, forHTTPHeaderField: "apikey")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: req)

            var rowReq = URLRequest(url: URL(string: "\(supabaseURL)/rest/v1/photos?id=eq.\(photo.id.uuidString)")!)
            rowReq.httpMethod = "DELETE"
            rowReq.setValue(anonKey, forHTTPHeaderField: "apikey")
            rowReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: rowReq)
        }
    }

    @MainActor
    private func downloadObject(path: String) async -> Data? {
        guard let token = accessToken,
              let url = URL(string: "\(supabaseURL)/storage/v1/object/photos/\(path)") else { return nil }
        var req = URLRequest(url: url)
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return data
        } catch {
            return nil
        }
    }

    // MARK: - HTTP helpers

    private var accessToken: String? { KeychainHelper.get("access_token") }

    private func request(
        path: String,
        method: String = "GET",
        body: Data? = nil,
        prefer: String? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        guard let token = accessToken,
              let url = URL(string: "\(supabaseURL)\(path)") else {
            throw URLError(.userAuthenticationRequired)
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let prefer { req.setValue(prefer, forHTTPHeaderField: "Prefer") }
        req.httpBody = body
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        return (data, http)
    }
}

nonisolated private struct ProfileRow: Codable, Sendable {
    let id: String
    let display_name: String?
    let plan: String
    let cycle: String
    let balance: Int
    let trial_active: Bool
    let trial_ends_at: String?
    let renewal_date: String
    let total_generated: Int
}

nonisolated private struct PhotoRow: Codable, Sendable {
    let id: String
    let user_id: String
    let style_id: String
    let storage_path: String
    let created_at: String
}
