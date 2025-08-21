import 'package:busines_card_scanner_flutter/domain/usecases/ai/manage_api_key_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/ai/validate_ai_service_usecase.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/pages/ai_settings_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/providers/settings_providers.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/view_models/ai_settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mock 類別
class MockManageApiKeyUseCase extends Mock implements ManageApiKeyUseCase {}
class MockValidateAIServiceUseCase extends Mock implements ValidateAIServiceUseCase {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AISettingsPage Integration Tests', () {
    late MockManageApiKeyUseCase mockManageApiKeyUseCase;
    late MockValidateAIServiceUseCase mockValidateAIServiceUseCase;

    setUp(() {
      mockManageApiKeyUseCase = MockManageApiKeyUseCase();
      mockValidateAIServiceUseCase = MockValidateAIServiceUseCase();
    });

    testWidgets('AISettingsPage 應該能正常顯示和渲染', (WidgetTester tester) async {
      // 創建真實的 ViewModel 實例
      final viewModel = AISettingsViewModel(
        manageApiKeyUseCase: mockManageApiKeyUseCase,
        validateAIServiceUseCase: mockValidateAIServiceUseCase,
      );

      // 包裝在 MaterialApp 和 ProviderScope 中
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiSettingsViewModelProvider.overrideWith((ref) => viewModel),
          ],
          child: const MaterialApp(
            home: AISettingsPage(),
          ),
        ),
      );

      // 等待頁面載入
      await tester.pumpAndSettle();

      // 驗證基本元件存在
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('AI 設定'), findsOneWidget);

      // 驗證主要功能區塊
      expect(find.text('API Key 管理'), findsOneWidget);
      expect(find.text('連線測試'), findsOneWidget);
      expect(find.text('使用量統計'), findsOneWidget);
      expect(find.textContaining('如何取得 API Key'), findsOneWidget);

      // 驗證按鈕存在
      expect(find.text('儲存'), findsOneWidget);
      expect(find.text('刪除'), findsOneWidget);
      expect(find.text('測試連線'), findsOneWidget);
      expect(find.text('重新整理'), findsOneWidget);
    });
  });
}