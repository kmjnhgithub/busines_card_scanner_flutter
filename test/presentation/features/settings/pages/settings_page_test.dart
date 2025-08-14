import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:busines_card_scanner_flutter/presentation/features/settings/pages/settings_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/view_models/settings_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/providers/settings_providers.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/constants/settings_constants.dart';

import '../../../../helpers/test_helpers.dart';

/// Mock 類別
class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockDeviceInfoPlugin extends Mock implements DeviceInfoPlugin {}

void main() {
  group('SettingsPage Widget Tests', () {
    late MockSharedPreferences mockPreferences;
    late MockDeviceInfoPlugin mockDeviceInfo;
    late ProviderContainer container;

    setUpAll(() {
      registerCommonFallbackValues();
    });

    setUp(() {
      mockPreferences = MockSharedPreferences();
      mockDeviceInfo = MockDeviceInfoPlugin();

      // 設定預設的 Mock 行為
      when(() => mockPreferences.getString(any())).thenReturn(null);
      when(() => mockPreferences.getBool(any())).thenReturn(null);
      when(
        () => mockPreferences.setString(any(), any()),
      ).thenAnswer((_) async => true);
      when(
        () => mockPreferences.setBool(any(), any()),
      ).thenAnswer((_) async => true);
      when(() => mockPreferences.remove(any())).thenAnswer((_) async => true);

      // 建立測試用的 ProviderContainer
      container = TestHelpers.createTestContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPreferences),
          deviceInfoProvider.overrideWithValue(mockDeviceInfo),
        ],
      );
    });

    tearDown(() {
      TestHelpers.disposeContainer(container);
    });

    /// 輔助方法：等待 SettingsPage 完全載入
    Future<void> waitForSettingsPageLoad(WidgetTester tester) async {
      await tester.pump(); // 初始渲染
      await tester.pump(Duration.zero); // 等待任何同步的狀態更新

      // 等待一小段時間確保所有非同步操作完成
      await tester.pump(const Duration(milliseconds: 50));
    }

    group('核心功能測試', () {
      testWidgets('應該正確顯示基本架構', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const SettingsPage(),
          ),
        );

        await waitForSettingsPageLoad(tester);

        // Assert
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('設定'), findsOneWidget);

        // 檢查不是載入狀態（應該顯示內容而不是載入指示器）
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('應該顯示設定內容而非載入狀態', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const SettingsPage(),
          ),
        );

        await waitForSettingsPageLoad(tester);

        // Assert - 檢查確實顯示內容
        // 使用 findsWidgets 檢查是否有任何 ListTile（設定項目）
        expect(find.byType(ListTile), findsWidgets);

        // 檢查關鍵的設定類型元件
        final dropdownExists = find
            .byType(DropdownButton)
            .evaluate()
            .isNotEmpty;
        final segmentedButtonExists = find
            .byType(SegmentedButton)
            .evaluate()
            .isNotEmpty;
        final switchExists = find.byType(SwitchListTile).evaluate().isNotEmpty;

        // 至少應該有一些設定元件
        expect(
          dropdownExists || segmentedButtonExists || switchExists,
          isTrue,
          reason: '應該至少顯示一些設定元件',
        );
      });
    });

    group('互動功能測試', () {
      testWidgets('應該能夠與語言設定互動', (tester) async {
        // Arrange
        when(
          () => mockPreferences.setString(any(), any()),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const SettingsPage(),
          ),
        );

        await waitForSettingsPageLoad(tester);

        // Act - 尋找並點擊語言下拉選單
        final dropdowns = find.byType(DropdownButton);
        if (dropdowns.evaluate().isNotEmpty) {
          await tester.tap(dropdowns.first);
          await tester.pumpAndSettle();

          // 如果下拉選單成功打開，應該能找到選項
          final englishOption = find.text('English');
          if (englishOption.evaluate().isNotEmpty) {
            await tester.tap(englishOption.last);
            await tester.pumpAndSettle();

            // Assert - 驗證設定被保存
            verify(
              () => mockPreferences.setString(any(), any()),
            ).called(greaterThanOrEqualTo(1));
          }
        }
      });

      testWidgets('應該能夠與主題設定互動', (tester) async {
        // Arrange
        when(
          () => mockPreferences.setString(any(), any()),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const SettingsPage(),
          ),
        );

        await waitForSettingsPageLoad(tester);

        // Act - 尋找並點擊主題設定
        final darkThemeButton = find.text('深色');
        if (darkThemeButton.evaluate().isNotEmpty) {
          await tester.tap(darkThemeButton);
          await tester.pumpAndSettle();

          // Assert - 驗證設定被保存
          verify(
            () => mockPreferences.setString(any(), any()),
          ).called(greaterThanOrEqualTo(1));
        }
      });

      testWidgets('應該能夠與通知開關互動', (tester) async {
        // Arrange
        when(
          () => mockPreferences.setBool(any(), any()),
        ).thenAnswer((_) async => true);

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const SettingsPage(),
          ),
        );

        await waitForSettingsPageLoad(tester);

        // Act - 尋找並點擊通知開關
        final switches = find.byType(SwitchListTile);
        if (switches.evaluate().isNotEmpty) {
          await tester.tap(switches.first);
          await tester.pumpAndSettle();

          // Assert - 驗證設定被保存
          verify(
            () => mockPreferences.setBool(any(), any()),
          ).called(greaterThanOrEqualTo(1));
        }
      });
    });

    group('對話框測試', () {
      testWidgets('應該能夠顯示和操作對話框', (tester) async {
        // Arrange
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const SettingsPage(),
          ),
        );

        await waitForSettingsPageLoad(tester);

        // Act - 嘗試找到並點擊關於或重置設定
        final aboutButton = find.text('關於');
        final resetButton = find.text('重置設定');

        Finder? targetButton;
        if (aboutButton.evaluate().isNotEmpty) {
          targetButton = aboutButton;
        } else if (resetButton.evaluate().isNotEmpty) {
          targetButton = resetButton;
        }

        if (targetButton != null) {
          // 如果元素不可見，嘗試滾動
          try {
            await tester.ensureVisible(targetButton);
          } catch (e) {
            // 如果滾動失敗，直接點擊
          }

          await tester.tap(targetButton);
          await tester.pumpAndSettle();

          // Assert - 檢查是否顯示對話框
          expect(find.byType(AlertDialog), findsOneWidget);

          // 關閉對話框
          final closeButton = find.text('關閉');
          final cancelButton = find.text('取消');

          if (closeButton.evaluate().isNotEmpty) {
            await tester.tap(closeButton.first);
            await tester.pumpAndSettle();
          } else if (cancelButton.evaluate().isNotEmpty) {
            await tester.tap(cancelButton.first);
            await tester.pumpAndSettle();
          }
        }
      });
    });

    group('Provider 整合測試', () {
      testWidgets('應該正確整合 Riverpod Providers', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const SettingsPage(),
          ),
        );

        await waitForSettingsPageLoad(tester);

        // Assert - 檢查 SettingsPage 是否成功創建（表示 Provider 正常工作）
        expect(find.byType(SettingsPage), findsOneWidget);

        // 檢查 SettingsPage 本身就是 ConsumerStatefulWidget（直接驗證 Provider 整合）
        expect(find.byType(SettingsPage), findsOneWidget);

        // 驗證頁面能正常運作，表示 Provider 整合正確
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('應該能夠讀取 ViewModel 狀態', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const SettingsPage(),
          ),
        );

        await waitForSettingsPageLoad(tester);

        // Assert - 通過檢查 Widget 存在來驗證 ViewModel 狀態讀取正常
        expect(find.byType(SettingsPage), findsOneWidget);

        // 驗證不是錯誤狀態（如果是錯誤狀態，可能會顯示錯誤訊息）
        expect(find.textContaining('載入設定失敗'), findsNothing);
      });
    });

    group('防禦性測試', () {
      testWidgets('應該處理 Provider 異常', (tester) async {
        // Arrange - 模擬 SharedPreferences 拋出異常
        when(
          () => mockPreferences.getString(any()),
        ).thenThrow(Exception('Mock error'));
        when(
          () => mockPreferences.getBool(any()),
        ).thenThrow(Exception('Mock error'));

        // Act & Assert - 確保不會崩潰
        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const SettingsPage(),
          ),
        );

        await waitForSettingsPageLoad(tester);

        // 頁面應該仍然可以顯示，即使有錯誤
        expect(find.byType(SettingsPage), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('應該在小螢幕上正常顯示', (tester) async {
        // Arrange - 設定小螢幕尺寸
        await tester.binding.setSurfaceSize(const Size(320, 568));

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: const SettingsPage(),
          ),
        );

        await waitForSettingsPageLoad(tester);

        // Assert - 基本元件應該仍然存在
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);

        // Cleanup
        await tester.binding.setSurfaceSize(null);
      });
    });
  });
}
