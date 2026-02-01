import Vision
import CoreGraphics

enum OCRService {
    static func recognizeText(from cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines: [String] = observations.compactMap { obs in
                    obs.topCandidates(1).first?.string
                }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["zh-Hans", "en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// 轻量清洗：统一换行、去掉多余空白
    static func clean(_ text: String) -> String {
        // 统一换行
        var t = text.replacingOccurrences(of: "\r\n", with: "\n")
        t = t.replacingOccurrences(of: "\r", with: "\n")

        // 每行 trim，压缩空格（保守）
        let lines = t.split(separator: "\n", omittingEmptySubsequences: false).map { line -> String in
            let s = String(line).trimmingCharacters(in: .whitespaces)
            // 连续空格压成一个
            return s.replacingOccurrences(of: "[ \t]{2,}", with: " ", options: .regularExpression)
        }

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
