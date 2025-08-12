import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_writer.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/core/errors/failures.dart';

/// CreateCardFromOCRUseCase - 從 OCR 結果建立名片的業務用例
/// 
/// 遵循單一職責原則（SRP），專注於 OCR 結果處理流程：
/// 1. 驗證 OCR 結果有效性
/// 2. 使用 AI 解析 OCR 文字為結構化資料
/// 3. 驗證和清理解析結果
/// 4. 建立名片實體並儲存
/// 
/// 遵循介面隔離原則（ISP），只依賴必要的 Repository 介面：
/// - CardWriter：負責名片儲存
/// - AIRepository：負責文字解析
/// 
/// 遵循依賴反轉原則（DIP），依賴抽象而非具體實作
class CreateCardFromOCRUseCase {
  const CreateCardFromOCRUseCase(
    this._cardWriter,
    this._aiRepository,
  );

  final CardWriter _cardWriter;
  final AIRepository _aiRepository;

  /// 執行從 OCR 結果建立名片的業務邏輯
  /// 
  /// [params] 包含 OCR 結果和相關參數的執行參數
  /// 
  /// 回傳建立結果，包含成功建立的名片和處理資訊
  /// 
  /// Throws:
  /// - [InvalidInputFailure] 當 OCR 文字無效或為空
  /// - [AIServiceUnavailableFailure] 當 AI 服務無法使用
  /// - [AIQuotaExceededFailure] 當 API 配額用盡
  /// - [StorageSpaceFailure] 當儲存空間不足
  /// - [DataSourceFailure] 當發生未預期的錯誤
  Future<CreateCardFromOCRResult> execute(CreateCardFromOCRParams params) async {
    try {
      final startTime = DateTime.now();
      final processingSteps = <String>[];
      final warnings = <String>[];
      ProcessingMetrics? metrics;

      // 1. 驗證 OCR 結果
      _validateOCRResult(params.ocrResult);
      processingSteps.add('OCR 結果驗證');

      // 2. 檢查 OCR 信心度
      if (params.ocrResult.confidence < (params.confidenceThreshold ?? 0.7)) {
        warnings.add('OCR 信心度較低 (${(params.ocrResult.confidence * 100).toStringAsFixed(1)}%)');
      }

      // 3. AI 文字解析
      final aiStartTime = DateTime.now();
      final parsedData = await _parseWithAI(
        params.ocrResult.rawText, 
        params.parseHints,
      );
      final aiEndTime = DateTime.now();
      processingSteps.add('AI 文字解析');

      // 4. 資料驗證和清理（如果啟用）
      ParsedCardData finalParsedData = parsedData;
      if (params.enableSanitization ?? true) {
        finalParsedData = await _validateAndSanitize(parsedData);
        processingSteps.add('資料驗證和清理');
      }

      // 5. 建立名片實體
      final card = _createBusinessCardFromParsedData(finalParsedData);

      // 6. 儲存名片（除非是乾執行模式）
      BusinessCard savedCard = card;
      if (params.dryRun == true) {
        processingSteps.add('乾執行模式');
      } else {
        savedCard = await _saveCard(card);
        processingSteps.add('名片資料儲存');
      }

      // 7. 資源清理（如果啟用）
      if (params.autoCleanup == true) {
        processingSteps.add('資源清理');
      }

      // 8. 計算處理指標（如果啟用）
      final endTime = DateTime.now();
      if (params.trackMetrics == true) {
        metrics = ProcessingMetrics(
          totalProcessingTimeMs: endTime.difference(startTime).inMilliseconds,
          aiProcessingTimeMs: aiEndTime.difference(aiStartTime).inMilliseconds,
          startTime: startTime,
          endTime: endTime,
        );
      }

      return CreateCardFromOCRResult(
        card: savedCard,
        parsedData: finalParsedData,
        processingSteps: processingSteps,
        warnings: warnings,
        metrics: metrics,
      );

    } catch (e, stackTrace) {
      // 重新拋出已知的業務異常
      if (e is Failure) {
        rethrow;
      }
      
      // 包裝未預期的異常
      throw DataSourceFailure(
        userMessage: '處理 OCR 結果時發生錯誤',
        internalMessage: 'Unexpected error during OCR processing: $e\nStack trace: $stackTrace',
      );
    }
  }

  /// 批次處理多個 OCR 結果
  /// 
  /// [params] 批次處理參數
  /// 
  /// 回傳批次處理結果
  Future<CreateCardFromOCRBatchResult> executeBatch(CreateCardFromOCRBatchParams params) async {
    final successful = <CreateCardFromOCRResult>[];
    final failed = <CreateCardFromOCRBatchError>[];

    for (int i = 0; i < params.ocrResults.length; i++) {
      try {
        final result = await execute(CreateCardFromOCRParams(
          ocrResult: params.ocrResults[i],
          parseHints: params.parseHints,
          confidenceThreshold: params.confidenceThreshold,
          enableSanitization: params.enableSanitization,
          dryRun: params.dryRun,
          trackMetrics: params.trackMetrics,
          autoCleanup: params.autoCleanup,
        ));
        successful.add(result);
      } catch (e) {
        failed.add(CreateCardFromOCRBatchError(
          index: i,
          error: e.toString(),
          originalOCRResult: params.ocrResults[i],
        ));
      }
    }

    return CreateCardFromOCRBatchResult(
      successful: successful,
      failed: failed,
    );
  }

  /// 驗證 OCR 結果有效性
  void _validateOCRResult(OCRResult ocrResult) {
    if (ocrResult.rawText.trim().isEmpty) {
      throw const InvalidInputFailure(
        field: 'ocrText',
        userMessage: 'OCR 文字內容不能為空',
      );
    }
  }

  /// 使用 AI 解析 OCR 文字
  Future<ParsedCardData> _parseWithAI(String ocrText, ParseHints? hints) async {
    return await _aiRepository.parseCardFromText(
      ocrText,
      hints: hints,
    );
  }

  /// 驗證和清理解析結果
  Future<ParsedCardData> _validateAndSanitize(ParsedCardData parsedData) async {
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

    return await _aiRepository.validateAndSanitizeResult(rawData);
  }

  /// 從解析資料建立 BusinessCard 實體
  BusinessCard _createBusinessCardFromParsedData(ParsedCardData parsedData) {
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    return parsedData.toBusinessCard(id: tempId);
  }

  /// 儲存名片
  Future<BusinessCard> _saveCard(BusinessCard card) async {
    return await _cardWriter.saveCard(card);
  }
}

/// 執行參數
class CreateCardFromOCRParams {
  const CreateCardFromOCRParams({
    required this.ocrResult,
    this.parseHints,
    this.confidenceThreshold,
    this.enableSanitization,
    this.dryRun,
    this.trackMetrics,
    this.autoCleanup,
  });

  /// OCR 結果
  final OCRResult ocrResult;

  /// 解析提示
  final ParseHints? parseHints;

  /// 信心度門檻
  final double? confidenceThreshold;

  /// 是否啟用資料清理
  final bool? enableSanitization;

  /// 是否為乾執行模式（不儲存）
  final bool? dryRun;

  /// 是否追蹤效能指標
  final bool? trackMetrics;

  /// 是否自動清理資源
  final bool? autoCleanup;
}

/// 批次處理參數
class CreateCardFromOCRBatchParams {
  const CreateCardFromOCRBatchParams({
    required this.ocrResults,
    this.parseHints,
    this.confidenceThreshold,
    this.enableSanitization,
    this.dryRun,
    this.trackMetrics,
    this.autoCleanup,
  });

  /// OCR 結果列表
  final List<OCRResult> ocrResults;

  /// 解析提示
  final ParseHints? parseHints;

  /// 信心度門檻
  final double? confidenceThreshold;

  /// 是否啟用資料清理
  final bool? enableSanitization;

  /// 是否為乾執行模式（不儲存）
  final bool? dryRun;

  /// 是否追蹤效能指標
  final bool? trackMetrics;

  /// 是否自動清理資源
  final bool? autoCleanup;
}

/// 執行結果
class CreateCardFromOCRResult {
  const CreateCardFromOCRResult({
    required this.card,
    required this.parsedData,
    required this.processingSteps,
    required this.warnings,
    this.metrics,
  });

  /// 建立的名片
  final BusinessCard card;

  /// AI 解析的資料
  final ParsedCardData parsedData;

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
class CreateCardFromOCRBatchResult {
  const CreateCardFromOCRBatchResult({
    required this.successful,
    required this.failed,
  });

  /// 成功建立的結果
  final List<CreateCardFromOCRResult> successful;

  /// 失敗的錯誤
  final List<CreateCardFromOCRBatchError> failed;

  /// 是否有失敗
  bool get hasFailures => failed.isNotEmpty;

  /// 成功數量
  int get successCount => successful.length;

  /// 失敗數量
  int get failureCount => failed.length;
}

/// 批次處理錯誤
class CreateCardFromOCRBatchError {
  const CreateCardFromOCRBatchError({
    required this.index,
    required this.error,
    required this.originalOCRResult,
  });

  /// 錯誤的索引位置
  final int index;

  /// 錯誤訊息
  final String error;

  /// 原始 OCR 結果
  final OCRResult originalOCRResult;
}

/// 處理效能指標
class ProcessingMetrics {
  const ProcessingMetrics({
    required this.totalProcessingTimeMs,
    required this.aiProcessingTimeMs,
    required this.startTime,
    required this.endTime,
  });

  /// 總處理時間（毫秒）
  final int totalProcessingTimeMs;

  /// AI 處理時間（毫秒）
  final int aiProcessingTimeMs;

  /// 開始時間
  final DateTime startTime;

  /// 結束時間
  final DateTime endTime;
}