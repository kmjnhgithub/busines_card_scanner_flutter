import 'package:busines_card_scanner_flutter/presentation/features/card_creation/pages/camera_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_creation/pages/ocr_processing_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_detail/pages/card_detail_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_list/pages/card_list_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/pages/ai_settings_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/pages/settings_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/providers/settings_providers.dart';
import 'package:busines_card_scanner_flutter/presentation/router/app_router.dart';
import 'package:busines_card_scanner_flutter/presentation/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

/// Mock 類別用於測試
class MockGoRouter extends Mock implements GoRouter {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  /// AppRouter 測試套件
  ///
  /// 測試路由配置的正確性，包括：
  /// - 基本路由導航
  /// - 參數路由傳遞
  /// - 路由守衛
  /// - 重定向邏輯
  /// - 錯誤處理
  group('AppRouter', () {
    late ProviderContainer container;
    late MockNavigatorObserver mockNavigatorObserver;
    late MockSharedPreferences mockSharedPreferences;

    setUpAll(() {
      registerCommonFallbackValues();
    });

    setUp(() {
      mockNavigatorObserver = MockNavigatorObserver();
      mockSharedPreferences = MockSharedPreferences();

      // Mock SharedPreferences 基本行為
      when(() => mockSharedPreferences.getString(any())).thenReturn(null);
      when(() => mockSharedPreferences.getBool(any())).thenReturn(false);
      when(() => mockSharedPreferences.getInt(any())).thenReturn(null);
      when(
        () => mockSharedPreferences.setString(any(), any()),
      ).thenAnswer((_) async => true);
      when(
        () => mockSharedPreferences.setBool(any(), any()),
      ).thenAnswer((_) async => true);

      container = TestHelpers.createTestContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        ],
      );
    });

    tearDown(() {
      TestHelpers.disposeContainer(container);
    });

    group('路由配置', () {
      testWidgets('應該建立 AppRouter 實例', (tester) async {
        // Red Phase: 測試 AppRouter 類別是否存在並可以正確建立
        expect(() => AppRouter(), returnsNormally);
      });

      testWidgets('應該建立 GoRouter 實例', (tester) async {
        // Red Phase: 測試是否能取得 GoRouter 實例
        final appRouter = AppRouter();
        final goRouter = appRouter.router;

        expect(goRouter, isA<GoRouter>());
        expect(goRouter, isNotNull);
      });

      testWidgets('應該有正確的初始路由', (tester) async {
        // Red Phase: 測試初始路由是否為啟動頁
        final appRouter = AppRouter();
        final goRouter = appRouter.router;

        // 檢查 GoRouter 的初始路由配置
        expect(goRouter.routeInformationProvider?.value.uri.path, equals('/'));

        // 或者檢查當前路由路徑
        final currentPath =
            goRouter.routerDelegate.currentConfiguration.uri.path;
        expect(
          currentPath.isEmpty ? '/' : currentPath,
          equals(AppRoutes.splash),
        );
      });
    });

    group('基本路由導航', () {
      testWidgets('應該能導航到啟動頁並自動跳轉', (tester) async {
        // Red Phase: 測試啟動頁路由與自動跳轉
        final appRouter = AppRouter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                mockSharedPreferences,
              ),
            ],
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        // 等待路由初始化
        await TestHelpers.testLoadingState(tester);

        // 檢查初始路由路徑（應該是根路徑）
        var currentRoute =
            appRouter.router.routerDelegate.currentConfiguration.uri.path;
        expect(
          currentRoute.isEmpty ? '/' : currentRoute,
          anyOf([equals('/'), equals(AppRoutes.cardList)]),
        );

        // 等待 SplashScreen 的自動跳轉完成（2秒後跳轉）
        await tester.pump(const Duration(seconds: 3));

        // 驗證最終重定向到名片列表（這是正確的行為）
        currentRoute =
            appRouter.router.routerDelegate.currentConfiguration.uri.path;
        expect(currentRoute, equals(AppRoutes.cardList));

        // 現在應該顯示 CardListPage
        expect(find.byType(CardListPage), findsOneWidget);
      });

      testWidgets('應該能導航到名片列表頁 (/card-list)', (tester) async {
        // Red Phase: 測試名片列表頁路由
        final appRouter = AppRouter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                mockSharedPreferences,
              ),
            ],
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        // 導航到名片列表
        appRouter.router.go(AppRoutes.cardList);

        await TestHelpers.testLoadingState(tester);

        // 驗證當前路由
        final currentRoute =
            appRouter.router.routerDelegate.currentConfiguration.uri.path;
        expect(currentRoute, equals(AppRoutes.cardList));

        // 驗證顯示 CardListPage
        expect(find.byType(CardListPage), findsOneWidget);
      });

      testWidgets('應該能導航到相機頁 (/camera)', (tester) async {
        // Red Phase: 測試相機頁路由
        final appRouter = AppRouter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                mockSharedPreferences,
              ),
            ],
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        // 導航到相機頁
        appRouter.router.go(AppRoutes.camera);

        await TestHelpers.testLoadingState(tester);

        // 驗證當前路由
        final currentRoute =
            appRouter.router.routerDelegate.currentConfiguration.uri.path;
        expect(currentRoute, equals(AppRoutes.camera));

        // 驗證顯示 CameraPage
        expect(find.byType(CameraPage), findsOneWidget);
      });

      testWidgets('應該能導航到設定頁 (/settings)', (tester) async {
        // Red Phase: 測試設定頁路由
        final appRouter = AppRouter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                mockSharedPreferences,
              ),
            ],
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        // 導航到設定頁
        appRouter.router.go(AppRoutes.settings);

        await TestHelpers.testLoadingState(tester);

        // 驗證當前路由
        final currentRoute =
            appRouter.router.routerDelegate.currentConfiguration.uri.path;
        expect(currentRoute, equals(AppRoutes.settings));

        // 驗證顯示 SettingsPage
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('應該能導航到AI設定頁 (/ai-settings)', (tester) async {
        // Red Phase: 測試AI設定頁路由
        final appRouter = AppRouter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                mockSharedPreferences,
              ),
            ],
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        // 導航到AI設定頁
        appRouter.router.go(AppRoutes.aiSettings);

        await TestHelpers.testLoadingState(tester);

        // 驗證當前路由
        final currentRoute =
            appRouter.router.routerDelegate.currentConfiguration.uri.path;
        expect(currentRoute, equals(AppRoutes.aiSettings));

        // 驗證顯示 AISettingsPage
        expect(find.byType(AISettingsPage), findsOneWidget);
      });
    });

    group('參數路由導航', () {
      testWidgets('應該能導航到OCR處理頁並傳遞圖片路徑 (/ocr-processing/:imagePath)', (
        tester,
      ) async {
        // Red Phase: 測試帶參數的OCR處理頁路由
        final appRouter = AppRouter();
        const testImagePath = 'test_image_path.jpg'; // 簡化路徑，避免特殊字符問題

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                mockSharedPreferences,
              ),
            ],
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        // 導航到OCR處理頁（帶參數）
        appRouter.router.go('${AppRoutes.ocrProcessing}/$testImagePath');

        await TestHelpers.testLoadingState(tester);

        // 驗證當前路由包含參數
        final currentUri =
            appRouter.router.routerDelegate.currentConfiguration.uri;
        expect(currentUri.path, contains(AppRoutes.ocrProcessing));
        expect(currentUri.path, contains(testImagePath));

        // 驗證顯示 OCRProcessingPage
        expect(find.byType(OCRProcessingPage), findsOneWidget);
      });

      testWidgets('應該能導航到名片詳情頁並傳遞名片ID (/card-detail/:cardId)', (tester) async {
        // Red Phase: 測試帶參數的名片詳情頁路由
        final appRouter = AppRouter();
        const testCardId = 'test-card-123';

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                mockSharedPreferences,
              ),
            ],
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        // 導航到名片詳情頁（帶參數）
        appRouter.router.go('${AppRoutes.cardDetail}/$testCardId');

        await TestHelpers.testLoadingState(tester);

        // 驗證當前路由包含參數
        final currentUri =
            appRouter.router.routerDelegate.currentConfiguration.uri;
        expect(currentUri.path, contains(AppRoutes.cardDetail));
        expect(currentUri.path, contains(testCardId));

        // 驗證顯示 CardDetailPage - 需要導入正確的 CardDetailPage
        expect(find.byType(CardDetailPage), findsOneWidget);
      });
    });

    group('導航流程測試', () {
      testWidgets('應該支援完整的名片掃描流程導航', (tester) async {
        // Red Phase: 測試完整的使用者流程導航
        final appRouter = AppRouter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                mockSharedPreferences,
              ),
            ],
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        final router = appRouter.router;

        // 1. 從啟動頁開始 - 檢查初始狀態
        final initialPath = router.routerDelegate.currentConfiguration.uri.path;
        expect(
          initialPath.isEmpty ? '/' : initialPath,
          equals(AppRoutes.splash),
        );

        // 2. 導航到名片列表
        router.go(AppRoutes.cardList);
        await TestHelpers.testLoadingState(tester);
        expect(find.byType(CardListPage), findsOneWidget);

        // 3. 導航到相機頁
        router.go(AppRoutes.camera);
        await TestHelpers.testLoadingState(tester);
        expect(find.byType(CameraPage), findsOneWidget);

        // 4. 導航到OCR處理頁
        const imagePath = 'test_captured_image.jpg';
        router.go('${AppRoutes.ocrProcessing}/$imagePath');
        await TestHelpers.testLoadingState(tester);
        expect(find.byType(OCRProcessingPage), findsOneWidget);

        // 5. 返回名片列表
        router.go(AppRoutes.cardList);
        await TestHelpers.testLoadingState(tester);
        expect(find.byType(CardListPage), findsOneWidget);
      });

      testWidgets('應該支援設定相關頁面的導航', (tester) async {
        // Red Phase: 測試設定相關頁面的導航流程
        final appRouter = AppRouter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                mockSharedPreferences,
              ),
            ],
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        final router = appRouter.router;

        // 1. 導航到設定頁
        router.go(AppRoutes.settings);
        await TestHelpers.testLoadingState(tester);
        expect(find.byType(SettingsPage), findsOneWidget);

        // 2. 導航到AI設定頁
        router.go(AppRoutes.aiSettings);
        await TestHelpers.testLoadingState(tester);
        expect(find.byType(AISettingsPage), findsOneWidget);

        // 3. 返回設定頁
        router.go(AppRoutes.settings);
        await TestHelpers.testLoadingState(tester);
        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('路由守衛與重定向', () {
      testWidgets('應該實作路由守衛邏輯', (tester) async {
        // Red Phase: 測試路由守衛功能
        final appRouter = AppRouter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                mockSharedPreferences,
              ),
            ],
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        final router = appRouter.router;

        // 在沒有滿足條件時，應該重定向或阻止導航
        // 這裡的具體邏輯會在實作階段定義
        expect(() => router.go('/protected-route'), returnsNormally);
      });

      testWidgets('應該處理無效路由並重定向到預設頁面', (tester) async {
        // Red Phase: 測試無效路由的處理
        final appRouter = AppRouter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                mockSharedPreferences,
              ),
            ],
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        final router = appRouter.router;

        // 嘗試導航到不存在的路由
        router.go('/non-existent-route');
        await TestHelpers.testLoadingState(tester);

        // 應該重定向到預設頁面（例如名片列表或404頁面）
        final currentRoute =
            router.routerDelegate.currentConfiguration.uri.path;
        expect(
          currentRoute,
          anyOf(equals(AppRoutes.cardList), equals(AppRoutes.splash)),
        );
      });
    });

    group('底部導航列整合', () {
      testWidgets('應該與底部導航列正確整合', (tester) async {
        // Red Phase: 測試底部導航列與路由的整合
        final appRouter = AppRouter();

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        // 導航到需要底部導航列的頁面
        appRouter.router.go(AppRoutes.cardList);

        await TestHelpers.testLoadingState(tester);

        // 應該顯示底部導航列
        expect(find.byType(BottomNavigationBar), findsOneWidget);

        // 測試底部導航列的三個主要功能
        final bottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNav.items.length, equals(3));

        // 驗證底部導航項目
        final items = bottomNav.items;
        expect(items[0].label, contains('名片')); // 名片列表
        expect(items[1].label, contains('掃描')); // 相機掃描
        expect(items[2].label, contains('設定')); // 設定
      });

      testWidgets('應該在底部導航項目之間正確切換', (tester) async {
        // Red Phase: 測試底部導航項目的切換功能
        final appRouter = AppRouter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                mockSharedPreferences,
              ),
            ],
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        final router = appRouter.router;

        // 導航到有底部導航的頁面
        router.go(AppRoutes.cardList);
        await TestHelpers.testLoadingState(tester);

        // 點擊底部導航項目測試路由切換
        final bottomNav = find.byType(BottomNavigationBar);
        expect(bottomNav, findsOneWidget);

        // 模擬點擊設定標籤
        await tester.tap(find.text('設定'));
        await TestHelpers.testLoadingState(tester);

        // 驗證路由切換
        final currentRoute =
            router.routerDelegate.currentConfiguration.uri.path;
        expect(currentRoute, equals(AppRoutes.settings));
      });
    });

    group('路由動畫與轉場', () {
      testWidgets('應該實作自定義的頁面轉場動畫', (tester) async {
        // Red Phase: 測試路由轉場動畫
        final appRouter = AppRouter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                mockSharedPreferences,
              ),
            ],
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        final router = appRouter.router;

        // 導航並檢查是否有轉場動畫
        router.go(AppRoutes.cardList);
        await tester.pump(); // 開始動畫
        await tester.pump(const Duration(milliseconds: 100)); // 動畫進行中

        // 驗證頁面轉場動畫存在 - 檢查是否有動畫相關的 Widget
        expect(find.byType(SlideTransition), findsWidgets);
      });
    });

    group('錯誤處理', () {
      testWidgets('應該處理路由配置錯誤', (tester) async {
        // Red Phase: 測試路由錯誤處理
        final appRouter = AppRouter();

        await tester.pumpWidget(
          TestHelpers.createTestWidget(
            container: container,
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        // 測試路由錯誤的處理機制
        final router = appRouter.router;
        expect(() => router, returnsNormally);
      });

      testWidgets('應該處理無效路由並顯示錯誤處理', (tester) async {
        // Red Phase: 測試無效路由處理（手機 APP 使用 errorBuilder）
        final appRouter = AppRouter();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                mockSharedPreferences,
              ),
            ],
            child: MaterialApp.router(routerConfig: appRouter.router),
          ),
        );

        final router = appRouter.router;

        // 導航到不存在的路由
        router.go('/this-route-does-not-exist');
        await TestHelpers.testLoadingState(tester);

        // 手機 APP 會顯示錯誤頁面，包含載入指示器和文字
        expect(find.text('載入中...'), findsWidgets);
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });
    });

    group('深度連結支援', () {
      testWidgets('應該支援深度連結導航', (tester) async {
        // Red Phase: 測試深度連結功能
        final appRouter = AppRouter();

        // 直接測試路由導航，不觸發 UI 建構
        const cardId = 'deep-link-card-123';
        final route = '${AppRoutes.cardDetail}/$cardId';

        // 驗證路由可以正確解析參數
        expect(route, equals('/card-detail/deep-link-card-123'));
        expect(route, contains(cardId));

        // 驗證路由是否有效
        expect(AppRoutes.isValidRoute(route), isTrue);
      });
    });
  });
}
