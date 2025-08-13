import 'dart:typed_data';

import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';

/// ProcessImageUseCase - 圖片處理的業務用例
///
/// 遵循單一職責原則（SRP），專注於圖片處理流程：
/// 1. 圖片驗證和預處理
/// 2. OCR 文字識別
/// 3. 結果品質驗證
/// 4. OCR 引擎管理
/// 5. 統計和監控
///
/// 支援：
/// - 單張和批次圖片處理
/// - 圖片預處理和最佳化
/// - OCR 引擎管理
/// - 處理統計和監控
/// - 效能指標追蹤
///
/// 遵循依賴反轉原則（DIP），依賴抽象而非具體實作
class ProcessImageUseCase {
  const ProcessImageUseCase(this._ocrRepository);

  final OCRRepository _ocrRepository;

  /// 執行圖片處理的業務邏輯
  ///
  /// [params] 包含圖片資料和處理選項的參數
  ///
  /// 回傳處理結果，包含 OCR 結果和處理資訊
  ///
  /// Throws:
  /// - [InvalidInputFailure] 當輸入無效
  /// - [DataSourceFailure] 當發生處理錯誤
  /// - [StorageSpaceFailure] 當儲存空間不足
  Future<ProcessImageResult> execute(ProcessImageParams params) async {
    try {
      final startTime = DateTime.now();
      final processingSteps = <String>[];
      final warnings = <String>[];
      ProcessingMetrics? metrics;

      // 1. 驗證輸入參數
      _validateInputParams(params);
      processingSteps.add('參數驗證');

      // 2. 乾執行模式檢查
      if (params.dryRun == true) {
        processingSteps.add('乾執行模式');
        return _createDryRunResult(params, processingSteps, startTime);
      }

      // 3. 自動選擇 OCR 引擎（如果啟用）
      if (params.autoSelectEngine == true) {
        processingSteps.add('自動選擇引擎');
      }

      // 4. 圖片預處理
      Uint8List processedImageData = params.imageData;
      final preprocessingStartTime = DateTime.now();

      if (params.enablePreprocessing == true || params.optimizeImage == true) {
        processedImageData = await _preprocessImage(params);
        if (params.enablePreprocessing == true) {
          processingSteps.add('圖片預處理');
        }
        if (params.optimizeImage == true) {
          processingSteps.add('圖片最佳化');
        }
      }

      final preprocessingEndTime = DateTime.now();

      // 5. 執行 OCR 處理
      final ocrStartTime = DateTime.now();
      final ocrResult = await _performOCR(
        processedImageData,
        params.ocrOptions,
      );
      final ocrEndTime = DateTime.now();
      processingSteps.add('OCR 文字識別');

      // 6. 檢查 OCR 信心度
      if (ocrResult.confidence < (params.confidenceThreshold ?? 0.7)) {
        warnings.add(
          '信心度較低 (${(ocrResult.confidence * 100).toStringAsFixed(1)}%)',
        );
      }

      // 7. 驗證結果品質（如果啟用）
      if (params.validateQuality == true) {
        final qualityWarnings = _validateResultQuality(ocrResult, params);
        warnings.addAll(qualityWarnings);
      }

      // 8. 儲存 OCR 結果（如果要求）
      if (params.saveResult == true) {
        await _saveOCRResult(ocrResult);
        processingSteps.add('OCR 結果儲存');
      }

      // 9. 資源清理（如果啟用）
      if (params.autoCleanup == true) {
        processingSteps.add('資源清理');
      }

      // 10. 計算處理指標（如果啟用）
      final endTime = DateTime.now();
      if (params.trackMetrics == true) {
        metrics = ProcessingMetrics(
          totalProcessingTimeMs: endTime.difference(startTime).inMilliseconds,
          preprocessingTimeMs: preprocessingEndTime
              .difference(preprocessingStartTime)
              .inMilliseconds,
          ocrProcessingTimeMs: ocrEndTime
              .difference(ocrStartTime)
              .inMilliseconds,
          startTime: startTime,
          endTime: endTime,
        );
      }

      return ProcessImageResult(
        isSuccess: true,
        ocrResult: ocrResult,
        processingSteps: processingSteps,
        warnings: warnings,
        metrics: metrics,
      );
    } catch (e, stackTrace) {
      // 重新拋出已知的業務異常
      if (e is DomainFailure) {
        rethrow;
      }

      // 包裝未預期的異常
      throw DataSourceFailure(
        userMessage: '圖片處理時發生錯誤',
        internalMessage:
            'Unexpected error during image processing: $e\nStack trace: $stackTrace',
      );
    }
  }

  /// 批次處理多張圖片
  ///
  /// [params] 批次處理參數
  ///
  /// 回傳批次處理結果
  Future<ProcessImageBatchResult> executeBatch(
    ProcessImageBatchParams params,
  ) async {
    try {
      final successful = <ProcessImageResult>[];
      final failed = <ProcessImageBatchError>[];

      // 使用 Repository 的批次處理功能
      final batchResult = await _performBatchOCR(
        params.imageDataList,
        params.ocrOptions,
      );

      // 轉換成功的結果
      for (final ocrResult in batchResult.successful) {
        successful.add(
          ProcessImageResult(
            isSuccess: true,
            ocrResult: ocrResult,
            processingSteps: ['批次 OCR 處理'],
            warnings: [],
          ),
        );
      }

      // 轉換失敗的結果
      for (final error in batchResult.failed) {
        failed.add(
          ProcessImageBatchError(
            index: error.index,
            error: error.error,
            originalImageData: error.originalImageData ?? Uint8List(0),
          ),
        );
      }

      return ProcessImageBatchResult(successful: successful, failed: failed);
    } catch (e, stackTrace) {
      if (e is DomainFailure) {
        rethrow;
      }

      throw DataSourceFailure(
        userMessage: '批次處理圖片時發生錯誤',
        internalMessage:
            'Unexpected error during batch processing: $e\nStack trace: $stackTrace',
      );
    }
  }

  /// 取得可用的 OCR 引擎
  Future<List<OCREngineInfo>> getAvailableEngines() async {
    return _ocrRepository.getAvailableEngines();
  }

  /// 設定偏好的 OCR 引擎
  Future<void> setPreferredEngine(String engineId) async {
    return _ocrRepository.setPreferredEngine(engineId);
  }

  /// 取得目前的 OCR 引擎
  Future<OCREngineInfo> getCurrentEngine() async {
    return _ocrRepository.getCurrentEngine();
  }

  /// 測試 OCR 引擎健康狀態
  Future<OCREngineHealth> testEngineHealth(String engineId) async {
    return _ocrRepository.testEngine(engineId: engineId);
  }

  /// 取得處理統計資料
  Future<OCRStatistics> getStatistics() async {
    return _ocrRepository.getStatistics();
  }

  /// 清理舊的 OCR 結果
  Future<int> cleanupOldResults({int daysOld = 30}) async {
    return _ocrRepository.cleanupOldResults(daysOld: daysOld);
  }

  /// 驗證輸入參數
  void _validateInputParams(ProcessImageParams params) {
    // 驗證圖片資料
    if (params.imageData.isEmpty) {
      throw const InvalidInputFailure(
        field: 'imageData',
        userMessage: '圖片資料不能為空',
      );
    }

    // 驗證圖片大小
    if (params.maxImageSizeBytes != null &&
        params.imageData.length > params.maxImageSizeBytes!) {
      throw InvalidInputFailure(
        field: 'imageData',
        userMessage:
            '圖片檔案過大，最大限制為 ${params.maxImageSizeBytes! ~/ (1024 * 1024)} MB',
      );
    }

    // 驗證信心度門檻
    if (params.confidenceThreshold != null) {
      final threshold = params.confidenceThreshold!;
      if (threshold < 0.0 || threshold > 1.0) {
        throw const InvalidInputFailure(
          field: 'confidenceThreshold',
          userMessage: '信心度門檻必須在 0.0 到 1.0 之間',
        );
      }
    }

    // 驗證圖片格式（如果啟用）
    if (params.validateImageFormat == true) {
      _validateImageFormat(params.imageData);
    }
  }

  /// 驗證圖片格式
  void _validateImageFormat(Uint8List imageData) {
    // 檢查常見的圖片格式 header
    if (imageData.length < 4) {
      throw const InvalidInputFailure(
        field: 'imageData',
        userMessage: '圖片資料不完整',
      );
    }

    final header = imageData.sublist(0, 4);

    // JPEG: FF D8 FF
    // PNG: 89 50 4E 47
    // WebP: 52 49 46 46 (RIFF)
    final isJPEG = header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF;
    final isPNG =
        header[0] == 0x89 &&
        header[1] == 0x50 &&
        header[2] == 0x4E &&
        header[3] == 0x47;
    final isWebP =
        header[0] == 0x52 &&
        header[1] == 0x49 &&
        header[2] == 0x46 &&
        header[3] == 0x46;

    if (!isJPEG && !isPNG && !isWebP) {
      throw const InvalidInputFailure(
        field: 'imageData',
        userMessage: '不支援的圖片格式，請使用 JPEG、PNG 或 WebP 格式',
      );
    }
  }

  /// 預處理圖片
  Future<Uint8List> _preprocessImage(ProcessImageParams params) async {
    return _ocrRepository.preprocessImage(
      params.imageData,
      options: params.preprocessOptions,
    );
  }

  /// 執行 OCR 處理
  Future<OCRResult> _performOCR(
    Uint8List imageData,
    OCROptions? options,
  ) async {
    return _ocrRepository.recognizeText(imageData, options: options);
  }

  /// 執行批次 OCR 處理
  Future<BatchOCRResult> _performBatchOCR(
    List<Uint8List> imageDataList,
    OCROptions? options,
  ) async {
    return _ocrRepository.recognizeTexts(imageDataList, options: options);
  }

  /// 儲存 OCR 結果
  Future<OCRResult> _saveOCRResult(OCRResult result) async {
    return _ocrRepository.saveOCRResult(result);
  }

  /// 驗證結果品質
  List<String> _validateResultQuality(
    OCRResult result,
    ProcessImageParams params,
  ) {
    final warnings = <String>[];

    // 檢查文字長度
    if (params.minTextLength != null &&
        result.rawText.trim().length < params.minTextLength!) {
      warnings.add('文字品質可能不佳：文字內容過短');
    }

    // 檢查是否包含太多數字（可能是低品質掃描）
    final digitCount = result.rawText.replaceAll(RegExp(r'[^\d]'), '').length;
    final totalLength = result.rawText.trim().length;
    if (totalLength > 0 && digitCount / totalLength > 0.7) {
      warnings.add('文字品質可能不佳：包含過多數字字符');
    }

    // 檢查是否包含太多特殊字符
    final specialCharCount = result.rawText
        .replaceAll(RegExp(r'[a-zA-Z0-9\u4e00-\u9fff\s]'), '')
        .length;
    if (totalLength > 0 && specialCharCount / totalLength > 0.3) {
      warnings.add('文字品質可能不佳：包含過多特殊字符');
    }

    return warnings;
  }

  /// 建立乾執行結果
  ProcessImageResult _createDryRunResult(
    ProcessImageParams params,
    List<String> processingSteps,
    DateTime startTime,
  ) {
    // 建立模擬的 OCR 結果
    final mockResult = OCRResult(
      id: 'dry-run-${DateTime.now().millisecondsSinceEpoch}',
      rawText: 'Dry run mode - no actual processing',
      confidence: 0,
      processingTimeMs: 0,
      processedAt: DateTime.now(),
    );

    ProcessingMetrics? metrics;
    if (params.trackMetrics == true) {
      final endTime = DateTime.now();
      metrics = ProcessingMetrics(
        totalProcessingTimeMs: endTime.difference(startTime).inMilliseconds,
        preprocessingTimeMs: 0,
        ocrProcessingTimeMs: 0,
        startTime: startTime,
        endTime: endTime,
      );
    }

    return ProcessImageResult(
      isSuccess: true,
      ocrResult: mockResult,
      processingSteps: processingSteps,
      warnings: [],
      metrics: metrics,
    );
  }
}

/// 處理參數
class ProcessImageParams {
  const ProcessImageParams({
    required this.imageData,
    this.ocrOptions,
    this.preprocessOptions,
    this.confidenceThreshold,
    this.maxImageSizeBytes,
    this.minTextLength,
    this.maxMemoryUsageMB,
    this.enablePreprocessing,
    this.optimizeImage,
    this.validateImageFormat,
    this.validateQuality,
    this.autoSelectEngine,
    this.saveResult,
    this.dryRun,
    this.trackMetrics,
    this.autoCleanup,
    this.timeout,
  });

  /// 圖片資料
  final Uint8List imageData;

  /// OCR 選項
  final OCROptions? ocrOptions;

  /// 預處理選項
  final ImagePreprocessOptions? preprocessOptions;

  /// 信心度門檻
  final double? confidenceThreshold;

  /// 最大圖片大小（位元組）
  final int? maxImageSizeBytes;

  /// 最小文字長度
  final int? minTextLength;

  /// 最大記憶體使用量（MB）
  final int? maxMemoryUsageMB;

  /// 是否啟用預處理
  final bool? enablePreprocessing;

  /// 是否最佳化圖片
  final bool? optimizeImage;

  /// 是否驗證圖片格式
  final bool? validateImageFormat;

  /// 是否驗證結果品質
  final bool? validateQuality;

  /// 是否自動選擇引擎
  final bool? autoSelectEngine;

  /// 是否儲存結果
  final bool? saveResult;

  /// 是否為乾執行模式
  final bool? dryRun;

  /// 是否追蹤效能指標
  final bool? trackMetrics;

  /// 是否自動清理資源
  final bool? autoCleanup;

  /// 操作超時時間
  final Duration? timeout;
}

/// 批次處理參數
class ProcessImageBatchParams {
  const ProcessImageBatchParams({
    required this.imageDataList,
    this.ocrOptions,
    this.concurrency = 3,
    this.trackMetrics,
  });

  /// 圖片資料列表
  final List<Uint8List> imageDataList;

  /// OCR 選項
  final OCROptions? ocrOptions;

  /// 並行處理數量
  final int concurrency;

  /// 是否追蹤效能指標
  final bool? trackMetrics;
}

/// 處理結果
class ProcessImageResult {
  const ProcessImageResult({
    required this.isSuccess,
    required this.ocrResult,
    required this.processingSteps,
    required this.warnings,
    this.metrics,
  });

  /// 是否成功
  final bool isSuccess;

  /// OCR 結果
  final OCRResult ocrResult;

  /// 處理步驟
  final List<String> processingSteps;

  /// 警告訊息
  final List<String> warnings;

  /// 效能指標（可選）
  final ProcessingMetrics? metrics;

  /// 是否有警告
  bool get hasWarnings => warnings.isNotEmpty;
}

/// 批次處理結果
class ProcessImageBatchResult {
  const ProcessImageBatchResult({
    required this.successful,
    required this.failed,
  });

  /// 成功處理的結果
  final List<ProcessImageResult> successful;

  /// 失敗的錯誤
  final List<ProcessImageBatchError> failed;

  /// 是否有失敗
  bool get hasFailures => failed.isNotEmpty;

  /// 成功數量
  int get successCount => successful.length;

  /// 失敗數量
  int get failureCount => failed.length;
}

/// 批次處理錯誤
class ProcessImageBatchError {
  const ProcessImageBatchError({
    required this.index,
    required this.error,
    required this.originalImageData,
  });

  /// 在批次中的索引位置
  final int index;

  /// 錯誤訊息
  final String error;

  /// 原始圖片資料
  final Uint8List originalImageData;
}

/// 處理效能指標
class ProcessingMetrics {
  const ProcessingMetrics({
    required this.totalProcessingTimeMs,
    required this.preprocessingTimeMs,
    required this.ocrProcessingTimeMs,
    required this.startTime,
    required this.endTime,
  });

  /// 總處理時間（毫秒）
  final int totalProcessingTimeMs;

  /// 預處理時間（毫秒）
  final int preprocessingTimeMs;

  /// OCR 處理時間（毫秒）
  final int ocrProcessingTimeMs;

  /// 開始時間
  final DateTime startTime;

  /// 結束時間
  final DateTime endTime;
}
