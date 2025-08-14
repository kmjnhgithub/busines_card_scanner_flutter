import 'package:busines_card_scanner_flutter/data/datasources/local/secure/enhanced_secure_storage.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/openai_service.dart';
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
class AISettingsViewModel extends StateNotifier<AISettingsState> {
  final EnhancedSecureStorage _secureStorage;
  final OpenAIService _openAIService;

  AISettingsViewModel({
    required EnhancedSecureStorage secureStorage,
    required OpenAIService openAIService,
  }) : _secureStorage = secureStorage,
       _openAIService = openAIService,
       super(const AISettingsState()) {
    _initializeApiKeyStatus();
  }

  /// 初始化 API Key 狀態
  Future<void> _initializeApiKeyStatus() async {
    try {
      final result = await _secureStorage.getApiKey('openai');
      result.fold(
        (failure) {
          // API Key 不存在，保持初始狀態
        },
        (apiKey) {
          state = state.copyWith(hasApiKey: true);
        },
      );
    } on Exception {
      // 忽略初始化錯誤，保持初始狀態
    }
  }

  /// 儲存 API Key
  Future<void> saveApiKey(String apiKey) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // 驗證 API Key 格式
      final validationError = _validateApiKeyFormat(apiKey);
      if (validationError != null) {
        state = state.copyWith(
          isLoading: false,
          error: validationError,
          hasApiKey: false,
        );
        return;
      }

      // 儲存 API Key
      final result = await _secureStorage.storeApiKey('openai', apiKey);
      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: '儲存 API Key 失敗：${failure.userMessage}',
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

      final result = await _secureStorage.deleteApiKey('openai');
      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: '刪除 API Key 失敗：${failure.userMessage}',
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
      final getKeyResult = await _secureStorage.getApiKey('openai');
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

      // 驗證 API Key
      final validationResult = await _openAIService.validateApiKey(apiKey);
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
      final getKeyResult = await _secureStorage.getApiKey('openai');
      final apiKey = getKeyResult.fold((failure) {
        state = state.copyWith(isLoading: false, error: '請先設定 API Key');
        return null;
      }, (key) => key);

      if (apiKey == null) {
        return;
      }

      // 載入使用量統計
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

  /// 驗證 API Key 格式
  String? _validateApiKeyFormat(String apiKey) {
    if (apiKey.isEmpty) {
      return 'API Key 不能為空';
    }

    if (apiKey.length < 20) {
      return 'API Key 格式無效：長度太短';
    }

    // OpenAI API Key 格式檢查
    if (!apiKey.startsWith('sk-')) {
      return 'API Key 格式無效：必須以 sk- 開頭';
    }

    // 檢查是否只包含有效字符（字母、數字、連字號、底線）
    if (!RegExp(r'^sk-[a-zA-Z0-9\-_]+$').hasMatch(apiKey)) {
      return 'API Key 格式無效：包含無效字符';
    }

    return null;
  }
}

/// AISettingsViewModel Provider
final aiSettingsViewModelProvider =
    StateNotifierProvider<AISettingsViewModel, AISettingsState>(
      (ref) => throw UnimplementedError(
        'AISettingsViewModel provider must be overridden',
      ),
    );
