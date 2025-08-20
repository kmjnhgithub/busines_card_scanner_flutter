import 'dart:typed_data';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';

/// OCR 處理 Repository 介面
///
/// 負責管理 OCR（光學字符識別）相關的操作，包括：
/// - 圖片文字識別
/// - OCR 結果儲存和檢索
/// - OCR 引擎管理和切換
/// - 識別歷史記錄管理
///
/// 支援多種 OCR 引擎的漸進式遷移策略：
/// - Phase 1-2: iOS 使用 Vision Framework，Android 使用 Google ML Kit
/// - Phase 3+: 統一使用 Google ML Kit 純 Flutter 實作
abstract class OCRRepository {
  /// 執行圖片文字識別
  ///
  /// [imageData] 要識別的圖片資料（支援 JPG、PNG 格式）
  /// [options] 可選的識別選項配置
  ///
  /// 回傳 OCR 識別結果，包含識別文字、信心度、處理時間等資訊
  ///
  /// Throws:
  /// - [OCRProcessingFailure] 當 OCR 引擎處理失敗
  /// - [UnsupportedImageFormatFailure] 當圖片格式不支援
  /// - [ImageTooLargeFailure] 當圖片尺寸超過限制
  /// - [OCRServiceUnavailableFailure] 當 OCR 服務無法使用
  Future<OCRResult> recognizeText(Uint8List imageData, {OCROptions? options});

  /// 批次處理多張圖片
  ///
  /// [imageDataList] 要處理的圖片資料列表
  /// [options] 可選的識別選項配置
  ///
  /// 回傳批次處理結果，包含成功和失敗的項目
  Future<BatchOCRResult> recognizeTexts(
    List<Uint8List> imageDataList, {
    OCROptions? options,
  });

  /// 儲存 OCR 結果
  ///
  /// [result] 要儲存的 OCR 結果
  ///
  /// 回傳儲存後的結果（包含分配的 ID）
  Future<OCRResult> saveOCRResult(OCRResult result);

  /// 取得 OCR 處理歷史
  ///
  /// [limit] 限制回傳的結果數量，預設為 50
  /// [includeImages] 是否包含原始圖片資料，預設為 false
  ///
  /// 回傳按處理時間降序排列的 OCR 結果列表
  Future<List<OCRResult>> getOCRHistory({
    int limit = 50,
    bool includeImages = false,
  });

  /// 根據 ID 取得 OCR 結果
  ///
  /// [resultId] OCR 結果的唯一識別碼
  /// [includeImage] 是否包含原始圖片資料，預設為 false
  ///
  /// Throws:
  /// - [OCRResultNotFoundException] 當指定的結果不存在
  Future<OCRResult> getOCRResultById(
    String resultId, {
    bool includeImage = false,
  });

  /// 刪除 OCR 結果
  ///
  /// [resultId] 要刪除的 OCR 結果 ID
  ///
  /// 回傳 true 如果刪除成功
  Future<bool> deleteOCRResult(String resultId);

  /// 清理舊的 OCR 結果
  ///
  /// [daysOld] 保留最近幾天的結果，預設為 30 天
  ///
  /// 回傳被清理的結果數量
  Future<int> cleanupOldResults({int daysOld = 30});

  /// 取得可用的 OCR 引擎列表
  ///
  /// 回傳當前平台可用的 OCR 引擎資訊
  Future<List<OCREngineInfo>> getAvailableEngines();

  /// 設定偏好的 OCR 引擎
  ///
  /// [engineId] OCR 引擎的識別碼
  ///
  /// 設定後續的 OCR 操作會優先使用指定引擎
  Future<void> setPreferredEngine(String engineId);

  /// 取得當前使用的 OCR 引擎
  Future<OCREngineInfo> getCurrentEngine();

  /// 測試 OCR 引擎狀態
  ///
  /// [engineId] 可選的引擎 ID，如果不提供則測試當前引擎
  ///
  /// 回傳引擎健康狀態資訊
  Future<OCREngineHealth> testEngine({String? engineId});

  /// 預處理圖片以提升 OCR 準確度
  ///
  /// [imageData] 原始圖片資料
  /// [options] 預處理選項
  ///
  /// 回傳優化後的圖片資料
  Future<Uint8List> preprocessImage(
    Uint8List imageData, {
    ImagePreprocessOptions? options,
  });

  /// 取得 OCR 統計資訊
  ///
  /// 回傳 OCR 使用統計，包含處理次數、平均準確度、效能指標等
  Future<OCRStatistics> getStatistics();
}

/// OCR 識別選項配置
class OCROptions {
  /// 是否啟用文字區塊偵測
  final bool enableTextBlocks;

  /// 期望的語言代碼（如：'zh-Hant', 'en', 'ja'）
  final List<String>? preferredLanguages;

  /// 是否預處理圖片
  final bool enablePreprocessing;

  /// 圖片旋轉校正
  final bool enableRotationCorrection;

  /// 最大處理時間（毫秒）
  final int? maxProcessingTimeMs;

  /// 是否儲存處理結果
  final bool saveResult;

  /// 主要語言代碼（用於單一語言識別）
  final String? language;

  /// 識別精度等級（'fast', 'accurate'）
  final String? recognitionLevel;

  /// 是否使用語言修正
  final bool? usesLanguageCorrection;

  const OCROptions({
    this.enableTextBlocks = true,
    this.preferredLanguages,
    this.enablePreprocessing = true,
    this.enableRotationCorrection = true,
    this.maxProcessingTimeMs,
    this.saveResult = false,
    this.language,
    this.recognitionLevel,
    this.usesLanguageCorrection,
  });
}

/// 批次 OCR 處理結果
class BatchOCRResult {
  final List<OCRResult> successful;
  final List<BatchOCRError> failed;

  const BatchOCRResult({required this.successful, required this.failed});

  bool get hasFailures => failed.isNotEmpty;
  int get successCount => successful.length;
  int get failureCount => failed.length;
  double get successRate =>
      successful.length / (successful.length + failed.length);
}

/// 批次 OCR 錯誤
class BatchOCRError {
  final int index;
  final String error;
  final Uint8List? originalImageData;

  const BatchOCRError({
    required this.index,
    required this.error,
    this.originalImageData,
  });
}

/// OCR 引擎資訊
class OCREngineInfo {
  final String id;
  final String name;
  final String version;
  final List<String> supportedLanguages;
  final bool isAvailable;
  final String platform; // 'ios', 'android', 'cross-platform'
  final List<String> capabilities; // 引擎功能列表

  const OCREngineInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.supportedLanguages,
    required this.isAvailable,
    required this.platform,
    required this.capabilities,
  });
}

/// OCR 引擎健康狀態
class OCREngineHealth {
  final String engineId;
  final bool isHealthy;
  final String? error;
  final double? responseTimeMs;
  final DateTime lastChecked; // 更名為 lastChecked

  const OCREngineHealth({
    required this.engineId,
    required this.isHealthy,
    required this.lastChecked,
    this.error,
    this.responseTimeMs,
  });
}

/// 圖片預處理選項
class ImagePreprocessOptions {
  /// 目標寬度（像素），null 表示不調整
  final int? targetWidth;

  /// 目標高度（像素），null 表示不調整
  final int? targetHeight;

  /// 對比度調整（-100 到 100）
  final int contrast;

  /// 亮度調整（-100 到 100）
  final int brightness;

  /// 是否轉為灰階
  final bool grayscale;

  /// 是否去噪
  final bool denoise;

  /// 是否銳化
  final bool sharpen;

  /// 是否增強對比度
  final bool enhanceContrast;

  /// 是否移除噪音
  final bool removeNoise;

  /// 是否標準化方向
  final bool normalizeOrientation;

  const ImagePreprocessOptions({
    this.targetWidth,
    this.targetHeight,
    this.contrast = 0,
    this.brightness = 0,
    this.grayscale = false,
    this.denoise = false,
    this.sharpen = false,
    this.enhanceContrast = false,
    this.removeNoise = false,
    this.normalizeOrientation = false,
  });
}

/// OCR 統計資訊
class OCRStatistics {
  final int totalProcessed;
  final double averageConfidence;
  final double averageProcessingTimeMs;
  final Map<String, int> engineUsage;
  final Map<String, double> languageConfidence;
  final DateTime lastUpdated;

  const OCRStatistics({
    required this.totalProcessed,
    required this.averageConfidence,
    required this.averageProcessingTimeMs,
    required this.engineUsage,
    required this.languageConfidence,
    required this.lastUpdated,
  });
}
