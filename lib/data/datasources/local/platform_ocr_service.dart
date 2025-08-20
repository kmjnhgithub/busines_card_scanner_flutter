import 'dart:io';

import 'package:busines_card_scanner_flutter/data/datasources/local/ml_kit_ocr_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/ocr_service.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';
import 'package:busines_card_scanner_flutter/platform/ios/vision_service_bridge.dart';
import 'package:flutter/foundation.dart';

/// 平台特定 OCR 服務選擇器
///
/// 根據運行平台自動選擇最佳的 OCR 引擎：
/// - iOS: 使用 iOS Vision Framework（原生效能最佳）
/// - Android: 使用 Google ML Kit（跨平台相容性佳）
/// - 其他平台: 使用 Google ML Kit 作為 fallback
class PlatformOCRService implements OCRService {
  late final OCRService _activeService;
  late final String _platformName;

  PlatformOCRService() {
    _initializePlatformService();
  }

  /// 初始化平台特定服務
  void _initializePlatformService() {
    if (Platform.isIOS) {
      _activeService = IOSVisionServiceBridge();
      _platformName = 'iOS Vision Framework';
      debugPrint('PlatformOCRService: 已選擇 iOS Vision Framework');
    } else {
      _activeService = MLKitOCRService();
      _platformName = Platform.isAndroid
          ? 'Android ML Kit'
          : 'Cross-platform ML Kit';
      debugPrint(
        'PlatformOCRService: 已選擇 Google ML Kit (${Platform.operatingSystem})',
      );
    }
  }

  @override
  Future<OCRResult> recognizeText(
    Uint8List imageData, {
    OCROptions? options,
  }) async {
    debugPrint('PlatformOCRService: 開始 OCR 處理 ($_platformName)');

    try {
      final result = await _activeService.recognizeText(
        imageData,
        options: options,
      );

      // 在結果中加入平台資訊
      final updatedResult = OCRResult(
        id: result.id,
        rawText: result.rawText,
        confidence: result.confidence,
        processedAt: result.processedAt,
        detectedTexts: result.detectedTexts,
        imageData: result.imageData,
        imageWidth: result.imageWidth,
        imageHeight: result.imageHeight,
        processingTimeMs: result.processingTimeMs,
        ocrEngine: '$_platformName (${result.ocrEngine})',
      );

      debugPrint(
        'PlatformOCRService: OCR 完成 ($_platformName) - 信心度: ${result.confidence}',
      );
      return updatedResult;
    } on Exception catch (e) {
      debugPrint('PlatformOCRService: OCR 處理失敗 ($_platformName): $e');

      // 如果是 iOS 服務失敗，可以考慮 fallback 到 ML Kit
      if (Platform.isIOS && _activeService is IOSVisionServiceBridge) {
        debugPrint('PlatformOCRService: iOS Vision 失敗，嘗試 fallback 到 ML Kit');
        try {
          final fallbackService = MLKitOCRService();
          final result = await fallbackService.recognizeText(
            imageData,
            options: options,
          );

          // 標記為 fallback 結果
          return OCRResult(
            id: result.id,
            rawText: result.rawText,
            confidence: result.confidence * 0.9, // 降低信心度表示是 fallback
            processedAt: result.processedAt,
            detectedTexts: result.detectedTexts,
            imageData: result.imageData,
            imageWidth: result.imageWidth,
            imageHeight: result.imageHeight,
            processingTimeMs: result.processingTimeMs,
            ocrEngine: 'ML Kit (iOS Vision Fallback)',
          );
        } on Exception catch (fallbackError) {
          debugPrint('PlatformOCRService: Fallback 也失敗: $fallbackError');
          rethrow;
        }
      }

      rethrow;
    }
  }

  @override
  Future<List<OCREngineInfo>> getAvailableEngines() async {
    final engines = await _activeService.getAvailableEngines();

    // 如果是 iOS，也添加 ML Kit 作為可用選項
    if (Platform.isIOS) {
      final mlKitService = MLKitOCRService();
      final mlKitEngines = await mlKitService.getAvailableEngines();
      engines.addAll(mlKitEngines);
    }

    return engines;
  }

  @override
  Future<void> setPreferredEngine(String engineId) async {
    debugPrint('PlatformOCRService: 設定偏好引擎 - $engineId');

    // 如果在 iOS 上要切換到 ML Kit
    if (Platform.isIOS && engineId == 'ml_kit') {
      _activeService = MLKitOCRService();
      _platformName = 'ML Kit (iOS)';
      debugPrint('PlatformOCRService: 已切換到 ML Kit');
      return;
    }

    // 如果在 iOS 上要切換回 Vision Framework
    if (Platform.isIOS && engineId == 'ios_vision') {
      _activeService = IOSVisionServiceBridge();
      _platformName = 'iOS Vision Framework';
      debugPrint('PlatformOCRService: 已切換到 iOS Vision Framework');
      return;
    }

    // 其他情況委派給當前服務
    await _activeService.setPreferredEngine(engineId);
  }

  @override
  Future<OCREngineInfo> getCurrentEngine() async {
    final engineInfo = await _activeService.getCurrentEngine();

    // 添加平台資訊
    return OCREngineInfo(
      id: engineInfo.id,
      name: '$_platformName - ${engineInfo.name}',
      version: engineInfo.version,
      isAvailable: engineInfo.isAvailable,
      supportedLanguages: engineInfo.supportedLanguages,
      platform: engineInfo.platform,
      capabilities: engineInfo.capabilities,
    );
  }

  @override
  Future<OCREngineHealth> testEngine({String? engineId}) async {
    debugPrint('PlatformOCRService: 測試引擎健康狀態 ($_platformName)');

    final health = await _activeService.testEngine(engineId: engineId);

    // 如果當前引擎不健康且在 iOS 上，測試 fallback 選項
    if (!health.isHealthy &&
        Platform.isIOS &&
        _activeService is IOSVisionServiceBridge) {
      debugPrint('PlatformOCRService: 當前引擎不健康，測試 ML Kit fallback');
      try {
        final fallbackService = MLKitOCRService();
        final fallbackHealth = await fallbackService.testEngine();

        if (fallbackHealth.isHealthy) {
          return OCREngineHealth(
            engineId: 'ml_kit_fallback',
            isHealthy: true,
            responseTimeMs: fallbackHealth.responseTimeMs,
            lastChecked: DateTime.now(),
            error: 'Primary engine failed, fallback available',
          );
        }
      } on Exception catch (e) {
        debugPrint('PlatformOCRService: Fallback 引擎測試失敗: $e');
      }
    }

    return health;
  }

  @override
  Future<Uint8List> preprocessImage(
    Uint8List imageData, {
    ImagePreprocessOptions? options,
  }) async {
    debugPrint('PlatformOCRService: 圖片預處理 ($_platformName)');
    return _activeService.preprocessImage(imageData, options: options);
  }

  /// 取得當前平台名稱
  String get platformName => _platformName;

  /// 取得當前使用的服務類型
  String get activeServiceType {
    if (_activeService is IOSVisionServiceBridge) {
      return 'ios_vision';
    } else if (_activeService is MLKitOCRService) {
      return 'ml_kit';
    } else {
      return 'unknown';
    }
  }

  /// 檢查是否支援 fallback
  bool get supportsFallback => Platform.isIOS;

  /// 手動觸發 fallback（僅限 iOS）
  Future<void> switchToFallback() async {
    if (!Platform.isIOS) {
      throw UnsupportedError('Fallback only supported on iOS');
    }

    if (_activeService is IOSVisionServiceBridge) {
      debugPrint('PlatformOCRService: 手動切換到 ML Kit fallback');
      _activeService = MLKitOCRService();
      _platformName = 'ML Kit (Manual Fallback)';
    }
  }

  /// 重設為預設服務
  Future<void> resetToDefault() async {
    debugPrint('PlatformOCRService: 重設為預設服務');
    _initializePlatformService();
  }

  /// 釋放資源
  void dispose() {
    debugPrint('PlatformOCRService: 釋放資源 ($_platformName)');

    // 如果當前服務有 dispose 方法則呼叫
    if (_activeService is MLKitOCRService) {
      _activeService.dispose();
    }
  }
}
