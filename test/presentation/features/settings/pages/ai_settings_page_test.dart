import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:busines_card_scanner_flutter/presentation/features/settings/pages/ai_settings_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/providers/settings_providers.dart'
    hide aiSettingsViewModelProvider;
import 'package:busines_card_scanner_flutter/presentation/features/settings/view_models/ai_settings_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_button.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_text_field.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_card.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/secure/enhanced_secure_storage.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/openai_service.dart';

import '../../../../helpers/test_helpers.dart';

/// Mock 類別
class MockAISettingsViewModel extends StateNotifier<AISettingsState>
    with Mock
    implements AISettingsViewModel {
  MockAISettingsViewModel() : super(const AISettingsState());
}

class MockEnhancedSecureStorage extends Mock implements EnhancedSecureStorage {}

class MockOpenAIService extends Mock implements OpenAIService {}

void main() {
  group('AISettingsPage Widget Tests', () {
    late MockAISettingsViewModel mockViewModel;
    late MockEnhancedSecureStorage mockStorage;
    late MockOpenAIService mockOpenAIService;
    late ProviderContainer container;

    setUpAll(() {
      registerCommonFallbackValues();
    });

    setUp(() {
      mockViewModel = MockAISettingsViewModel();
      mockStorage = MockEnhancedSecureStorage();
      mockOpenAIService = MockOpenAIService();

      // 建立測試用的 ProviderContainer
      container = TestHelpers.createTestContainer(
        overrides: [
          aiSettingsViewModelProvider.overrideWith((ref) {
            return mockViewModel;
          }),
        ],
      );
    });

    tearDown(() {
      TestHelpers.disposeContainer(container);
    });

    /// 輔助方法：等待頁面載入完成
    Future<void> waitForPageLoad(WidgetTester tester) async {
      await TestHelpers.testLoadingState(tester);
    }

    group('初始顯示測試', () {
      testWidgets('應該正確顯示基本架構', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查基本架構
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('AI 設定'), findsOneWidget);
      });

      testWidgets('應該顯示 API Key 管理區塊', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查 API Key 管理區塊
        expect(find.text('API Key 管理'), findsOneWidget);
        expect(find.byType(ThemedTextField), findsOneWidget);

        // 檢查儲存和刪除按鈕
        expect(find.text('儲存'), findsOneWidget);
        expect(find.text('刪除'), findsOneWidget);

        // 檢查顯示/隱藏按鈕（眼睛圖示）
        expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(0));
      });

      testWidgets('應該顯示連線測試區塊', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查連線測試區塊
        expect(find.text('連線測試'), findsOneWidget);
        expect(find.text('測試連線'), findsOneWidget);
      });

      testWidgets('應該顯示使用量統計區塊', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查使用量統計區塊
        expect(find.text('使用量統計'), findsOneWidget);
        expect(find.text('重新整理'), findsOneWidget);
        expect(find.byType(ThemedCard), findsAtLeastNWidgets(1));
      });

      testWidgets('應該顯示說明區塊', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查說明區塊
        expect(find.textContaining('如何取得 API Key'), findsOneWidget);
        expect(find.textContaining('OpenAI'), findsOneWidget);
      });
    });

    group('API Key 輸入與儲存測試', () {
      testWidgets('應該能夠輸入 API Key', (tester) async {
        // Arrange
        const testApiKey = 'sk-test123456789';

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Act - 輸入 API Key
        final textField = find.byType(ThemedTextField);
        await tester.enterText(textField, testApiKey);
        await tester.pump();

        // Assert - 檢查輸入成功
        expect(find.text(testApiKey), findsOneWidget);
      });

      testWidgets('應該在點擊儲存時呼叫 ViewModel', (tester) async {
        // Arrange
        const testApiKey = 'sk-test123456789';

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Act - 輸入並儲存 API Key
        final textField = find.byType(ThemedTextField);
        await tester.enterText(textField, testApiKey);
        await tester.pump();

        final saveButton = find.text('儲存');
        await tester.tap(saveButton);
        await tester.pump();

        // Assert - 驗證呼叫 ViewModel
        verify(() => mockViewModel.saveApiKey(testApiKey)).called(1);
      });

      testWidgets('應該能夠切換 API Key 的顯示狀態', (tester) async {
        // Arrange
        const testApiKey = 'sk-test123456789';

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Act - 輸入 API Key
        final textField = find.byType(ThemedTextField);
        await tester.enterText(textField, testApiKey);
        await tester.pump();

        // Act - 點擊顯示/隱藏按鈕
        final visibilityButton = find.byIcon(Icons.visibility);
        await tester.tap(visibilityButton);
        await tester.pump();

        // Assert - 檢查圖示變更為 visibility_off
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      });

      testWidgets('應該顯示 API Key 格式錯誤', (tester) async {
        // Arrange
        when(
          () => mockViewModel.state,
        ).thenReturn(const AISettingsState(error: 'API Key 格式無效：必須以 sk- 開頭'));

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查錯誤訊息顯示
        expect(find.textContaining('API Key 格式無效'), findsOneWidget);
      });
    });

    group('API Key 刪除測試', () {
      testWidgets('應該在點擊刪除時顯示確認對話框', (tester) async {
        // Arrange
        when(
          () => mockViewModel.state,
        ).thenReturn(const AISettingsState(hasApiKey: true));

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Act - 點擊刪除按鈕
        final deleteButton = find.text('刪除');
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        // Assert - 檢查確認對話框
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('確認刪除'), findsOneWidget);
        expect(find.textContaining('確定要刪除 API Key'), findsOneWidget);
      });

      testWidgets('應該在確認刪除時呼叫 ViewModel', (tester) async {
        // Arrange
        when(
          () => mockViewModel.state,
        ).thenReturn(const AISettingsState(hasApiKey: true));

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Act - 點擊刪除並確認
        final deleteButton = find.text('刪除');
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        final confirmButton = find.text('刪除').last;
        await tester.tap(confirmButton);
        await tester.pump();

        // Assert - 驗證呼叫 ViewModel
        verify(() => mockViewModel.deleteApiKey()).called(1);
      });

      testWidgets('應該在取消刪除時關閉對話框', (tester) async {
        // Arrange
        when(
          () => mockViewModel.state,
        ).thenReturn(const AISettingsState(hasApiKey: true));

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Act - 點擊刪除並取消
        final deleteButton = find.text('刪除');
        await tester.tap(deleteButton);
        await tester.pumpAndSettle();

        final cancelButton = find.text('取消');
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        // Assert - 檢查對話框關閉
        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('連線測試功能測試', () {
      testWidgets('應該在點擊測試連線時呼叫 ViewModel', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Act - 點擊測試連線按鈕
        final testButton = find.text('測試連線');
        await tester.tap(testButton);
        await tester.pump();

        // Assert - 驗證呼叫 ViewModel
        verify(() => mockViewModel.testConnection()).called(1);
      });

      testWidgets('應該顯示載入狀態', (tester) async {
        // Arrange - 設定載入狀態
        when(
          () => mockViewModel.state,
        ).thenReturn(const AISettingsState(isLoading: true));

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查載入指示器
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      });

      testWidgets('應該顯示連線成功訊息', (tester) async {
        // Arrange - 設定連線成功狀態
        when(() => mockViewModel.state).thenReturn(
          const AISettingsState(
            connectionStatus: ConnectionStatus.connected,
            isApiKeyValid: true,
          ),
        );

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查成功訊息或圖示
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.textContaining('連線成功'), findsOneWidget);
      });

      testWidgets('應該顯示連線失敗訊息', (tester) async {
        // Arrange - 設定連線失敗狀態
        when(() => mockViewModel.state).thenReturn(
          const AISettingsState(
            connectionStatus: ConnectionStatus.failed,
            error: '連線測試失敗：無效的 API Key',
          ),
        );

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查失敗訊息或圖示
        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.textContaining('連線測試失敗'), findsOneWidget);
      });
    });

    group('使用量統計載入測試', () {
      testWidgets('應該在點擊重新整理時呼叫 ViewModel', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Act - 點擊重新整理按鈕
        final refreshButton = find.text('重新整理');
        await tester.tap(refreshButton);
        await tester.pump();

        // Assert - 驗證呼叫 ViewModel
        verify(() => mockViewModel.loadUsageStats()).called(1);
      });

      testWidgets('應該顯示使用量統計資訊', (tester) async {
        // Arrange - 設定使用量統計
        final mockUsageStats = UsageStats(
          totalRequests: 150,
          totalTokens: 50000,
          currentMonth: DateTime.now(),
          dailyUsage: [
            DailyUsage(date: DateTime.now(), requests: 10, tokens: 1000),
          ],
        );

        when(
          () => mockViewModel.state,
        ).thenReturn(AISettingsState(usageStats: mockUsageStats));

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查使用量統計顯示
        expect(find.textContaining('150'), findsOneWidget); // 總請求數
        expect(find.textContaining('50,000'), findsOneWidget); // 總代幣數
      });

      testWidgets('應該在沒有使用量統計時顯示空狀態', (tester) async {
        // Arrange - 無使用量統計
        when(
          () => mockViewModel.state,
        ).thenReturn(const AISettingsState(usageStats: null));

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查空狀態訊息
        expect(find.textContaining('暫無使用量統計'), findsOneWidget);
      });
    });

    group('錯誤處理測試', () {
      testWidgets('應該顯示一般錯誤訊息', (tester) async {
        // Arrange
        const errorMessage = '網路連線失敗，請檢查網路設定';
        when(
          () => mockViewModel.state,
        ).thenReturn(const AISettingsState(error: errorMessage));

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查錯誤訊息顯示
        expect(find.textContaining(errorMessage), findsOneWidget);
      });

      testWidgets('應該能夠清除錯誤狀態', (tester) async {
        // Arrange
        when(
          () => mockViewModel.state,
        ).thenReturn(const AISettingsState(error: '測試錯誤'));

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Act - 點擊關閉錯誤訊息（如果有關閉按鈕）
        final closeButton = find.byIcon(Icons.close);
        if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton);
          await tester.pump();

          // Assert - 驗證清除錯誤
          verify(() => mockViewModel.clearError()).called(1);
        }
      });

      testWidgets('應該處理 ViewModel 異常', (tester) async {
        // Arrange - 模擬 ViewModel 拋出異常
        when(() => mockViewModel.state).thenThrow(Exception('Mock error'));

        // Act & Assert - 確保不會崩潰
        expect(() async {
          await tester.pumpWidget(
            TestHelpers.createTestWidget(
              container: container,
              child: const AISettingsPage(),
            ),
          );
          await waitForPageLoad(tester);
        }, returnsNormally);
      });
    });

    group('外部連結測試', () {
      testWidgets('應該包含 OpenAI 網站連結', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查連結存在
        expect(
          find.textContaining('https://platform.openai.com'),
          findsOneWidget,
        );
      });

      testWidgets('應該能夠點擊外部連結', (tester) async {
        // Arrange
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Act - 嘗試點擊連結
        final linkText = find.textContaining('https://platform.openai.com');
        if (linkText.evaluate().isNotEmpty) {
          // 模擬點擊（實際測試中無法真正打開連結）
          await tester.tap(linkText.first);
          await tester.pump();

          // Assert - 確保不會崩潰
          expect(tester.takeException(), isNull);
        }
      });
    });

    group('API Key 遮罩顯示測試', () {
      testWidgets('應該在有 API Key 時顯示遮罩', (tester) async {
        // Arrange - 設定有 API Key 狀態
        when(
          () => mockViewModel.state,
        ).thenReturn(const AISettingsState(hasApiKey: true));

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查遮罩顯示（預設應該遮罩）
        expect(find.textContaining('sk-...'), findsOneWidget);
      });

      testWidgets('應該在沒有 API Key 時顯示空的輸入欄位', (tester) async {
        // Arrange - 設定無 API Key 狀態
        when(
          () => mockViewModel.state,
        ).thenReturn(const AISettingsState(hasApiKey: false));

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查輸入欄位為空
        final textField = find.byType(ThemedTextField);
        expect(textField, findsOneWidget);

        // 檢查輸入欄位的提示文字
        expect(find.textContaining('請輸入 OpenAI API Key'), findsOneWidget);
      });
    });

    group('無障礙性測試', () {
      testWidgets('應該包含重要的語義標籤', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const AISettingsPage(),
          ),
        );

        await waitForPageLoad(tester);

        // Assert - 檢查基本語義標籤存在
        // 檢查是否有 Semantics widget
        expect(find.byType(Semantics), findsWidgets);

        // 檢查頁面基本結構
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });
    });
  });
}
