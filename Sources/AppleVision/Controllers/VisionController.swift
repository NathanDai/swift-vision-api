import Vapor
import Vision
import CoreImage
import CoreGraphics

// MARK: - 模型定义
struct OCRResult: Content {
    let text: String
    let confidence: Float
    let boundingBox: BoundingBox
}

struct BoundingBox: Content {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

// MARK: - 控制器
struct VisionController: RouteCollection {
    // MARK: - 配置
    private let config = OCRConfig(
        languages: ["zh-Hans", "zh-Hant", "en"],
        minimumTextHeight: 0.01,
        recognitionLevel: .accurate,
        usesLanguageCorrection: true,
        automaticallyDetectsLanguage: true
    )
    
    func boot(routes: any RoutesBuilder) throws {
        routes.grouped("vision").post("ocr", use: ocr)
    }
    
    // MARK: - OCR 处理
    func ocr(req: Request) async throws -> [OCRResult] {
        let image = try await getImage(from: req)
        let request = createOCRRequest()
        try await performRecognition(image: image, request: request)
        return try processResults(from: request)
    }
}

// MARK: - 私有扩展
private extension VisionController {
    struct OCRConfig {
        let languages: [String]
        let minimumTextHeight: Float
        let recognitionLevel: VNRequestTextRecognitionLevel
        let usesLanguageCorrection: Bool
        let automaticallyDetectsLanguage: Bool
    }
    
    func getImage(from req: Request) async throws -> CGImage {
        let file = try req.content.get(File.self, at: "image")
        let imageData = Data(buffer: file.data)
        
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw Abort(.badRequest, reason: "无法解析图片数据")
        }
        
        return image
    }
    
    func createOCRRequest() -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = config.recognitionLevel
        request.usesLanguageCorrection = config.usesLanguageCorrection
        request.recognitionLanguages = config.languages
        request.minimumTextHeight = config.minimumTextHeight
        request.automaticallyDetectsLanguage = config.automaticallyDetectsLanguage
        return request
    }
    
    func performRecognition(image: CGImage, request: VNRecognizeTextRequest) async throws {
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
    }
    
    func processResults(from request: VNRecognizeTextRequest) throws -> [OCRResult] {
        guard let observations = request.results else { return [] }
        
        return observations.compactMap { observation -> OCRResult? in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            
            let box = observation.boundingBox
            return OCRResult(
                text: candidate.string,
                confidence: candidate.confidence,
                boundingBox: BoundingBox(
                    x: box.origin.x,
                    y: 1 - box.origin.y - box.size.height,  // 转换为网页坐标系（左上角为原点）
                    width: box.size.width,
                    height: box.size.height
                )
            )
        }
    }
}

// 扩展 Data 以支持转换为 CGImage
extension Data {
    func toCGImage() throws -> CGImage {
        guard let imageSource = CGImageSourceCreateWithData(self as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw Abort(.badRequest, reason: "无法解析图片数据")
        }
        return image
    }
}