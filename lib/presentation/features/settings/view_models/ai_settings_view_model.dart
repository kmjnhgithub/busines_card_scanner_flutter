import 'dart:async';

import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/ai/manage_api_key_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/ai/validate_ai_service_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_settings_view_model.freezed.dart';
part 'ai_settings_view_model.g.dart';

/// 連線狀態列舉
enum ConnectionStatus {
  unknown, // 未知狀態
  connecting, // 連線中
  connected, // 已連線
  failed, // 連線失敗
}

/// 使用量統計
@freezed
class UsageStats with _$UsageStats {
  const factory UsageStats({
    required int totalRequests,
    required int totalTokens,
    required DateTime currentMonth,
    required List<DailyUsage> dailyUsage,
  }) = _UsageStats;

  factory UsageStats.fromJson(Map<String, dynamic> json) =>
      _$UsageStatsFromJson(json);
}

/// 每日使用量
@freezed
class DailyUsage with _$DailyUsage {
  const factory DailyUsage({
    required DateTime date,
    required int requests,
    required int tokens,
  }) = _DailyUsage;

  factory DailyUsage.fromJson(Map<String, dynamic> json) =>
      _$DailyUsageFromJson(json);
}

/// AI 設定頁面狀態
@freezed
class AISettingsState with _$AISettingsState {
  const factory AISettingsState({
    @Default(false) bool isLoading,
    @Default(false) bool hasApiKey,
    @Default(false) bool isApiKeyValid,
    @Default(ConnectionStatus.unknown) ConnectionStatus connectionStatus,
    UsageStats? usageStats,
    String? error,
  }) = _AISettingsState;

  factory AISettingsState.fromJson(Map<String, dynamic> json) =>
      _$AISettingsStateFromJson(json);
}

/// AI 設定頁面 ViewModel
///
/// 遵循 Clean Architecture 原則，只依賴 Domain 層的 UseCase
class AISettingsViewModel extends StateNotifier<AISettingsState> {
  final ManageApiKeyUseCase _manageApiKeyUseCase;
  final ValidateAIServiceUseCase _validateAIServiceUseCase;

  AISettingsViewModel({
    required ManageApiKeyUseCase manageApiKeyUseCase,
    required ValidateAIServiceUseCase validateAIServiceUseCase,
  }) : _manageApiKeyUseCase = manageApiKeyUseCase,
       _validateAIServiceUseCase = validateAIServiceUseCase,
       super(const AISettingsState()) {
    _initializeApiKeyStatus();
  }

  /// 初始化 API Key 狀態
  Future<void> _initializeApiKeyStatus() async {
    try {
      final result = await _manageApiKeyUseCase.hasApiKey('openai');
      result.fold(
        (failure) {
          // API Key 不存在或檢查失敗，保持初始狀態
        },
        (hasKey) {
          state = state.copyWith(hasApiKey: hasKey);
        },
      );

      // 初始化 AI 服務狀態檢查（為未來功能預留）
      unawaited(_validateAIServiceUseCase.getServiceStatus().then((statusResult) {
        statusResult.fold(
          (failure) {
            // 服務狀態檢查失敗，記錄但不影響 UI
          },
          (status) {
            // 未來可以根據服務狀態更新 UI
          },
        );
      }));
    } on Exception {
      // 忽略初始化錯誤，保持初始狀態
    }
  }

  /// 儲存 API Key
  Future<void> saveApiKey(String apiKey) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // 使用 UseCase 儲存 API Key（包含格式驗證）
      final result = await _manageApiKeyUseCase.storeApiKey('openai', apiKey);
      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: _getErrorMessage(failure),
            hasApiKey: false,
          );
        },
        (_) {
          state = state.copyWith(
            isLoading: false,
            hasApiKey: true,
            error: null,
          );
        },
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '儲存 API Key 時發生未預期錯誤：$e',
        hasApiKey: false,
      );
    }
  }

  /// 刪除 API Key
  Future<void> deleteApiKey() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await _manageApiKeyUseCase.deleteApiKey('openai');
      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: _getErrorMessage(failure),
          );
        },
        (_) {
          state = state.copyWith(
            isLoading: false,
            hasApiKey: false,
            isApiKeyValid: false,
            connectionStatus: ConnectionStatus.unknown,
            usageStats: null,
            error: null,
          );
        },
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: '刪除 API Key 時發生未預期錯誤：$e');
    }
  }

  /// 驗證 API Key
  Future<void> validateApiKey() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // 取得儲存的 API Key
      final getKeyResult = await _manageApiKeyUseCase.getApiKey('openai');
      final apiKey = getKeyResult.fold((failure) {
        state = state.copyWith(
          isLoading: false,
          error: '請先設定 API Key',
          isApiKeyValid: false,
          connectionStatus: ConnectionStatus.failed,
        );
        return null;
      }, (key) => key);

      if (apiKey == null) {
        return;
      }

      // 驗證 API Key 格式
      final validationResult = await _manageApiKeyUseCase.validateApiKeyFormat(
        'openai',
        apiKey,
      );
      validationResult.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: '連線測試失敗：${failure.userMessage}',
            isApiKeyValid: false,
            connectionStatus: ConnectionStatus.failed,
          );
        },
        (isValid) {
          if (isValid) {
            state = state.copyWith(
              isLoading: false,
              isApiKeyValid: true,
              connectionStatus: ConnectionStatus.connected,
              error: null,
            );
          } else {
            state = state.copyWith(
              isLoading: false,
              error: 'API Key 驗證失敗，請檢查是否正確',
              isApiKeyValid: false,
              connectionStatus: ConnectionStatus.failed,
            );
          }
        },
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'API Key 驗證時發生未預期錯誤：$e',
        isApiKeyValid: false,
        connectionStatus: ConnectionStatus.failed,
      );
    }
  }

  /// 載入使用量統計
  Future<void> loadUsageStats() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // 取得儲存的 API Key
      final getKeyResult = await _manageApiKeyUseCase.getApiKey('openai');
      final apiKey = getKeyResult.fold((failure) {
        state = state.copyWith(isLoading: false, error: '請先設定 API Key');
        return null;
      }, (key) => key);

      if (apiKey == null) {
        return;
      }

      // 載入使用量統計
      // TODO: 重新啟用 getUsageStats 方法當 UsageStats 移至 Domain 層後
      /*
      final statsResult = await _openAIService.getUsageStats(apiKey);
      statsResult.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: '載入使用量統計失敗：${failure.userMessage}',
          );
        },
        (stats) {
          state = state.copyWith(
            isLoading: false,
            usageStats: stats,
            error: null,
          );
        },
      );
      */
      // 暫時設為載入完成，不載入使用量統計
      state = state.copyWith(isLoading: false, error: null);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: '載入使用量統計時發生未預期錯誤：$e');
    }
  }

  /// 測試連線（綜合測試）
  Future<void> testConnection() async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        connectionStatus: ConnectionStatus.connecting,
      );

      // 先驗證 API Key
      await validateApiKey();

      // 如果驗證成功，則載入使用量統計
      if (state.isApiKeyValid &&
          state.connectionStatus == ConnectionStatus.connected) {
        await loadUsageStats();
      }
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '連線測試時發生未預期錯誤：$e',
        connectionStatus: ConnectionStatus.failed,
      );
    }
  }

  /// 清除錯誤狀態
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 取得錯誤訊息
  String _getErrorMessage(DomainFailure failure) {
    if (failure is DomainValidationFailure) {
      return failure.userMessage;
    } else if (failure is DataSourceFailure) {
      return failure.userMessage;
    } else {
      return '操作失敗：${failure.userMessage}';
    }
  }
}
