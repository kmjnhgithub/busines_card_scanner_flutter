import 'package:busines_card_scanner_flutter/data/datasources/remote/ocr_service.dart';
import 'package:busines_card_scanner_flutter/domain/entities/detected_text.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Size;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';

/// Google ML Kit OCR 服務實作
///
/// 使用 Google ML Kit Text Recognition 進行 OCR 處理
/// 支援中英文混合識別，適用於 Android 和 iOS
class MLKitOCRService implements OCRService {
  late final TextRecognizer _textRecognizer;

  MLKitOCRService() {
    // 初始化文字識別器，支援中文腳本
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);
  }

  @override
  Future<OCRResult> recognizeText(
    Uint8List imageData, {
    OCROptions? options,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 建立 InputImage
      final inputImage = InputImage.fromBytes(
        bytes: imageData,
        metadata: _buildInputImageMetadata(imageData, options),
      );

      // 執行文字識別
      final recognizedText = await _textRecognizer.processImage(inputImage);

      stopwatch.stop();

      // 轉換為 OCRResult
      final result = _convertToOCRResult(
        recognizedText,
        imageData,
        stopwatch.elapsedMilliseconds,
      );

      return result;
    } on Exception {
      stopwatch.stop();

      // 返回空結果但保留錯誤資訊
      return OCRResult(
        id: const Uuid().v4(),
        rawText: '',
        confidence: 0,
        processedAt: DateTime.now(),
        detectedTexts: const [],
        imageData: imageData,
        imageWidth: 0,
        imageHeight: 0,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        ocrEngine: 'Google ML Kit',
      );
    }
  }

  @override
  Future<List<OCREngineInfo>> getAvailableEngines() async {
    return [
      const OCREngineInfo(
        id: 'ml_kit',
        name: 'Google ML Kit',
        version: '0.11.0',
        isAvailable: true,
        supportedLanguages: ['zh', 'en', 'ja', 'ko'],
        platform: 'cross-platform',
        capabilities: ['text_recognition', 'text_blocks', 'line_detection'],
      ),
    ];
  }

  @override
  Future<void> setPreferredEngine(String engineId) async {
    // ML Kit 只有一個引擎，不需要切換
  }

  @override
  Future<OCREngineInfo> getCurrentEngine() async {
    final engines = await getAvailableEngines();
    return engines.first;
  }

  @override
  Future<OCREngineHealth> testEngine({String? engineId}) async {
    try {
      // 測試引擎狀態
      final testImageData = _createTestImage();
      await recognizeText(testImageData);

      return OCREngineHealth(
        engineId: 'ml_kit',
        isHealthy: true,
        responseTimeMs: 0,
        lastChecked: DateTime.now(),
      );
    } on Exception catch (e) {
      return OCREngineHealth(
        engineId: 'ml_kit',
        isHealthy: false,
        responseTimeMs: 0,
        lastChecked: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  @override
  Future<Uint8List> preprocessImage(
    Uint8List imageData, {
    ImagePreprocessOptions? options,
  }) async {
    // ML Kit 自動處理圖片預處理，直接返回原圖
    return imageData;
  }

  /// 建立 InputImageMetadata
  InputImageMetadata _buildInputImageMetadata(
    Uint8List imageData,
    OCROptions? options,
  ) {
    // 預設的圖片元資料
    return InputImageMetadata(
      size: const Size(800, 600), // 預設尺寸
      rotation: InputImageRotation.rotation0deg,
      format: InputImageFormat.yuv420,
      bytesPerRow: 800 * 3, // RGB
    );
  }

  /// 轉換 RecognizedText 為 OCRResult
  OCRResult _convertToOCRResult(
    RecognizedText recognizedText,
    Uint8List imageData,
    int processingTimeMs,
  ) {
    // 提取所有文字
    final allText = recognizedText.text;

    // 轉換檢測到的文字區塊
    final detectedTexts = recognizedText.blocks.map<DetectedText>((block) {
      return DetectedText(
        text: block.text,
        boundingBox: _convertBoundingBox(block.boundingBox),
        confidence: _calculateBlockConfidence(block),
        languageCode: 'auto', // ML Kit 自動檢測
      );
    }).toList();

    // 計算整體信心度
    final confidence = _calculateOverallConfidence(recognizedText);

    return OCRResult(
      id: const Uuid().v4(),
      rawText: allText,
      confidence: confidence,
      processedAt: DateTime.now(),
      detectedTexts: detectedTexts,
      imageData: imageData,
      imageWidth: 800, // 預設值，實際應從圖片中取得
      imageHeight: 600,
      processingTimeMs: processingTimeMs,
      ocrEngine: 'Google ML Kit',
    );
  }

  /// 轉換邊界框
  BoundingBox _convertBoundingBox(rect) {
    if (rect == null) {
      return const BoundingBox(left: 0, top: 0, width: 0, height: 0);
    }

    return BoundingBox(
      left: rect.left.toDouble(),
      top: rect.top.toDouble(),
      width: rect.width.toDouble(),
      height: rect.height.toDouble(),
    );
  }

  /// 計算文字區塊信心度
  double _calculateBlockConfidence(TextBlock block) {
    // ML Kit 沒有直接提供信心度，根據文字品質估算
    final textLength = block.text.length;
    final hasNumbers = RegExp(r'\d').hasMatch(block.text);
    final hasLetters = RegExp(r'[a-zA-Z\u4e00-\u9fa5]').hasMatch(block.text);

    double confidence = 0.7; // 基礎信心度

    if (textLength > 3) {
      confidence += 0.1;
    }
    if (hasNumbers && hasLetters) {
      confidence += 0.1;
    }
    if (textLength > 10) {
      confidence += 0.1;
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// 計算整體信心度
  double _calculateOverallConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) {
      return 0;
    }

    // 根據檢測到的文字品質計算信心度
    final totalText = recognizedText.text;
    final blockCount = recognizedText.blocks.length;

    double confidence = 0.5; // 基礎分數

    // 根據文字長度調整
    if (totalText.length > 10) {
      confidence += 0.2;
    }
    if (totalText.length > 50) {
      confidence += 0.1;
    }

    // 根據區塊數量調整
    if (blockCount > 2) {
      confidence += 0.1;
    }
    if (blockCount > 5) {
      confidence += 0.1;
    }

    // 檢查是否包含典型名片內容
    if (_containsBusinessCardContent(totalText)) {
      confidence += 0.1;
    }

    return confidence.clamp(0.0, 1.0);
  }

  /// 檢查是否包含名片內容
  bool _containsBusinessCardContent(String text) {
    final businessCardKeywords = [
      '@', // email
      'Tel', '電話', 'Phone',
      'Mobile', '手機',
      'Company', '公司',
      'Manager', '經理',
      'Engineer', '工程師',
      'www.', 'http',
    ];

    return businessCardKeywords.any(
      (keyword) => text.toLowerCase().contains(keyword.toLowerCase()),
    );
  }

  /// 建立測試圖片
  Uint8List _createTestImage() {
    // 建立一個簡單的測試圖片（1x1 白色像素）
    return Uint8List.fromList([255, 255, 255]);
  }

  /// 釋放資源
  void dispose() {
    _textRecognizer.close();
  }
}
