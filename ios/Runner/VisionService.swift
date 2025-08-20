import Foundation
import Vision
import UIKit
import Flutter

/// iOS Vision Framework OCR 服務
///
/// 提供文字識別功能給 Flutter 應用程式使用
/// 使用 iOS 原生 Vision Framework 進行高精度 OCR 處理
class VisionService: NSObject {
    
    /// 註冊 Method Channel
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.app.scanner/vision",
            binaryMessenger: registrar.messenger()
        )
        
        let instance = VisionService()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    /// 處理 Method Channel 呼叫
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "recognizeText":
            handleRecognizeText(call, result: result)
        case "getAvailableEngines":
            handleGetAvailableEngines(result)
        case "setPreferredEngine":
            handleSetPreferredEngine(call, result: result)
        case "preprocessImage":
            handlePreprocessImage(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// 處理文字識別
    private func handleRecognizeText(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let imageData = args["imageData"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing imageData", details: nil))
            return
        }
        
        // 解析可選參數
        let language = args["language"] as? String ?? "zh-Hant"
        let recognitionLevel = args["recognitionLevel"] as? String ?? "accurate"
        let usesLanguageCorrection = args["usesLanguageCorrection"] as? Bool ?? true
        
        // 轉換圖片資料
        guard let image = UIImage(data: imageData.data) else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Cannot create image from data", details: nil))
            return
        }
        
        // 執行 OCR
        recognizeText(
            in: image,
            language: language,
            recognitionLevel: recognitionLevel,
            usesLanguageCorrection: usesLanguageCorrection
        ) { ocrResult in
            result(ocrResult)
        }
    }
    
    /// 執行文字識別
    private func recognizeText(
        in image: UIImage,
        language: String,
        recognitionLevel: String,
        usesLanguageCorrection: Bool,
        completion: @escaping ([String: Any]) -> Void
    ) {
        guard let cgImage = image.cgImage else {
            completion([
                "text": "",
                "textBlocks": [],
                "imageWidth": 0,
                "imageHeight": 0,
                "error": "Cannot get CGImage"
            ])
            return
        }
        
        // 建立 Vision 請求
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion([
                    "text": "",
                    "textBlocks": [],
                    "imageWidth": Int(image.size.width),
                    "imageHeight": Int(image.size.height),
                    "error": error.localizedDescription
                ])
                return
            }
            
            // 處理識別結果
            let results = self.processVisionResults(request.results as? [VNRecognizedTextObservation] ?? [])
            
            completion([
                "text": results.allText,
                "textBlocks": results.textBlocks,
                "imageWidth": Int(image.size.width),
                "imageHeight": Int(image.size.height)
            ])
        }
        
        // 設定識別參數
        if #available(iOS 13.0, *) {
            // 設定識別等級
            switch recognitionLevel {
            case "fast":
                request.recognitionLevel = .fast
            case "accurate":
                request.recognitionLevel = .accurate
            default:
                request.recognitionLevel = .accurate
            }
            
            // 設定語言
            request.recognitionLanguages = [language]
            
            // 設定語言校正
            request.usesLanguageCorrection = usesLanguageCorrection
        }
        
        // 執行請求
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion([
                        "text": "",
                        "textBlocks": [],
                        "imageWidth": Int(image.size.width),
                        "imageHeight": Int(image.size.height),
                        "error": error.localizedDescription
                    ])
                }
            }
        }
    }
    
    /// 處理 Vision 識別結果
    private func processVisionResults(_ observations: [VNRecognizedTextObservation]) -> (allText: String, textBlocks: [[String: Any]]) {
        var allText = ""
        var textBlocks: [[String: Any]] = []
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            let text = topCandidate.string
            allText += text + "\n"
            
            // 轉換邊界框座標（Vision 使用正規化座標）
            let boundingBox = observation.boundingBox
            
            let textBlock: [String: Any] = [
                "text": text,
                "confidence": topCandidate.confidence,
                "language": "auto", // Vision 不直接提供語言檢測
                "boundingBox": [
                    "x": boundingBox.origin.x,
                    "y": 1.0 - boundingBox.origin.y - boundingBox.height, // 轉換座標系統
                    "width": boundingBox.width,
                    "height": boundingBox.height
                ]
            ]
            
            textBlocks.append(textBlock)
        }
        
        // 移除最後的換行符
        if allText.hasSuffix("\n") {
            allText = String(allText.dropLast())
        }
        
        return (allText: allText, textBlocks: textBlocks)
    }
    
    /// 取得可用引擎
    private func handleGetAvailableEngines(_ result: @escaping FlutterResult) {
        let engines: [String: Any] = [
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "Unknown",
            "supportedLanguages": ["zh-Hant", "zh-Hans", "en", "ja", "ko", "fr", "de", "es", "it"],
            "capabilities": ["text_recognition", "text_blocks", "confidence_scores", "bounding_boxes"]
        ]
        
        result(engines)
    }
    
    /// 設定偏好引擎
    private func handleSetPreferredEngine(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Vision Framework 只有一個引擎，直接返回成功
        result(nil)
    }
    
    /// 預處理圖片
    private func handlePreprocessImage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let imageData = args["imageData"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing imageData", details: nil))
            return
        }
        
        // 解析處理選項
        let enhanceContrast = args["enhanceContrast"] as? Bool ?? true
        let removeNoise = args["removeNoise"] as? Bool ?? true
        let normalizeOrientation = args["normalizeOrientation"] as? Bool ?? true
        
        guard let image = UIImage(data: imageData.data) else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Cannot create image from data", details: nil))
            return
        }
        
        // 執行圖片預處理
        let processedImage = preprocessImage(
            image,
            enhanceContrast: enhanceContrast,
            removeNoise: removeNoise,
            normalizeOrientation: normalizeOrientation
        )
        
        // 轉換回資料
        guard let processedData = processedImage.jpegData(compressionQuality: 0.9) else {
            result(FlutterError(code: "PROCESSING_FAILED", message: "Cannot convert processed image to data", details: nil))
            return
        }
        
        result([
            "processedImageData": FlutterStandardTypedData(bytes: processedData)
        ])
    }
    
    /// 圖片預處理
    private func preprocessImage(
        _ image: UIImage,
        enhanceContrast: Bool,
        removeNoise: Bool,
        normalizeOrientation: Bool
    ) -> UIImage {
        var processedImage = image
        
        // 正規化方向
        if normalizeOrientation && image.imageOrientation != .up {
            processedImage = normalizeImageOrientation(processedImage)
        }
        
        // 增強對比度和移除噪點需要使用 Core Image
        if enhanceContrast || removeNoise {
            guard let ciImage = CIImage(image: processedImage) else {
                return processedImage
            }
            
            var filteredImage = ciImage
            
            // 增強對比度
            if enhanceContrast {
                if let contrastFilter = CIFilter(name: "CIColorControls") {
                    contrastFilter.setValue(filteredImage, forKey: kCIInputImageKey)
                    contrastFilter.setValue(1.2, forKey: kCIInputContrastKey) // 增加 20% 對比度
                    
                    if let output = contrastFilter.outputImage {
                        filteredImage = output
                    }
                }
            }
            
            // 移除噪點（使用降噪濾鏡）
            if removeNoise {
                if let noiseFilter = CIFilter(name: "CINoiseReduction") {
                    noiseFilter.setValue(filteredImage, forKey: kCIInputImageKey)
                    noiseFilter.setValue(0.02, forKey: "inputNoiseLevel")
                    noiseFilter.setValue(0.4, forKey: "inputSharpness")
                    
                    if let output = noiseFilter.outputImage {
                        filteredImage = output
                    }
                }
            }
            
            // 轉換回 UIImage
            let context = CIContext()
            if let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) {
                processedImage = UIImage(cgImage: cgImage)
            }
        }
        
        return processedImage
    }
    
    /// 正規化圖片方向
    private func normalizeImageOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
}

/// Flutter Plugin 協議實作擴展
extension VisionService: FlutterPlugin {
    // 空實作，因為我們已經在類別中實作了 register 和 handle 方法
}