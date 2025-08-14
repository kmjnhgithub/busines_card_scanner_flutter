import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:busines_card_scanner_flutter/presentation/features/settings/pages/ai_settings_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/view_models/ai_settings_view_model.dart';

import '../../../../helpers/test_helpers.dart';

/// 簡化版的 Mock ViewModel（不使用 Mock 套件）
class TestAISettingsViewModel extends AISettingsViewModel {
  TestAISettingsViewModel() : super(
    secureStorage: throw UnimplementedError(),
    openAIService: throw UnimplementedError(),
  );
  
  @override
  AISettingsState get state => const AISettingsState();
  
  @override
  Future<void> saveApiKey(String apiKey) async {}
  
  @override
  Future<void> deleteApiKey() async {}
  
  @override
  Future<void> validateApiKey() async {}
  
  @override
  Future<void> loadUsageStats() async {}
  
  @override
  Future<void> testConnection() async {}
  
  @override
  void clearError() {}
}

void main() {
  group('AISettingsPage Simple Tests', () {
    late ProviderContainer container;
    late TestAISettingsViewModel testViewModel;

    setUpAll(() {
      registerCommonFallbackValues();
    });

    setUp(() {
      testViewModel = TestAISettingsViewModel();

      // 建立測試用的 ProviderContainer
      container = TestHelpers.createTestContainer(
        overrides: [
          aiSettingsViewModelProvider.overrideWith((ref) => testViewModel),
        ],
      );
    });

    tearDown(() {
      TestHelpers.disposeContainer(container);
    });

    testWidgets('應該能夠正確顯示頁面基本結構', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        TestHelpers.createTestWidget(
          container: container,
          child: const AISettingsPage(),
        ),
      );

      await TestHelpers.testLoadingState(tester);

      // Assert - 檢查基本結構
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('AI 設定'), findsOneWidget);
      
      // 檢查主要區塊標題
      expect(find.text('API Key 管理'), findsOneWidget);
      expect(find.text('連線測試'), findsOneWidget);
      expect(find.text('使用量統計'), findsOneWidget);
      expect(find.textContaining('如何取得 API Key'), findsOneWidget);
    });

    testWidgets('應該顯示基本的按鈕和輸入元件', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        TestHelpers.createTestWidget(
          container: container,
          child: const AISettingsPage(),
        ),
      );

      await TestHelpers.testLoadingState(tester);

      // Assert - 檢查基本元件存在
      expect(find.text('儲存'), findsOneWidget);
      expect(find.text('刪除'), findsOneWidget);
      expect(find.text('測試連線'), findsOneWidget);
      expect(find.text('重新整理'), findsOneWidget);
      expect(find.textContaining('前往 OpenAI 平台'), findsOneWidget);
    });
  });
}