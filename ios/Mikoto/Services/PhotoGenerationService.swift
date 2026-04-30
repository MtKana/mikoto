import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

nonisolated enum PhotoGenError: LocalizedError {
    case imageProcessingFailed
    case authError
    case insufficientBalance
    case payloadTooLarge
    case rateLimited
    case serverError(Int)
    case noImageReturned
    case decodingFailed
    case missingConfig

    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed: "写真を処理できませんでした。別の写真をお試しください。"
        case .authError:             "AI機能が利用できません。アプリを再起動してください。"
        case .insufficientBalance:   "AI機能が一時的に利用できません。"
        case .payloadTooLarge:       "画像が大きすぎます。別の写真をお試しください。"
        case .rateLimited:           "リクエストが多すぎます。少し待ってからお試しください。"
        case .serverError:           "問題が発生しました。もう一度お試しください。"
        case .noImageReturned:       "画像を生成できませんでした。もう一度お試しください。"
        case .decodingFailed:        "画像データを読み込めませんでした。"
        case .missingConfig:         "設定エラー。もう一度お試しください。"
        }
    }
}

nonisolated struct PhotoGenerationService: Sendable {

    private static var toolkitURL: String {
        let configured = (Bundle.main.infoDictionary?["EXPO_PUBLIC_TOOLKIT_URL"] as? String) ?? ""
        return configured.isEmpty ? "https://toolkit.rork.com" : configured
    }

    private static var secretKey: String {
        (Bundle.main.infoDictionary?["EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY"] as? String) ?? ""
    }

    static func generate(from sourceImage: UIImage, style: PhotoStyle) async throws -> Data {
        let (imageData, mimeType) = try resizeForUpload(sourceImage)
        let base64 = imageData.base64EncodedString()

        guard !secretKey.isEmpty else { throw PhotoGenError.missingConfig }

        let url = URL(string: "\(toolkitURL)/v2/vercel/v1/chat/completions")!

        let body: [String: Any] = [
            "model": "google/gemini-3.1-flash-image-preview",
            "modalities": ["text", "image"],
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "image_url", "image_url": ["url": "data:\(mimeType);base64,\(base64)"]],
                        ["type": "text", "text": style.prompt]
                    ] as [Any]
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(secretKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 180

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PhotoGenError.serverError(0) }
        switch http.statusCode {
        case 200: break
        case 401: throw PhotoGenError.authError
        case 402: throw PhotoGenError.insufficientBalance
        case 413: throw PhotoGenError.payloadTooLarge
        case 429: throw PhotoGenError.rateLimited
        default:  throw PhotoGenError.serverError(http.statusCode)
        }

        guard let dataURI = extractFirstImage(from: data) else {
            throw PhotoGenError.noImageReturned
        }
        let raw: String
        if dataURI.hasPrefix("data:"), let comma = dataURI.firstIndex(of: ",") {
            raw = String(dataURI[dataURI.index(after: comma)...])
        } else {
            raw = dataURI
        }
        guard let outputData = Data(base64Encoded: raw) else {
            throw PhotoGenError.decodingFailed
        }
        return outputData
    }

    private static func extractFirstImage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any] else {
            return nil
        }
        if let images = message["images"] as? [Any] {
            for item in images {
                if let str = item as? String { return str }
                if let obj = item as? [String: Any] {
                    if let urlObj = obj["image_url"] as? [String: Any], let url = urlObj["url"] as? String {
                        return url
                    }
                    if let url = obj["url"] as? String { return url }
                }
            }
        }
        if let content = message["content"] as? [[String: Any]] {
            for part in content {
                if let urlObj = part["image_url"] as? [String: Any], let url = urlObj["url"] as? String {
                    return url
                }
            }
        }
        return nil
    }

    private static func resizeForUpload(_ image: UIImage, maxBytes: Int = 3_000_000) throws -> (Data, String) {
        guard let cgSource = image.cgImage else { throw PhotoGenError.imageProcessingFailed }
        let ladder: [(Int, Double)] = [(1280, 0.82), (1024, 0.78), (832, 0.74), (640, 0.70), (512, 0.65)]

        for (maxPixel, quality) in ladder {
            let scale = CGFloat(maxPixel) / CGFloat(max(cgSource.width, cgSource.height))
            let targetWidth = scale < 1 ? Int(CGFloat(cgSource.width) * scale) : cgSource.width
            let targetHeight = scale < 1 ? Int(CGFloat(cgSource.height) * scale) : cgSource.height

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let context = CGContext(
                data: nil,
                width: targetWidth,
                height: targetHeight,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { continue }
            context.interpolationQuality = .high
            context.draw(cgSource, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
            guard let resized = context.makeImage() else { continue }

            let outData = NSMutableData()
            guard let dest = CGImageDestinationCreateWithData(outData, UTType.jpeg.identifier as CFString, 1, nil) else { continue }
            CGImageDestinationAddImage(dest, resized, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
            guard CGImageDestinationFinalize(dest) else { continue }
            let data = outData as Data
            if data.count <= maxBytes {
                return (data, "image/jpeg")
            }
        }
        throw PhotoGenError.payloadTooLarge
    }
}
private let supabaseURL: String = {
    let configured = (Bundle.main.infoDictionary?["EXPO_PUBLIC_SUPABASE_URL"] as? String) ?? ""
    return configured.isEmpty ? "https://nmunmpgljrtljithkjic.supabase.co" : configured
}()

private let supabaseAnonKey: String = {
    let configured = (Bundle.main.infoDictionary?["EXPO_PUBLIC_SUPABASE_ANON_KEY"] as? String) ?? ""
    return configured.isEmpty ? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5tdW5tcGdsanJ0bGppdGhramljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczODE1NDgsImV4cCI6MjA5Mjk1NzU0OH0.AeS7jZILVz52tGxhMLJCGB4kYCKeqDRVWCy3u3oLo-I" : configured
}()

