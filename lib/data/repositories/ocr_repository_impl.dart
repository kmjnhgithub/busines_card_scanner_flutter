import 'dart:typed_data';

import 'package:busines_card_scanner_flutter/data/datasources/local/ocr_cache_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/ocr_service.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';

/// OCRRepository 的實作
///
/// 遵循 Clean Architecture 原則：
/// - 實作 Domain 層定義的 OCRRepository 介面
/// - 依賴抽象的 DataSource 介面（OCRService、OCRCacheService）
/// - 負責協調 OCR 服務和快取服務
/// - 實作智慧快取策略和錯誤處理
class OCRRepositoryImpl implements OCRRepository {
  final OCRService ocrService;
  final OCRCacheService cacheService;

  const OCRRepositoryImpl({
    required this.ocrService,
    required this.cacheService,
  });

  @override
  Future<OCRResult> recognizeText(
    Uint8List imageData, {
    OCROptions? options,
  }) async {
    // 嘗試從快取取得結果
    final cacheKey = cacheService.getCacheKey(imageData);

    try {
      final cachedResult = await cacheService.getCachedResult(cacheKey);
      if (cacheService.isCacheValid(cachedResult)) {
        return cachedResult;
      }
    } on Exception {
      // 快取中沒有結果或取得失敗，繼續使用 OCR 服務
    }

    // 使用 OCR 服務處理
    final result = await ocrService.recognizeText(imageData, options: options);

    // 將結果存入快取
    try {
      await cacheService.cacheResult(cacheKey, result);
    } on Exception {
      // 快取儲存失敗不影響主要功能
    }

    return result;
  }

  @override
  Future<BatchOCRResult> recognizeTexts(
    List<Uint8List> imageDataList, {
    OCROptions? options,
  }) async {
    if (imageDataList.isEmpty) {
      return const BatchOCRResult(successful: [], failed: []);
    }

    final successful = <OCRResult>[];
    final failed = <BatchOCRError>[];

    for (int i = 0; i < imageDataList.length; i++) {
      try {
        final result = await recognizeText(imageDataList[i], options: options);
        successful.add(result);
      } on Exception catch (error) {
        failed.add(
          BatchOCRError(
            index: i,
            error: error.toString(),
            originalImageData: imageDataList[i],
          ),
        );
      }
    }

    return BatchOCRResult(successful: successful, failed: failed);
  }

  @override
  Future<OCRResult> saveOCRResult(OCRResult result) async {
    return cacheService.saveResult(result);
  }

  @override
  Future<List<OCRResult>> getOCRHistory({
    int limit = 50,
    bool includeImages = false,
  }) async {
    return cacheService.getHistory(limit: limit, includeImages: includeImages);
  }

  @override
  Future<OCRResult> getOCRResultById(
    String resultId, {
    bool includeImage = false,
  }) async {
    return cacheService.getResultById(resultId, includeImage: includeImage);
  }

  @override
  Future<bool> deleteOCRResult(String resultId) async {
    return cacheService.deleteResult(resultId);
  }

  @override
  Future<int> cleanupOldResults({int daysOld = 30}) async {
    return cacheService.cleanupOldResults(daysOld: daysOld);
  }

  @override
  Future<List<OCREngineInfo>> getAvailableEngines() async {
    return ocrService.getAvailableEngines();
  }

  @override
  Future<void> setPreferredEngine(String engineId) async {
    await ocrService.setPreferredEngine(engineId);
  }

  @override
  Future<OCREngineInfo> getCurrentEngine() async {
    return ocrService.getCurrentEngine();
  }

  @override
  Future<OCREngineHealth> testEngine({String? engineId}) async {
    return ocrService.testEngine(engineId: engineId);
  }

  @override
  Future<Uint8List> preprocessImage(
    Uint8List imageData, {
    ImagePreprocessOptions? options,
  }) async {
    return ocrService.preprocessImage(imageData, options: options);
  }

  @override
  Future<OCRStatistics> getStatistics() async {
    return cacheService.getStatistics();
  }
}
