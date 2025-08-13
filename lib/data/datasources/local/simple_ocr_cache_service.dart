import 'dart:typed_data';

import 'package:busines_card_scanner_flutter/data/datasources/local/ocr_cache_service.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';
import 'package:crypto/crypto.dart';

/// 簡化的 OCR 快取服務實作
///
/// 提供基本的記憶體快取功能，用於快速解決編譯問題
/// 後續可以替換為完整的 Drift 資料庫實作
class SimpleOCRCacheService implements OCRCacheService {
  // 簡單的記憶體快取
  final Map<String, OCRResult> _memoryCache = {};
  final List<OCRResult> _history = [];

  static const int _maxCacheSize = 100;
  static const int _cacheValidityHours = 24;

  @override
  String getCacheKey(Uint8List imageData) {
    final digest = sha256.convert(imageData);
    return digest.toString();
  }

  @override
  Future<OCRResult> getCachedResult(String cacheKey) async {
    final result = _memoryCache[cacheKey];
    if (result == null) {
      throw Exception('Cache miss');
    }
    return result;
  }

  @override
  bool isCacheValid(OCRResult result) {
    final now = DateTime.now();
    final cacheExpiry = result.processedAt.add(
      const Duration(hours: _cacheValidityHours),
    );
    return now.isBefore(cacheExpiry);
  }

  @override
  Future<void> cacheResult(String cacheKey, OCRResult result) async {
    // 簡單的 LRU 快取實作
    if (_memoryCache.length >= _maxCacheSize) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }

    _memoryCache[cacheKey] = result;
  }

  @override
  Future<OCRResult> saveResult(OCRResult result) async {
    // 生成新的 ID 如果需要
    final savedResult = result.id.isEmpty
        ? result.copyWith(id: 'saved_${DateTime.now().millisecondsSinceEpoch}')
        : result;

    // 加入歷史記錄
    _history.insert(0, savedResult);
    if (_history.length > _maxCacheSize) {
      _history.removeLast();
    }

    return savedResult;
  }

  @override
  Future<List<OCRResult>> getHistory({
    int limit = 50,
    bool includeImages = false,
  }) async {
    final results = _history.take(limit).toList();

    if (!includeImages) {
      // 移除圖片資料以節省記憶體
      return results.map((r) => r.copyWith()).toList();
    }

    return results;
  }

  @override
  Future<OCRResult> getResultById(
    String resultId, {
    bool includeImage = false,
  }) async {
    final result = _history.firstWhere(
      (r) => r.id == resultId,
      orElse: () => throw Exception('Result not found'),
    );

    if (!includeImage) {
      return result.copyWith();
    }

    return result;
  }

  @override
  Future<bool> deleteResult(String resultId) async {
    final index = _history.indexWhere((r) => r.id == resultId);
    if (index >= 0) {
      _history.removeAt(index);

      // 同時從快取中移除
      _memoryCache.removeWhere((key, value) => value.id == resultId);
      return true;
    }
    return false;
  }

  @override
  Future<int> cleanupOldResults({int daysOld = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final oldResults = _history
        .where((r) => r.processedAt.isBefore(cutoffDate))
        .toList();

    for (final result in oldResults) {
      _history.remove(result);
      _memoryCache.removeWhere((key, value) => value.id == result.id);
    }

    return oldResults.length;
  }

  @override
  Future<OCRStatistics> getStatistics() async {
    final totalProcessed = _history.length;
    final averageConfidence = totalProcessed > 0
        ? _history.map((r) => r.confidence).reduce((a, b) => a + b) /
              totalProcessed
        : 0.0;

    final averageProcessingTime = totalProcessed > 0
        ? _history
                  .map((r) => r.processingTimeMs?.toDouble() ?? 0.0)
                  .reduce((a, b) => a + b) /
              totalProcessed
        : 0.0;

    final engineUsage = <String, int>{};
    for (final result in _history) {
      final engine = result.ocrEngine ?? 'unknown';
      engineUsage[engine] = (engineUsage[engine] ?? 0) + 1;
    }

    return OCRStatistics(
      totalProcessed: totalProcessed,
      averageConfidence: averageConfidence,
      averageProcessingTimeMs: averageProcessingTime,
      engineUsage: engineUsage,
      languageConfidence: const {},
      lastUpdated: DateTime.now(),
    );
  }
}
