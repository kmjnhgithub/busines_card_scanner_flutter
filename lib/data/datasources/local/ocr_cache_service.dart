import 'dart:typed_data';

import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';

/// OCR 結果快取服務抽象類別
///
/// 負責 OCR 結果的本地儲存、快取管理和歷史記錄：
/// - OCR 結果的儲存和檢索
/// - 快取有效性驗證
/// - 歷史記錄管理
/// - 統計資訊追蹤
///
/// 遵循依賴反轉原則，Repository 依賴此抽象介面而非具體實作
abstract class OCRCacheService {
  /// 產生圖片的快取鍵值
  ///
  /// [imageData] 圖片資料
  ///
  /// 回傳用於快取查詢的唯一鍵值（通常基於圖片雜湊）
  String getCacheKey(Uint8List imageData);

  /// 從快取中取得 OCR 結果
  ///
  /// [cacheKey] 快取鍵值
  ///
  /// 回傳快取的 OCR 結果，如果不存在則拋出例外
  Future<OCRResult> getCachedResult(String cacheKey);

  /// 檢查快取結果是否有效
  ///
  /// [result] 要檢查的 OCR 結果
  ///
  /// 回傳 true 如果快取仍然有效（未過期且資料完整）
  bool isCacheValid(OCRResult result);

  /// 將 OCR 結果存入快取
  ///
  /// [cacheKey] 快取鍵值
  /// [result] 要快取的 OCR 結果
  Future<void> cacheResult(String cacheKey, OCRResult result);

  /// 儲存 OCR 結果到持久儲存
  ///
  /// [result] 要儲存的 OCR 結果
  ///
  /// 回傳儲存後的結果（包含分配的 ID）
  Future<OCRResult> saveResult(OCRResult result);

  /// 取得 OCR 處理歷史
  ///
  /// [limit] 限制回傳的結果數量
  /// [includeImages] 是否包含原始圖片資料
  ///
  /// 回傳按處理時間降序排列的 OCR 結果列表
  Future<List<OCRResult>> getHistory({
    int limit = 50,
    bool includeImages = false,
  });

  /// 根據 ID 取得 OCR 結果
  ///
  /// [resultId] OCR 結果的唯一識別碼
  /// [includeImage] 是否包含原始圖片資料
  Future<OCRResult> getResultById(String resultId, {bool includeImage = false});

  /// 刪除 OCR 結果
  ///
  /// [resultId] 要刪除的 OCR 結果 ID
  ///
  /// 回傳 true 如果刪除成功
  Future<bool> deleteResult(String resultId);

  /// 清理舊的 OCR 結果
  ///
  /// [daysOld] 保留最近幾天的結果
  ///
  /// 回傳被清理的結果數量
  Future<int> cleanupOldResults({int daysOld = 30});

  /// 取得 OCR 統計資訊
  ///
  /// 回傳 OCR 使用統計，包含處理次數、平均準確度、效能指標等
  Future<OCRStatistics> getStatistics();
}
