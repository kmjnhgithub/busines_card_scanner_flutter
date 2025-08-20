import 'dart:io';

import 'package:busines_card_scanner_flutter/data/datasources/remote/ocr_service.dart';
import 'package:busines_card_scanner_flutter/domain/entities/detected_text.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

/// iOS Vision Framework OCR 服務實作
///
/// 透過 Platform Channel 呼叫 iOS 原生 Vision Framework
/// 僅在 iOS 平台可用，提供高精度的文字識別
class IOSVisionServiceBridge implements OCRService {
  static const MethodChannel _channel = MethodChannel('com.app.scanner/vision');

  @override
  Future<OCRResult> recognizeText(
    Uint8List imageData, {
    OCROptions? options,
  }) async {
    // 檢查平台
    if (!Platform.isIOS) {
      throw UnsupportedError(
        'iOS Vision Framework only available on iOS platform',
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('IOSVisionServiceBridge: 開始 iOS Vision OCR 處理');

      // 呼叫 iOS 原生方法
      final result = await _channel.invokeMethod('recognizeText', {
        'imageData': imageData,
        'language': options?.language ?? 'zh-Hant', // 繁體中文
        'recognitionLevel': options?.recognitionLevel ?? 'accurate',
        'usesLanguageCorrection': options?.usesLanguageCorrection ?? true,
      });

      stopwatch.stop();

      // 解析原生回應
      final ocrResult = _parseNativeResponse(
        result,
        imageData,
        stopwatch.elapsedMilliseconds,
      );

      debugPrint('IOSVisionServiceBridge: OCR 完成，信心度: ${ocrResult.confidence}');
      debugPrint('IOSVisionServiceBridge: 識別文字: ${ocrResult.rawText}');

      return ocrResult;
    } on PlatformException catch (e) {
      stopwatch.stop();
      debugPrint('IOSVisionServiceBridge: Platform Exception: ${e.message}');

      // 返回失敗結果
      return _createFailedResult(
        imageData,
        stopwatch.elapsedMilliseconds,
        e.message,
      );
    } on Exception catch (e) {
      stopwatch.stop();
      debugPrint('IOSVisionServiceBridge: Exception: $e');

      // 返回失敗結果
      return _createFailedResult(
        imageData,
        stopwatch.elapsedMilliseconds,
        e.toString(),
      );
    }
  }

  @override
  Future<List<OCREngineInfo>> getAvailableEngines() async {
    if (!Platform.isIOS) {
      return [];
    }

    try {
      final engines = await _channel.invokeMethod('getAvailableEngines');

      return [
        OCREngineInfo(
          id: 'ios_vision',
          name: 'iOS Vision Framework',
          version: engines['version'] ?? 'Unknown',
          isAvailable: true,
          supportedLanguages: List<String>.from(
            engines['supportedLanguages'] ?? ['zh-Hant', 'en'],
          ),
          platform: 'ios',
          capabilities: List<String>.from(
            engines['capabilities'] ?? ['text_recognition', 'text_blocks'],
          ),
        ),
      ];
    } on Exception catch (e) {
      debugPrint('IOSVisionServiceBridge: 取得引擎資訊失敗: $e');
      return [];
    }
  }

  @override
  Future<void> setPreferredEngine(String engineId) async {
    if (!Platform.isIOS) {
      return;
    }

    try {
      await _channel.invokeMethod('setPreferredEngine', {'engineId': engineId});
      debugPrint('IOSVisionServiceBridge: 引擎設定為 $engineId');
    } on Exception catch (e) {
      debugPrint('IOSVisionServiceBridge: 設定引擎失敗: $e');
    }
  }

  @override
  Future<OCREngineInfo> getCurrentEngine() async {
    final engines = await getAvailableEngines();
    return engines.isNotEmpty
        ? engines.first
        : const OCREngineInfo(
            id: 'ios_vision',
            name: 'iOS Vision Framework',
            version: 'Unknown',
            isAvailable: false,
            supportedLanguages: [],
            platform: 'ios',
            capabilities: [],
          );
  }

  @override
  Future<OCREngineHealth> testEngine({String? engineId}) async {
    if (!Platform.isIOS) {
      return OCREngineHealth(
        engineId: 'ios_vision',
        isHealthy: false,
        responseTimeMs: 0,
        lastChecked: DateTime.now(),
        error: 'Not available on non-iOS platforms',
      );
    }

    try {
      final startTime = DateTime.now();

      // 建立測試圖片
      final testImageData = _createTestImage();
      await recognizeText(testImageData);

      final endTime = DateTime.now();
      final responseTime = endTime
          .difference(startTime)
          .inMilliseconds
          .toDouble();

      return OCREngineHealth(
        engineId: 'ios_vision',
        isHealthy: true,
        responseTimeMs: responseTime,
        lastChecked: endTime,
      );
    } on Exception catch (e) {
      return OCREngineHealth(
        engineId: 'ios_vision',
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
    if (!Platform.isIOS) {
      return imageData;
    }

    try {
      debugPrint('IOSVisionServiceBridge: 預處理圖片');

      final result = await _channel.invokeMethod('preprocessImage', {
        'imageData': imageData,
        'enhanceContrast': options?.enhanceContrast ?? true,
        'removeNoise': options?.removeNoise ?? true,
        'normalizeOrientation': options?.normalizeOrientation ?? true,
      });

      return Uint8List.fromList(List<int>.from(result['processedImageData']));
    } on Exception catch (e) {
      debugPrint('IOSVisionServiceBridge: 圖片預處理失敗: $e');
      return imageData; // 返回原圖
    }
  }

  /// 解析原生回應
  OCRResult _parseNativeResponse(
    result,
    Uint8List imageData,
    int processingTimeMs,
  ) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(result);

    // 提取文字內容
    final rawText = data['text'] as String? ?? '';

    // 提取檢測到的文字區塊
    final blocksData = data['textBlocks'] as List? ?? [];
    final detectedTexts = blocksData.map<DetectedText>((blockData) {
      final block = Map<String, dynamic>.from(blockData);
      return DetectedText(
        text: block['text'] as String? ?? '',
        boundingBox: _parseBoundingBox(block['boundingBox']),
        confidence: (block['confidence'] as num?)?.toDouble() ?? 0.0,
        languageCode: block['language'] as String? ?? 'auto',
      );
    }).toList();

    // 計算整體信心度
    final confidence = _calculateOverallConfidence(detectedTexts, rawText);

    return OCRResult(
      id: const Uuid().v4(),
      rawText: rawText,
      confidence: confidence,
      processedAt: DateTime.now(),
      detectedTexts: detectedTexts,
      imageData: imageData,
      imageWidth: (data['imageWidth'] as num?)?.toInt() ?? 0,
      imageHeight: (data['imageHeight'] as num?)?.toInt() ?? 0,
      processingTimeMs: processingTimeMs,
      ocrEngine: 'iOS Vision Framework',
    );
  }

  /// 解析邊界框
  BoundingBox _parseBoundingBox(boundingBoxData) {
    if (boundingBoxData == null) {
      return const BoundingBox(left: 0, top: 0, width: 0, height: 0);
    }

    final box = Map<String, dynamic>.from(boundingBoxData);
    return BoundingBox(
      left: (box['x'] as num?)?.toDouble() ?? 0.0,
      top: (box['y'] as num?)?.toDouble() ?? 0.0,
      width: (box['width'] as num?)?.toDouble() ?? 0.0,
      height: (box['height'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 計算整體信心度
  double _calculateOverallConfidence(
    List<DetectedText> detectedTexts,
    String rawText,
  ) {
    if (detectedTexts.isEmpty || rawText.isEmpty) {
      return 0;
    }

    // 根據檢測區塊的平均信心度
    double totalConfidence = 0;
    for (final text in detectedTexts) {
      totalConfidence += text.confidence;
    }

    double avgConfidence = totalConfidence / detectedTexts.length;

    // 根據文字品質調整
    if (rawText.length > 10) {
      avgConfidence += 0.1;
    }
    if (rawText.length > 50) {
      avgConfidence += 0.1;
    }
    if (_containsBusinessCardContent(rawText)) {
      avgConfidence += 0.1;
    }

    return avgConfidence.clamp(0.0, 1.0);
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

  /// 建立失敗結果
  OCRResult _createFailedResult(
    Uint8List imageData,
    int processingTimeMs,
    String? errorMessage,
  ) {
    return OCRResult(
      id: const Uuid().v4(),
      rawText: '',
      confidence: 0,
      processedAt: DateTime.now(),
      detectedTexts: const [],
      imageData: imageData,
      imageWidth: 0,
      imageHeight: 0,
      processingTimeMs: processingTimeMs,
      ocrEngine:
          'iOS Vision Framework (Failed: ${errorMessage ?? 'Unknown error'})',
    );
  }

  /// 建立測試圖片
  Uint8List _createTestImage() {
    // 建立一個簡單的測試圖片（1x1 白色像素）
    return Uint8List.fromList([255, 255, 255]);
  }
}
