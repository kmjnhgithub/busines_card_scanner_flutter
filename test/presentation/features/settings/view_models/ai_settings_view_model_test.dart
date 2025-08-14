import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:busines_card_scanner_flutter/data/datasources/local/secure/enhanced_secure_storage.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/openai_service.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/view_models/ai_settings_view_model.dart';

// Mock classes
class MockEnhancedSecureStorage extends Mock implements EnhancedSecureStorage {}

class MockOpenAIService extends Mock implements OpenAIService {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AISettingsViewModel Tests', () {
    late MockEnhancedSecureStorage mockSecureStorage;
    late MockOpenAIService mockOpenAIService;
    late ProviderContainer container;

    setUp(() {
      mockSecureStorage = MockEnhancedSecureStorage();
      mockOpenAIService = MockOpenAIService();

      container = ProviderContainer(
        overrides: [
          aiSettingsViewModelProvider.overrideWith(
            (ref) => AISettingsViewModel(
              secureStorage: mockSecureStorage,
              openAIService: mockOpenAIService,
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('初始狀態', () {
      test('應該有正確的初始狀態', () {
        final state = container.read(aiSettingsViewModelProvider);

        expect(state.isLoading, false);
        expect(state.hasApiKey, false);
        expect(state.isApiKeyValid, false);
        expect(state.connectionStatus, ConnectionStatus.unknown);
        expect(state.usageStats, isNull);
        expect(state.error, isNull);
      });

      test('應該檢查已存在的 API Key', () async {
        // Arrange
        when(
          () => mockSecureStorage.getApiKey('openai'),
        ).thenAnswer((_) async => const Right('sk-test12345'));

        // 重新建立 container 以觸發初始化
        container.dispose();
        container = ProviderContainer(
          overrides: [
            aiSettingsViewModelProvider.overrideWith(
              (ref) => AISettingsViewModel(
                secureStorage: mockSecureStorage,
                openAIService: mockOpenAIService,
              ),
            ),
          ],
        );

        // Act - 取得 ViewModel 實例以觸發初始化
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // 等待異步初始化完成
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        final state = container.read(aiSettingsViewModelProvider);
        expect(state.hasApiKey, true);
        verify(() => mockSecureStorage.getApiKey('openai')).called(1);
      });
    });

    group('API Key 管理', () {
      test('應該成功儲存有效的 API Key', () async {
        // Arrange
        const apiKey = 'sk-proj-test123456789012345678901234567890123456';
        when(
          () => mockSecureStorage.storeApiKey('openai', apiKey),
        ).thenAnswer((_) async => const Right(null));
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.saveApiKey(apiKey);

        // Assert
        final state = viewModel.state;
        expect(state.hasApiKey, true);
        expect(state.error, isNull);
        expect(state.isLoading, false);

        verify(() => mockSecureStorage.storeApiKey('openai', apiKey)).called(1);
      });

      test('應該拒絕無效的 API Key 格式', () async {
        // Arrange
        const invalidApiKey = 'invalid-key';
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.saveApiKey(invalidApiKey);

        // Assert
        final state = viewModel.state;
        expect(state.hasApiKey, false);
        expect(state.error, isNotNull);
        expect(state.error, contains('API Key 格式無效'));

        verifyNever(() => mockSecureStorage.storeApiKey(any(), any()));
      });

      test('應該處理儲存失敗的情況', () async {
        // Arrange
        const apiKey = 'sk-proj-test123456789012345678901234567890123456';
        when(() => mockSecureStorage.storeApiKey('openai', apiKey)).thenAnswer(
          (_) async => const Left(
            DataSourceFailure(
              userMessage: '儲存失敗',
              internalMessage: 'Storage error',
            ),
          ),
        );
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.saveApiKey(apiKey);

        // Assert
        final state = viewModel.state;
        expect(state.hasApiKey, false);
        expect(state.error, isNotNull);
        expect(state.error, contains('儲存 API Key 失敗'));
      });

      test('API Key 儲存期間應該顯示載入狀態', () async {
        // Arrange
        const apiKey = 'sk-proj-test123456789012345678901234567890123456';
        when(
          () => mockSecureStorage.storeApiKey('openai', apiKey),
        ).thenAnswer((_) async => const Right(null));
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);
        bool loadingStateObserved = false;

        container.listen(aiSettingsViewModelProvider, (previous, next) {
          if (next.isLoading) {
            loadingStateObserved = true;
          }
        });

        // Act
        await viewModel.saveApiKey(apiKey);

        // Assert
        expect(loadingStateObserved, true);
      });

      test('應該成功刪除 API Key', () async {
        // Arrange
        when(
          () => mockSecureStorage.deleteApiKey('openai'),
        ).thenAnswer((_) async => const Right(null));
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.deleteApiKey();

        // Assert
        final state = viewModel.state;
        expect(state.hasApiKey, false);
        expect(state.isApiKeyValid, false);
        expect(state.connectionStatus, ConnectionStatus.unknown);
        expect(state.error, isNull);

        verify(() => mockSecureStorage.deleteApiKey('openai')).called(1);
      });

      test('應該處理刪除失敗的情況', () async {
        // Arrange
        when(() => mockSecureStorage.deleteApiKey('openai')).thenAnswer(
          (_) async => const Left(
            DataSourceFailure(
              userMessage: '刪除失敗',
              internalMessage: 'Delete error',
            ),
          ),
        );
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.deleteApiKey();

        // Assert
        final state = viewModel.state;
        expect(state.error, isNotNull);
        expect(state.error, contains('刪除 API Key 失敗'));
      });
    });

    group('API Key 驗證', () {
      test('應該成功驗證有效的 API Key', () async {
        // Arrange
        const apiKey = 'sk-proj-test123456789012345678901234567890123456';
        when(
          () => mockSecureStorage.getApiKey('openai'),
        ).thenAnswer((_) async => const Right(apiKey));
        when(
          () => mockOpenAIService.validateApiKey(apiKey),
        ).thenAnswer((_) async => const Right(true));
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.validateApiKey();

        // Assert
        final state = viewModel.state;
        expect(state.isApiKeyValid, true);
        expect(state.connectionStatus, ConnectionStatus.connected);
        expect(state.error, isNull);

        verify(() => mockOpenAIService.validateApiKey(apiKey)).called(1);
      });

      test('應該處理無效的 API Key', () async {
        // Arrange
        const apiKey = 'sk-proj-invalid123456789012345678901234567890';
        when(
          () => mockSecureStorage.getApiKey('openai'),
        ).thenAnswer((_) async => const Right(apiKey));
        when(
          () => mockOpenAIService.validateApiKey(apiKey),
        ).thenAnswer((_) async => const Right(false));
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.validateApiKey();

        // Assert
        final state = viewModel.state;
        expect(state.isApiKeyValid, false);
        expect(state.connectionStatus, ConnectionStatus.failed);
        expect(state.error, isNotNull);
        expect(state.error, contains('API Key 驗證失敗'));
      });

      test('應該處理網路連線失敗', () async {
        // Arrange
        const apiKey = 'sk-proj-test123456789012345678901234567890123456';
        when(
          () => mockSecureStorage.getApiKey('openai'),
        ).thenAnswer((_) async => const Right(apiKey));
        when(() => mockOpenAIService.validateApiKey(apiKey)).thenAnswer(
          (_) async =>
              const Left(NetworkConnectionFailure(userMessage: '網路連線失敗')),
        );
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.validateApiKey();

        // Assert
        final state = viewModel.state;
        expect(state.isApiKeyValid, false);
        expect(state.connectionStatus, ConnectionStatus.failed);
        expect(state.error, isNotNull);
        expect(state.error, contains('連線測試失敗'));
      });

      test('應該處理沒有儲存 API Key 的情況', () async {
        // Arrange
        when(() => mockSecureStorage.getApiKey('openai')).thenAnswer(
          (_) async => const Left(
            DataSourceFailure(
              userMessage: 'API key not found',
              internalMessage: 'No key stored',
            ),
          ),
        );
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.validateApiKey();

        // Assert
        final state = viewModel.state;
        expect(state.isApiKeyValid, false);
        expect(state.connectionStatus, ConnectionStatus.failed);
        expect(state.error, isNotNull);
        expect(state.error, contains('請先設定 API Key'));
      });

      test('驗證期間應該顯示載入狀態', () async {
        // Arrange
        const apiKey = 'sk-proj-test123456789012345678901234567890123456';
        when(
          () => mockSecureStorage.getApiKey('openai'),
        ).thenAnswer((_) async => const Right(apiKey));
        when(
          () => mockOpenAIService.validateApiKey(apiKey),
        ).thenAnswer((_) async => const Right(true));
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);
        bool loadingStateObserved = false;

        container.listen(aiSettingsViewModelProvider, (previous, next) {
          if (next.isLoading) {
            loadingStateObserved = true;
          }
        });

        // Act
        await viewModel.validateApiKey();

        // Assert
        expect(loadingStateObserved, true);
      });
    });

    group('使用量統計', () {
      test('應該成功載入使用量統計', () async {
        // Arrange
        const apiKey = 'sk-proj-test123456789012345678901234567890123456';
        final mockUsageStats = UsageStats(
          totalRequests: 150,
          totalTokens: 12000,
          currentMonth: DateTime.now(),
          dailyUsage: [
            DailyUsage(date: DateTime.now(), requests: 10, tokens: 800),
          ],
        );

        when(
          () => mockSecureStorage.getApiKey('openai'),
        ).thenAnswer((_) async => const Right(apiKey));
        when(
          () => mockOpenAIService.getUsageStats(apiKey),
        ).thenAnswer((_) async => Right(mockUsageStats));
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.loadUsageStats();

        // Assert
        final state = viewModel.state;
        expect(state.usageStats, isNotNull);
        expect(state.usageStats!.totalRequests, 150);
        expect(state.usageStats!.totalTokens, 12000);
        expect(state.error, isNull);

        verify(() => mockOpenAIService.getUsageStats(apiKey)).called(1);
      });

      test('應該處理載入使用量統計失敗', () async {
        // Arrange
        const apiKey = 'sk-proj-test123456789012345678901234567890123456';
        when(
          () => mockSecureStorage.getApiKey('openai'),
        ).thenAnswer((_) async => const Right(apiKey));
        when(() => mockOpenAIService.getUsageStats(apiKey)).thenAnswer(
          (_) async =>
              const Left(NetworkConnectionFailure(userMessage: '載入失敗')),
        );
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.loadUsageStats();

        // Assert
        final state = viewModel.state;
        expect(state.usageStats, isNull);
        expect(state.error, isNotNull);
        expect(state.error, contains('載入使用量統計失敗'));
      });

      test('載入使用量統計期間應該顯示載入狀態', () async {
        // Arrange
        const apiKey = 'sk-proj-test123456789012345678901234567890123456';
        final mockUsageStats = UsageStats(
          totalRequests: 150,
          totalTokens: 12000,
          currentMonth: DateTime.now(),
          dailyUsage: [],
        );

        when(
          () => mockSecureStorage.getApiKey('openai'),
        ).thenAnswer((_) async => const Right(apiKey));
        when(
          () => mockOpenAIService.getUsageStats(apiKey),
        ).thenAnswer((_) async => Right(mockUsageStats));
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);
        bool loadingStateObserved = false;

        container.listen(aiSettingsViewModelProvider, (previous, next) {
          if (next.isLoading) {
            loadingStateObserved = true;
          }
        });

        // Act
        await viewModel.loadUsageStats();

        // Assert
        expect(loadingStateObserved, true);
      });
    });

    group('綜合測試連線', () {
      test('應該成功完成完整的連線測試', () async {
        // Arrange
        const apiKey = 'sk-proj-test123456789012345678901234567890123456';
        final mockUsageStats = UsageStats(
          totalRequests: 100,
          totalTokens: 8000,
          currentMonth: DateTime.now(),
          dailyUsage: [],
        );

        when(
          () => mockSecureStorage.getApiKey('openai'),
        ).thenAnswer((_) async => const Right(apiKey));
        when(
          () => mockOpenAIService.validateApiKey(apiKey),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => mockOpenAIService.getUsageStats(apiKey),
        ).thenAnswer((_) async => Right(mockUsageStats));
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.testConnection();

        // Assert
        final state = viewModel.state;
        expect(state.isApiKeyValid, true);
        expect(state.connectionStatus, ConnectionStatus.connected);
        expect(state.usageStats, isNotNull);
        expect(state.error, isNull);

        verify(() => mockOpenAIService.validateApiKey(apiKey)).called(1);
        verify(() => mockOpenAIService.getUsageStats(apiKey)).called(1);
      });

      test('連線測試失敗時應該停止後續操作', () async {
        // Arrange
        const apiKey = 'sk-proj-test123456789012345678901234567890123456';
        when(
          () => mockSecureStorage.getApiKey('openai'),
        ).thenAnswer((_) async => const Right(apiKey));
        when(
          () => mockOpenAIService.validateApiKey(apiKey),
        ).thenAnswer((_) async => const Right(false));
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.testConnection();

        // Assert
        final state = viewModel.state;
        expect(state.isApiKeyValid, false);
        expect(state.connectionStatus, ConnectionStatus.failed);
        expect(state.usageStats, isNull);

        verify(() => mockOpenAIService.validateApiKey(apiKey)).called(1);
        verifyNever(() => mockOpenAIService.getUsageStats(any()));
      });
    });

    group('錯誤處理', () {
      test('應該能清除錯誤狀態', () async {
        // Arrange
        when(() => mockSecureStorage.deleteApiKey('openai')).thenAnswer(
          (_) async => const Left(
            DataSourceFailure(
              userMessage: '測試錯誤',
              internalMessage: 'Test error',
            ),
          ),
        );
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // 產生錯誤
        await viewModel.deleteApiKey();
        expect(viewModel.state.error, isNotNull);

        // Act
        viewModel.clearError();

        // Assert
        final state = viewModel.state;
        expect(state.error, isNull);
      });
    });

    group('邊界條件測試', () {
      test('應該處理空的 API Key', () async {
        // Arrange
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.saveApiKey('');

        // Assert
        final state = viewModel.state;
        expect(state.hasApiKey, false);
        expect(state.error, isNotNull);
        expect(state.error, contains('API Key 不能為空'));
      });

      test('應該處理過短的 API Key', () async {
        // Arrange
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.saveApiKey('sk-123');

        // Assert
        final state = viewModel.state;
        expect(state.hasApiKey, false);
        expect(state.error, isNotNull);
        expect(state.error, contains('API Key 格式無效'));
      });

      test('應該處理包含無效字符的 API Key', () async {
        // Arrange
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act
        await viewModel.saveApiKey('sk-test@invalid-chars');

        // Assert
        final state = viewModel.state;
        expect(state.hasApiKey, false);
        expect(state.error, isNotNull);
        expect(state.error, contains('API Key 格式無效'));
      });

      test('同時進行多個操作時應該正確處理', () async {
        // Arrange
        const apiKey = 'sk-proj-test123456789012345678901234567890123456';
        when(
          () => mockSecureStorage.storeApiKey('openai', apiKey),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockSecureStorage.getApiKey('openai'),
        ).thenAnswer((_) async => const Right(apiKey));
        when(
          () => mockOpenAIService.validateApiKey(apiKey),
        ).thenAnswer((_) async => const Right(true));
        final viewModel = container.read(aiSettingsViewModelProvider.notifier);

        // Act - 同時執行多個操作
        final futures = [
          viewModel.saveApiKey(apiKey),
          viewModel.validateApiKey(),
        ];

        await Future.wait(futures);

        // Assert
        final state = viewModel.state;
        expect(state.hasApiKey, true);
        expect(state.isApiKeyValid, true);
        expect(state.error, isNull);
      });
    });
  });
}
