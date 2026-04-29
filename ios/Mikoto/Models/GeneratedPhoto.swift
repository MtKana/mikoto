import Foundation
import SwiftUI

struct GeneratedPhoto: Identifiable, Hashable {
    let id: UUID
    let imageData: Data
    let styleID: String
    let createdAt: Date

    init(id: UUID = UUID(), imageData: Data, styleID: String, createdAt: Date = Date()) {
        self.id = id
        self.imageData = imageData
        self.styleID = styleID
        self.createdAt = createdAt
    }

    var uiImage: UIImage? { UIImage(data: imageData) }

    var style: PhotoStyle? {
        PhotoStyle.all.first(where: { $0.id == styleID })
    }
}
