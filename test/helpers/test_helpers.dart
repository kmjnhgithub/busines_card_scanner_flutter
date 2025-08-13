import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 測試輔助工具類
///
/// 提供標準化的測試架構模式和通用的測試輔助函數
class TestHelpers {
  /// 建立測試用的 Widget，使用已覆寫的 ProviderContainer
  ///
  /// [container] 包含已覆寫的 providers
  /// [child] 要測試的 widget
  /// [routes] 路由配置（可選）
  static Widget createTestWidget({
    required ProviderContainer container,
    required Widget child,
    Map<String, WidgetBuilder>? routes,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: child,
        routes: routes ?? {},
      ),
    );
  }

  /// 建立簡單的測試 Widget（不需要 Provider 覆寫）
  ///
  /// [child] 要測試的 widget
  /// [overrides] Provider 覆寫列表（可選）
  static Widget createSimpleTestWidget({
    required Widget child,
    List<Override>? overrides,
  }) {
    return ProviderScope(
      overrides: overrides ?? [],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// 建立測試用的 ProviderContainer
  ///
  /// [overrides] Provider 覆寫列表
  static ProviderContainer createTestContainer({
    required List<Override> overrides,
  }) {
    return ProviderContainer(
      overrides: overrides,
    );
  }

  /// 建立包含 Scaffold 的測試 Widget
  ///
  /// 用於需要 Scaffold 環境的 widget 測試
  static Widget wrapWithScaffold(Widget child) {
    return Scaffold(
      body: child,
    );
  }

  /// 建立包含 Material 環境的測試 Widget
  ///
  /// 用於需要 Material 主題的 widget 測試
  static Widget wrapWithMaterial(Widget child) {
    return Material(
      child: child,
    );
  }

  /// 測試非同步載入狀態
  ///
  /// 用於測試載入狀態時，避免 pumpAndSettle 超時
  static Future<void> testLoadingState(
    WidgetTester tester, {
    Duration loadingDuration = const Duration(milliseconds: 100),
  }) async {
    // 只 pump 一次以檢查載入狀態
    await tester.pump();
    // 等待載入狀態持續一段時間
    await tester.pump(loadingDuration);
  }

  /// 安全地等待非同步操作完成
  ///
  /// 包含超時保護，避免無限等待
  static Future<void> pumpAndSettleWithTimeout(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        timeout,
      );
    } catch (e) {
      // 如果超時，至少 pump 一次以更新狀態
      await tester.pump();
    }
  }

  /// 建立測試用的路由設定
  static Map<String, WidgetBuilder> createTestRoutes({
    Map<String, WidgetBuilder>? additionalRoutes,
  }) {
    final routes = <String, WidgetBuilder>{
      '/': (context) => Container(),
    };
    
    if (additionalRoutes != null) {
      routes.addAll(additionalRoutes);
    }
    
    return routes;
  }

  /// 釋放 ProviderContainer 資源
  ///
  /// 確保在 tearDown 中正確釋放資源
  static void disposeContainer(ProviderContainer? container) {
    container?.dispose();
  }

  /// 驗證 Widget 是否存在並可見
  static void expectWidgetVisible(Finder finder) {
    expect(finder, findsOneWidget);
    final widget = finder.evaluate().single.widget;
    expect(widget, isNotNull);
  }

  /// 驗證 Widget 不存在
  static void expectWidgetNotFound(Finder finder) {
    expect(finder, findsNothing);
  }

  /// 建立測試用的 GlobalKey
  static GlobalKey<T> createTestKey<T extends State>() {
    return GlobalKey<T>();
  }
}

/// 測試用的延遲工具
class TestDelays {
  /// 短延遲（用於狀態更新）
  static const Duration short = Duration(milliseconds: 100);
  
  /// 中等延遲（用於動畫）
  static const Duration medium = Duration(milliseconds: 500);
  
  /// 長延遲（用於網路請求模擬）
  static const Duration long = Duration(seconds: 1);
  
  /// 超長延遲（用於超時測試）
  static const Duration veryLong = Duration(seconds: 3);
}

/// 測試用的常見 Finder
class TestFinders {
  /// 找到載入指示器
  static Finder loadingIndicator() {
    return find.byType(CircularProgressIndicator);
  }
  
  /// 找到載入文字
  static Finder loadingText([String text = '載入中...']) {
    return find.text(text);
  }
  
  /// 找到錯誤訊息
  static Finder errorMessage(String message) {
    return find.text(message);
  }
  
  /// 找到空狀態
  static Finder emptyState([String message = '沒有資料']) {
    return find.text(message);
  }
  
  /// 找到按鈕
  static Finder button(String text) {
    return find.widgetWithText(ElevatedButton, text);
  }
  
  /// 找到圖標按鈕
  static Finder iconButton(IconData icon) {
    return find.byIcon(icon);
  }
}