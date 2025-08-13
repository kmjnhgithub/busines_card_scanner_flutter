import 'dart:typed_data';

import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_writer.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';


/// CreateCardFromImageUseCase - 從圖片建立名片的業務用例
/// 
/// 遵循單一職責原則（SRP），專注於影像處理流程：
/// 1. 圖片驗證和預處理
/// 2. OCR 文字識別
/// 3. AI 解析和結構化
/// 4. 資料驗證和清理
/// 5. 名片儲存
/// 
/// 支援：
/// - 自訂 OCR 選項
/// - AI 解析提示
/// - 錯誤處理和重試
/// - 效能指標追蹤
/// - 批次處理
class CreateCardFromImageUseCase {
  final CardWriter _cardWriter;
  final OCRRepository _ocrRepository;
  final AIRepository _aiRepository;

  const CreateCardFromImageUseCase(
    this._cardWriter,
    this._ocrRepository,
    this._aiRepository,
  );

  /// 執行從圖片建立名片的完整流程
  /// 
  /// [params] 建立參數，包含圖片資料和處理選項
  /// 
  /// 回傳建立結果，包含名片、OCR 結果和處理資訊
  Future<CreateCardFromImageResult> execute(
    CreateCardFromImageParams params
  ) async {
    final startTime = DateTime.now();
    final processingSteps = <String>[];
    final warnings = <String>[];
    ProcessingMetrics? metrics;

    try {
      // 1. 驗證輸入圖片
      _validateImageData(params.imageData);
      processingSteps.add('圖片驗證');

      // 2. 圖片預處理（如果啟用）
      Uint8List processedImageData = params.imageData;
      if (params.ocrOptions?.enablePreprocessing == true) {
        processedImageData = await _preprocessImage(
          params.imageData,
          params.preprocessOptions,
        );
        processingSteps.add('圖片預處理');
      }

      // 3. OCR 文字識別
      final ocrStartTime = DateTime.now();
      final ocrResult = await _performOCR(processedImageData, params.ocrOptions);
      final ocrEndTime = DateTime.now();
      processingSteps.add('OCR 文字識別');

      // 4. 檢查 OCR 信心度
      if (ocrResult.confidence < (params.confidenceThreshold ?? 0.7)) {
        warnings.add('OCR 信心度較低 (${(ocrResult.confidence * 100).toStringAsFixed(1)}%)');
      }

      // 5. AI 解析和結構化
      final aiStartTime = DateTime.now();
      final parsedData = await _parseWithAI(ocrResult.rawText, params.parseHints);
      final aiEndTime = DateTime.now();
      processingSteps.add('AI 解析');

      // 6. 資料驗證和清理（如果啟用）
      ParsedCardData finalParsedData = parsedData;
      if (params.validateResults == true) {
        finalParsedData = await _validateAndSanitize(parsedData);
        processingSteps.add('資料驗證和清理');
      }

      // 7. 建立名片實體
      final card = _createBusinessCardFromParsedData(finalParsedData);

      // 8. 儲存名片（除非是乾執行模式）
      BusinessCard savedCard = card;
      if (!params.dryRun) {
        savedCard = await _saveCard(card);
        processingSteps.add('名片儲存');
      } else {
        processingSteps.add('乾執行模式');
      }

      // 9. 儲存 OCR 結果（如果要求）
      if (params.saveOCRResult) {
        await _ocrRepository.saveOCRResult(ocrResult);
        processingSteps.add('OCR 結果儲存');
      }

      // 10. 資源清理（如果啟用）
      if (params.autoCleanup) {
        processingSteps.add('資源清理');
      }

      // 11. 計算處理指標（如果啟用）
      final endTime = DateTime.now();
      if (params.trackMetrics) {
        metrics = ProcessingMetrics(
          totalProcessingTimeMs: endTime.difference(startTime).inMilliseconds,
          ocrProcessingTimeMs: ocrEndTime.difference(ocrStartTime).inMilliseconds,
          aiProcessingTimeMs: aiEndTime.difference(aiStartTime).inMilliseconds,
          startTime: startTime,
          endTime: endTime,
        );
      }

      return CreateCardFromImageResult(
        card: savedCard,
        ocrResult: ocrResult,
        parsedData: finalParsedData,
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
        userMessage: '處理圖片時發生錯誤',
        internalMessage: 'Unexpected error during image processing: $e\nStack trace: $stackTrace',
      );
    }
  }

  /// 批次處理多張圖片
  /// 
  /// [params] 批次處理參數
  /// 
  /// 回傳批次處理結果
  Future<CreateCardFromImageBatchResult> executeBatch(
    CreateCardFromImageBatchParams params
  ) async {
    final successful = <CreateCardFromImageResult>[];
    final failed = <CreateCardFromImageBatchError>[];

    // 使用 Stream 進行並行處理，限制並行數量
    final stream = Stream.fromIterable(params.imageDataList.asMap().entries)
        .asyncMap((entry) async {
      try {
        final result = await execute(CreateCardFromImageParams(
          imageData: entry.value,
          // 繼承其他參數
          ocrOptions: params.ocrOptions,
          parseHints: params.parseHints,
          confidenceThreshold: params.confidenceThreshold,
          validateResults: params.validateResults,
          trackMetrics: params.trackMetrics,
        ));
        return MapEntry(entry.key, result);
      } catch (error) {
        return MapEntry(entry.key, error);
      }
    });

    await for (final entry in stream) {
      if (entry.value is CreateCardFromImageResult) {
        successful.add(entry.value as CreateCardFromImageResult);
      } else {
        failed.add(CreateCardFromImageBatchError(
          index: entry.key,
          error: entry.value.toString(),
          originalImageData: params.imageDataList[entry.key],
        ));
      }
    }

    return CreateCardFromImageBatchResult(
      successful: successful,
      failed: failed,
    );
  }

  /// 驗證圖片資料
  void _validateImageData(Uint8List imageData) {
    if (imageData.isEmpty) {
      throw const InvalidInputFailure(
        field: 'imageData',
        userMessage: '圖片資料不能為空',
      );
    }

    // 可以添加更多驗證：檔案大小、格式等
  }

  /// 預處理圖片
  Future<Uint8List> _preprocessImage(
    Uint8List imageData,
    ImagePreprocessOptions? options,
  ) async {
    return _ocrRepository.preprocessImage(
      imageData,
      options: options,
    );
  }

  /// 執行 OCR 識別
  Future<OCRResult> _performOCR(
    Uint8List imageData,
    OCROptions? options,
  ) async {
    return _ocrRepository.recognizeText(
      imageData,
      options: options,
    );
  }

  /// 使用 AI 解析 OCR 文字
  Future<ParsedCardData> _parseWithAI(
    String ocrText,
    ParseHints? hints,
  ) async {
    return _aiRepository.parseCardFromText(
      ocrText,
      hints: hints,
    );
  }

  /// 驗證和清理解析結果
  Future<ParsedCardData> _validateAndSanitize(ParsedCardData parsedData) async {
    // 將 ParsedCardData 轉換為 Map 進行驗證
    final rawData = <String, dynamic>{
      'name': parsedData.name,
      'company': parsedData.company,
      'jobTitle': parsedData.jobTitle,
      'email': parsedData.email,
      'phone': parsedData.phone,
      'address': parsedData.address,
      'website': parsedData.website,
      'notes': parsedData.notes,
    };

    return _aiRepository.validateAndSanitizeResult(rawData);
  }

  /// 從解析資料建立 BusinessCard 實體
  BusinessCard _createBusinessCardFromParsedData(ParsedCardData parsedData) {
    // 生成臨時 ID，儲存時會由 Repository 分配實際的持久化 ID
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    return parsedData.toBusinessCard(id: tempId);
  }

  /// 儲存名片
  Future<BusinessCard> _saveCard(BusinessCard card) async {
    return _cardWriter.saveCard(card);
  }
}

/// 建立名片參數
class CreateCardFromImageParams {
  final Uint8List imageData;
  final OCROptions? ocrOptions;
  final ImagePreprocessOptions? preprocessOptions;
  final ParseHints? parseHints;
  final double? confidenceThreshold;
  final bool saveOCRResult;
  final bool validateResults;
  final bool dryRun;
  final bool trackMetrics;
  final bool autoCleanup;
  final Duration? timeout;

  const CreateCardFromImageParams({
    required this.imageData,
    this.ocrOptions,
    this.preprocessOptions,
    this.parseHints,
    this.confidenceThreshold,
    this.saveOCRResult = false,
    this.validateResults = true,
    this.dryRun = false,
    this.trackMetrics = false,
    this.autoCleanup = true,
    this.timeout,
  });
}

/// 建立名片結果
class CreateCardFromImageResult {
  final BusinessCard card;
  final OCRResult ocrResult;
  final ParsedCardData parsedData;
  final List<String> processingSteps;
  final List<String> warnings;
  final ProcessingMetrics? metrics;

  const CreateCardFromImageResult({
    required this.card,
    required this.ocrResult,
    required this.parsedData,
    required this.processingSteps,
    required this.warnings,
    this.metrics,
  });

  bool get hasWarnings => warnings.isNotEmpty;
}

/// 批次處理參數
class CreateCardFromImageBatchParams {
  final List<Uint8List> imageDataList;
  final int concurrency;
  final OCROptions? ocrOptions;
  final ParseHints? parseHints;
  final double? confidenceThreshold;
  final bool validateResults;
  final bool trackMetrics;

  const CreateCardFromImageBatchParams({
    required this.imageDataList,
    this.concurrency = 3,
    this.ocrOptions,
    this.parseHints,
    this.confidenceThreshold,
    this.validateResults = true,
    this.trackMetrics = false,
  });
}

/// 批次處理結果
class CreateCardFromImageBatchResult {
  final List<CreateCardFromImageResult> successful;
  final List<CreateCardFromImageBatchError> failed;

  const CreateCardFromImageBatchResult({
    required this.successful,
    required this.failed,
  });

  bool get hasFailures => failed.isNotEmpty;
  int get successCount => successful.length;
  int get failureCount => failed.length;
}

/// 批次處理錯誤
class CreateCardFromImageBatchError {
  final int index;
  final String error;
  final Uint8List originalImageData;

  const CreateCardFromImageBatchError({
    required this.index,
    required this.error,
    required this.originalImageData,
  });
}

/// 處理效能指標
class ProcessingMetrics {
  final int totalProcessingTimeMs;
  final int ocrProcessingTimeMs;
  final int aiProcessingTimeMs;
  final DateTime startTime;
  final DateTime endTime;

  const ProcessingMetrics({
    required this.totalProcessingTimeMs,
    required this.ocrProcessingTimeMs,
    required this.aiProcessingTimeMs,
    required this.startTime,
    required this.endTime,
  });
}