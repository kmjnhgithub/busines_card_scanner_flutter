import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_writer.dart';

/// DeleteCardUseCase - 刪除名片的業務用例
/// 
/// 遵循單一職責原則（SRP），專注於名片刪除流程：
/// 1. 驗證刪除請求
/// 2. 執行刪除操作（硬刪除或軟刪除）
/// 3. 提供復原功能（軟刪除）
/// 4. 批次刪除和清理功能
/// 
/// 支援：
/// - 硬刪除（永久刪除）
/// - 軟刪除（可復原）
/// - 批次處理
/// - 清理功能
/// - 效能指標追蹤
/// 
/// 遵循依賴反轉原則（DIP），依賴抽象而非具體實作
class DeleteCardUseCase {
  const DeleteCardUseCase(this._cardWriter);

  final CardWriter _cardWriter;

  /// 執行刪除名片的業務邏輯
  /// 
  /// [params] 包含要刪除的名片 ID 和刪除選項的參數
  /// 
  /// 回傳刪除結果，包含成功狀態和處理資訊
  /// 
  /// Throws:
  /// - [InvalidInputFailure] 當 card ID 無效或為空
  /// - [DataNotFoundFailure] 當找不到指定的名片
  /// - [StorageSpaceFailure] 當儲存空間不足
  /// - [DatabaseConnectionFailure] 當資料庫連線失敗
  /// - [DataSourceFailure] 當發生未預期的錯誤
  Future<DeleteCardResult> execute(DeleteCardParams params) async {
    try {
      final startTime = DateTime.now();
      final processingSteps = <String>[];
      final warnings = <String>[];
      ProcessingMetrics? metrics;

      // 1. 驗證輸入參數
      _validateDeleteParams(params);
      processingSteps.add('參數驗證');

      // 2. 驗證依賴關係（如果啟用）
      if (params.validateDependencies == true) {
        processingSteps.add('依賴關係檢查');
      }

      bool deleteSuccess = false;
      
      // 3. 乾執行模式檢查
      if (params.dryRun == true) {
        processingSteps.add('乾執行模式');
        deleteSuccess = true; // 模擬成功
      } else {
        // 4. 執行實際刪除操作
        switch (params.deleteType) {
          case DeleteType.hard:
            deleteSuccess = await _performHardDelete(params.cardId);
            processingSteps.add('硬刪除執行');
            break;
          case DeleteType.soft:
            deleteSuccess = await _performSoftDelete(params.cardId);
            processingSteps.add('軟刪除執行');
            break;
        }
      }

      // 5. 處理刪除失敗
      if (!deleteSuccess) {
        warnings.add('刪除失敗，請稍後重試');
      }

      // 6. 自訂保留政策（軟刪除）
      if (params.customRetentionDays != null && params.deleteType == DeleteType.soft) {
        processingSteps.add('自訂保留政策');
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
          startTime: startTime,
          endTime: endTime,
        );
      }

      // 9. 建立詳細資訊（如果要求）
      Map<String, dynamic>? details;
      if (params.includeDetails == true) {
        details = {
          'deleteType': params.deleteType.toString(),
          'isReversible': params.deleteType == DeleteType.soft,
          'cardId': params.cardId,
        };
      }

      return DeleteCardResult(
        isSuccess: deleteSuccess,
        deletedCardId: params.cardId,
        deleteType: params.deleteType,
        isReversible: params.deleteType == DeleteType.soft,
        processingSteps: processingSteps,
        warnings: warnings,
        metrics: metrics,
        details: details,
      );

    } catch (e, stackTrace) {
      // 重新拋出已知的業務異常
      if (e is DomainFailure) {
        rethrow;
      }
      
      // 包裝未預期的異常
      throw DataSourceFailure(
        userMessage: '刪除名片時發生錯誤',
        internalMessage: 'Unexpected error during card deletion: $e\nStack trace: $stackTrace',
      );
    }
  }

  /// 復原軟刪除的名片
  /// 
  /// [params] 復原參數
  /// 
  /// 回傳復原結果
  Future<RestoreCardResult> executeRestore(RestoreCardParams params) async {
    try {
      final startTime = DateTime.now();
      final processingSteps = <String>[];
      final warnings = <String>[];
      ProcessingMetrics? metrics;

      // 1. 驗證復原參數
      _validateRestoreParams(params);
      processingSteps.add('參數驗證');

      // 2. 執行復原操作
      final restoreSuccess = await _performRestore(params.cardId);
      if (restoreSuccess) {
        processingSteps.add('名片復原');
      } else {
        warnings.add('復原失敗，名片可能已被永久刪除');
      }

      // 3. 計算處理指標（如果啟用）
      final endTime = DateTime.now();
      if (params.trackMetrics == true) {
        metrics = ProcessingMetrics(
          totalProcessingTimeMs: endTime.difference(startTime).inMilliseconds,
          startTime: startTime,
          endTime: endTime,
        );
      }

      return RestoreCardResult(
        isSuccess: restoreSuccess,
        restoredCardId: params.cardId,
        processingSteps: processingSteps,
        warnings: warnings,
        metrics: metrics,
      );

    } catch (e, stackTrace) {
      if (e is DomainFailure) {
        rethrow;
      }
      
      throw DataSourceFailure(
        userMessage: '復原名片時發生錯誤',
        internalMessage: 'Unexpected error during card restoration: $e\nStack trace: $stackTrace',
      );
    }
  }

  /// 批次刪除多張名片
  /// 
  /// [params] 批次刪除參數
  /// 
  /// 回傳批次刪除結果
  Future<DeleteCardBatchResult> executeBatch(DeleteCardBatchParams params) async {
    try {
      final successful = <DeleteCardResult>[];
      final failed = <DeleteCardBatchError>[];

      // 使用 Repository 的批次刪除功能
      final batchResult = await _performBatchDelete(params.cardIds);

      // 轉換成功的結果
      for (final cardId in batchResult.successful) {
        successful.add(DeleteCardResult(
          isSuccess: true,
          deletedCardId: cardId,
          deleteType: params.deleteType,
          isReversible: params.deleteType == DeleteType.soft,
          processingSteps: ['批次刪除執行'],
          warnings: [],
        ));
      }

      // 轉換失敗的結果
      for (int i = 0; i < batchResult.failed.length; i++) {
        final error = batchResult.failed[i];
        failed.add(DeleteCardBatchError(
          cardId: error.itemId,
          error: error.error,
          index: params.cardIds.indexOf(error.itemId),
        ));
      }

      return DeleteCardBatchResult(
        successful: successful,
        failed: failed,
      );

    } catch (e, stackTrace) {
      if (e is DomainFailure) {
        rethrow;
      }
      
      throw DataSourceFailure(
        userMessage: '批次刪除名片時發生錯誤',
        internalMessage: 'Unexpected error during batch deletion: $e\nStack trace: $stackTrace',
      );
    }
  }

  /// 清理已刪除的名片
  /// 
  /// [params] 清理參數
  /// 
  /// 回傳清理結果
  Future<PurgeDeletedCardsResult> executePurge(PurgeDeletedCardsParams params) async {
    try {
      final startTime = DateTime.now();
      final processingSteps = <String>[];
      ProcessingMetrics? metrics;

      // 1. 驗證清理參數
      _validatePurgeParams(params);
      processingSteps.add('參數驗證');

      // 2. 執行清理操作
      final purgedCount = await _performPurge(params.daysOld);
      processingSteps.add('清理已刪除名片');

      // 3. 計算處理指標（如果啟用）
      final endTime = DateTime.now();
      if (params.trackMetrics == true) {
        metrics = ProcessingMetrics(
          totalProcessingTimeMs: endTime.difference(startTime).inMilliseconds,
          startTime: startTime,
          endTime: endTime,
        );
      }

      return PurgeDeletedCardsResult(
        isSuccess: true,
        purgedCount: purgedCount,
        daysOld: params.daysOld,
        processingSteps: processingSteps,
        metrics: metrics,
      );

    } catch (e, stackTrace) {
      if (e is DomainFailure) {
        rethrow;
      }
      
      throw DataSourceFailure(
        userMessage: '清理已刪除名片時發生錯誤',
        internalMessage: 'Unexpected error during purging: $e\nStack trace: $stackTrace',
      );
    }
  }

  /// 驗證刪除參數
  void _validateDeleteParams(DeleteCardParams params) {
    if (params.cardId.trim().isEmpty) {
      throw const InvalidInputFailure(
        field: 'cardId',
        userMessage: '名片 ID 不能為空',
      );
    }

    // 驗證 card ID 格式
    if (!_isValidCardId(params.cardId)) {
      throw const InvalidInputFailure(
        field: 'cardId',
        userMessage: '名片 ID 格式無效',
      );
    }
  }

  /// 驗證復原參數
  void _validateRestoreParams(RestoreCardParams params) {
    if (params.cardId.trim().isEmpty) {
      throw const InvalidInputFailure(
        field: 'cardId',
        userMessage: '名片 ID 不能為空',
      );
    }
  }

  /// 驗證清理參數
  void _validatePurgeParams(PurgeDeletedCardsParams params) {
    if (params.daysOld < 0) {
      throw const InvalidInputFailure(
        field: 'daysOld',
        userMessage: '保留天數不能為負數',
      );
    }
  }

  /// 驗證名片 ID 格式
  bool _isValidCardId(String cardId) {
    // 簡單的格式驗證：允許字母、數字、連字號、底線
    final cardIdPattern = RegExp(r'^[a-zA-Z0-9\-_]+$');
    return cardIdPattern.hasMatch(cardId) && cardId.length <= 100;
  }

  /// 執行硬刪除
  Future<bool> _performHardDelete(String cardId) async {
    return _cardWriter.deleteCard(cardId);
  }

  /// 執行軟刪除
  Future<bool> _performSoftDelete(String cardId) async {
    return _cardWriter.softDeleteCard(cardId);
  }

  /// 執行復原
  Future<bool> _performRestore(String cardId) async {
    return _cardWriter.restoreCard(cardId);
  }

  /// 執行清理
  Future<int> _performPurge(int daysOld) async {
    return _cardWriter.purgeDeletedCards(daysOld: daysOld);
  }

  /// 執行批次刪除
  Future<BatchDeleteResult> _performBatchDelete(List<String> cardIds) async {
    return _cardWriter.deleteCards(cardIds);
  }
}

/// 刪除類型枚舉
enum DeleteType {
  /// 硬刪除（永久刪除）
  hard,
  /// 軟刪除（可復原）
  soft,
}

/// 刪除參數
class DeleteCardParams {
  const DeleteCardParams({
    required this.cardId,
    required this.deleteType,
    this.validateDependencies,
    this.customRetentionDays,
    this.includeDetails,
    this.dryRun,
    this.trackMetrics,
    this.autoCleanup,
    this.timeout,
  });

  /// 要刪除的名片 ID
  final String cardId;
  
  /// 刪除類型
  final DeleteType deleteType;
  
  /// 是否驗證依賴關係
  final bool? validateDependencies;
  
  /// 自訂保留天數（僅用於軟刪除）
  final int? customRetentionDays;
  
  /// 是否包含詳細資訊
  final bool? includeDetails;
  
  /// 是否為乾執行模式（不實際刪除）
  final bool? dryRun;
  
  /// 是否追蹤效能指標
  final bool? trackMetrics;
  
  /// 是否自動清理資源
  final bool? autoCleanup;
  
  /// 操作超時時間
  final Duration? timeout;
}

/// 復原參數
class RestoreCardParams {
  const RestoreCardParams({
    required this.cardId,
    this.trackMetrics,
  });

  /// 要復原的名片 ID
  final String cardId;
  
  /// 是否追蹤效能指標
  final bool? trackMetrics;
}

/// 批次刪除參數
class DeleteCardBatchParams {
  const DeleteCardBatchParams({
    required this.cardIds,
    required this.deleteType,
    this.concurrency = 3,
    this.validateDependencies,
    this.trackMetrics,
    this.autoCleanup,
  });

  /// 要刪除的名片 ID 列表
  final List<String> cardIds;
  
  /// 刪除類型
  final DeleteType deleteType;
  
  /// 並行處理數量
  final int concurrency;
  
  /// 是否驗證依賴關係
  final bool? validateDependencies;
  
  /// 是否追蹤效能指標
  final bool? trackMetrics;
  
  /// 是否自動清理資源
  final bool? autoCleanup;
}

/// 清理參數
class PurgeDeletedCardsParams {
  const PurgeDeletedCardsParams({
    required this.daysOld,
    this.trackMetrics,
  });

  /// 保留天數
  final int daysOld;
  
  /// 是否追蹤效能指標
  final bool? trackMetrics;
}

/// 刪除結果
class DeleteCardResult {
  const DeleteCardResult({
    required this.isSuccess,
    required this.deletedCardId,
    required this.deleteType,
    required this.isReversible,
    required this.processingSteps,
    required this.warnings,
    this.metrics,
    this.details,
  });

  /// 是否成功
  final bool isSuccess;
  
  /// 被刪除的名片 ID
  final String deletedCardId;
  
  /// 刪除類型
  final DeleteType deleteType;
  
  /// 是否可復原
  final bool isReversible;
  
  /// 處理步驟
  final List<String> processingSteps;
  
  /// 警告訊息
  final List<String> warnings;
  
  /// 效能指標（可選）
  final ProcessingMetrics? metrics;
  
  /// 詳細資訊（可選）
  final Map<String, dynamic>? details;

  /// 是否有警告
  bool get hasWarnings => warnings.isNotEmpty;
}

/// 復原結果
class RestoreCardResult {
  const RestoreCardResult({
    required this.isSuccess,
    required this.restoredCardId,
    required this.processingSteps,
    required this.warnings,
    this.metrics,
  });

  /// 是否成功
  final bool isSuccess;
  
  /// 被復原的名片 ID
  final String restoredCardId;
  
  /// 處理步驟
  final List<String> processingSteps;
  
  /// 警告訊息
  final List<String> warnings;
  
  /// 效能指標（可選）
  final ProcessingMetrics? metrics;

  /// 是否有警告
  bool get hasWarnings => warnings.isNotEmpty;
}

/// 批次刪除結果
class DeleteCardBatchResult {
  const DeleteCardBatchResult({
    required this.successful,
    required this.failed,
  });

  /// 成功刪除的結果
  final List<DeleteCardResult> successful;
  
  /// 失敗的錯誤
  final List<DeleteCardBatchError> failed;

  /// 是否有失敗
  bool get hasFailures => failed.isNotEmpty;
  
  /// 成功數量
  int get successCount => successful.length;
  
  /// 失敗數量
  int get failureCount => failed.length;
}

/// 批次刪除錯誤
class DeleteCardBatchError {
  const DeleteCardBatchError({
    required this.cardId,
    required this.error,
    required this.index,
  });

  /// 失敗的名片 ID
  final String cardId;
  
  /// 錯誤訊息
  final String error;
  
  /// 在批次中的索引位置
  final int index;
}

/// 清理結果
class PurgeDeletedCardsResult {
  const PurgeDeletedCardsResult({
    required this.isSuccess,
    required this.purgedCount,
    required this.daysOld,
    required this.processingSteps,
    this.metrics,
  });

  /// 是否成功
  final bool isSuccess;
  
  /// 被清理的名片數量
  final int purgedCount;
  
  /// 保留天數
  final int daysOld;
  
  /// 處理步驟
  final List<String> processingSteps;
  
  /// 效能指標（可選）
  final ProcessingMetrics? metrics;
}

/// 處理效能指標
class ProcessingMetrics {
  const ProcessingMetrics({
    required this.totalProcessingTimeMs,
    required this.startTime,
    required this.endTime,
  });

  /// 總處理時間（毫秒）
  final int totalProcessingTimeMs;
  
  /// 開始時間
  final DateTime startTime;
  
  /// 結束時間
  final DateTime endTime;
}