import CoreGraphics
import Foundation
import UIKit
import Vision

enum OCRError: LocalizedError {
    case invalidImage
    case visionFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidImage: "无法读取图片"
        case .visionFailed(let error): "识别失败：\(error.localizedDescription)"
        }
    }
}

/// Wrapper around the iOS 18+ `RecognizeTextRequest` API with Chinese support.
enum OCRService {
    struct Observation: Sendable, Identifiable {
        let id = UUID()
        let text: String
        let confidence: Float
        /// Bounding box in Vision's normalized coordinates (0..1, origin bottom-left).
        let boundingBox: CGRect
    }

    static func recognizeText(from image: UIImage) async throws -> [Observation] {
        guard let cgImage = image.cgImage else { throw OCRError.invalidImage }

        var request = RecognizeTextRequest()
        request.recognitionLanguages = [
            Locale.Language(identifier: "zh-Hans"),
            Locale.Language(identifier: "en-US"),
        ]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        do {
            let results = try await request.perform(on: cgImage)
            return results.compactMap { obs in
                guard let top = obs.topCandidates(1).first else { return nil }
                return Observation(
                    text: top.string,
                    confidence: top.confidence,
                    boundingBox: obs.boundingBox.cgRect
                )
            }
        } catch {
            throw OCRError.visionFailed(error)
        }
    }

    /// Returns all observations joined as a single newline-separated string,
    /// sorted roughly top-to-bottom then left-to-right.
    static func joinedText(_ observations: [Observation]) -> String {
        observations
            .sorted {
                if abs($0.boundingBox.midY - $1.boundingBox.midY) > 0.01 {
                    return $0.boundingBox.midY > $1.boundingBox.midY
                }
                return $0.boundingBox.minX < $1.boundingBox.minX
            }
            .map(\.text)
            .joined(separator: "\n")
    }
}
