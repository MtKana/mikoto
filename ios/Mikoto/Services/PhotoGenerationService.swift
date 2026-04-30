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

    private static let model = "gemini-2.5-flash-image"

    private static var apiKey: String {
        Secrets.googleAIApiKey
    }

    static func generate(from sourceImage: UIImage, style: PhotoStyle) async throws -> Data {
        let (imageData, mimeType) = try resizeForUpload(sourceImage)
        let base64 = imageData.base64EncodedString()

        guard !apiKey.isEmpty else { throw PhotoGenError.missingConfig }

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["inlineData": ["mimeType": mimeType, "data": base64]],
                        ["text": style.prompt]
                    ] as [Any]
                ]
            ],
            "generationConfig": [
                "responseModalities": ["IMAGE", "TEXT"]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 180

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PhotoGenError.serverError(0) }

        if http.statusCode != 200 {
            if let respString = String(data: data, encoding: .utf8) {
                NSLog("[PhotoGen] error %d: %@", http.statusCode, respString)
            }
            switch http.statusCode {
            case 400: throw PhotoGenError.imageProcessingFailed
            case 401, 403: throw PhotoGenError.authError
            case 413: throw PhotoGenError.payloadTooLarge
            case 429: throw PhotoGenError.rateLimited
            default:  throw PhotoGenError.serverError(http.statusCode)
            }
        }

        guard let imageBase64 = extractFirstImage(from: data) else {
            if let respString = String(data: data, encoding: .utf8) {
                NSLog("[PhotoGen] no image in response: %@", respString)
            }
            throw PhotoGenError.noImageReturned
        }
        guard let outputData = Data(base64Encoded: imageBase64) else {
            throw PhotoGenError.decodingFailed
        }
        return outputData
    }

    private static func extractFirstImage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            return nil
        }
        for part in parts {
            if let inlineData = part["inlineData"] as? [String: Any],
               let base64 = inlineData["data"] as? String {
                return base64
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

