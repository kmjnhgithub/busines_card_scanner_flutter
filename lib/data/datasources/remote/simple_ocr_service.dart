import 'dart:typed_data';

import 'package:busines_card_scanner_flutter/data/datasources/remote/ocr_service.dart';
import 'package:busines_card_scanner_flutter/domain/entities/detected_text.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';

/// 簡化的 OCR 服務實作
///
/// 提供基本的 OCR 功能，用於快速解決編譯問題
/// 後續可以替換為完整的 Google ML Kit 實作
class SimpleOCRService implements OCRService {
  static const String _engineId = 'simple_ocr';
  static const String _engineName = 'Simple OCR Service';
  static const String _engineVersion = '1.0.0';

  @override
  Future<OCRResult> recognizeText(
    Uint8List imageData, {
    OCROptions? options,
  }) async {
    // 簡單的模擬實作 - 返回固定結果
    await Future.delayed(const Duration(milliseconds: 500));

    // 基本的圖片驗證
    if (imageData.isEmpty) {
      throw const UnsupportedImageFormatFailure(userMessage: '圖片資料無效');
    }

    if (imageData.length > 10 * 1024 * 1024) {
      // 10MB limit
      throw const ImageTooLargeFailure(
        imageSize: 0,
        maxSize: 10 * 1024 * 1024,
        userMessage: '圖片檔案過大，請使用較小的圖片',
      );
    }

    return OCRResult(
      id: 'simple_ocr_${DateTime.now().millisecondsSinceEpoch}',
      rawText: '張三\nABC科技公司\n產品經理\n02-1234-5678\nemail@example.com',
      detectedTexts: const [
        DetectedText(
          text: '張三',
          confidence: 0.9,
          boundingBox: BoundingBox(left: 10, top: 10, width: 100, height: 30),
        ),
        DetectedText(
          text: 'ABC科技公司',
          confidence: 0.85,
          boundingBox: BoundingBox(left: 10, top: 50, width: 150, height: 25),
        ),
        DetectedText(
          text: '產品經理',
          confidence: 0.8,
          boundingBox: BoundingBox(left: 10, top: 80, width: 80, height: 20),
        ),
        DetectedText(
          text: '02-1234-5678',
          confidence: 0.9,
          boundingBox: BoundingBox(left: 10, top: 110, width: 120, height: 20),
        ),
        DetectedText(
          text: 'email@example.com',
          confidence: 0.85,
          boundingBox: BoundingBox(left: 10, top: 140, width: 160, height: 20),
        ),
      ],
      confidence: 0.85,
      imageData: imageData,
      imageWidth: 800,
      imageHeight: 600,
      processedAt: DateTime.now(),
      processingTimeMs: 500,
      ocrEngine: _engineId,
    );
  }

  @override
  Future<List<OCREngineInfo>> getAvailableEngines() async {
    return [
      const OCREngineInfo(
        id: _engineId,
        name: _engineName,
        version: _engineVersion,
        supportedLanguages: ['zh-Hant', 'en'],
        isAvailable: true,
        platform: 'cross-platform',
        capabilities: ['basic_text_recognition'],
      ),
    ];
  }

  @override
  Future<void> setPreferredEngine(String engineId) async {
    // Stub implementation
  }

  @override
  Future<OCREngineInfo> getCurrentEngine() async {
    return const OCREngineInfo(
      id: _engineId,
      name: _engineName,
      version: _engineVersion,
      supportedLanguages: ['zh-Hant', 'en'],
      isAvailable: true,
      platform: 'cross-platform',
      capabilities: ['basic_text_recognition'],
    );
  }

  @override
  Future<OCREngineHealth> testEngine({String? engineId}) async {
    return OCREngineHealth(
      engineId: engineId ?? _engineId,
      isHealthy: true,
      responseTimeMs: 100,
      lastChecked: DateTime.now(),
    );
  }

  @override
  Future<Uint8List> preprocessImage(
    Uint8List imageData, {
    ImagePreprocessOptions? options,
  }) async {
    // 返回原始圖片 - 不做預處理
    return imageData;
  }
}
