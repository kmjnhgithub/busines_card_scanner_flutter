import 'package:busines_card_scanner_flutter/presentation/router/app_router.dart';
import 'package:busines_card_scanner_flutter/presentation/router/app_routes.dart';
import 'package:test/test.dart';

/// 簡化版 AppRouter 測試
///
/// 專注於測試核心路由邏輯，不依賴Flutter Widget測試
/// 這是TDD的Red Phase - 確保所有測試都會失敗
void main() {
  group('AppRouter - Core Logic Tests', () {
    test('應該能建立 AppRouter 實例', () {
      // Green Phase: 測試 AppRouter() 單例模式
      expect(() => AppRouter(), returnsNormally);
    });

    test('應該能取得 router 實例', () {
      // Green Phase: 測試能取得 GoRouter 實例
      final appRouter = AppRouter();
      expect(appRouter.router, isNotNull);
    });
  });

  group('AppRoutes - 路由常數測試', () {
    test('應該定義所有必要的路由常數', () {
      // 驗證所有路由常數都已定義
      expect(AppRoutes.splash, equals('/'));
      expect(AppRoutes.cardList, equals('/card-list'));
      expect(AppRoutes.camera, equals('/camera'));
      expect(AppRoutes.ocrProcessing, equals('/ocr-processing'));
      expect(AppRoutes.cardDetail, equals('/card-detail'));
      expect(AppRoutes.settings, equals('/settings'));
      expect(AppRoutes.aiSettings, equals('/ai-settings'));
      expect(AppRoutes.export, equals('/export'));
      expect(AppRoutes.notFound, equals('/404'));
    });

    test('應該回傳所有路由列表', () {
      final allRoutes = AppRoutes.allRoutes;

      expect(allRoutes, isA<List<String>>());
      expect(allRoutes.length, equals(9));
      expect(allRoutes, contains('/'));
      expect(allRoutes, contains('/card-list'));
      expect(allRoutes, contains('/camera'));
      expect(allRoutes, contains('/settings'));
    });

    test('應該正確識別底部導航路由', () {
      final bottomNavRoutes = AppRoutes.bottomNavRoutes;

      expect(bottomNavRoutes, isA<List<String>>());
      expect(bottomNavRoutes.length, equals(3));
      expect(bottomNavRoutes, contains('/card-list'));
      expect(bottomNavRoutes, contains('/camera'));
      expect(bottomNavRoutes, contains('/settings'));
    });

    test('應該正確建構帶參數的路由', () {
      // 測試 OCR 處理頁面的參數路由
      final route = AppRoutes.buildRouteWithParams(AppRoutes.ocrProcessing, [
        'test-image.jpg',
      ]);
      expect(route, equals('/ocr-processing/test-image.jpg'));

      // 測試名片詳情頁面的參數路由
      final cardRoute = AppRoutes.buildRouteWithParams(AppRoutes.cardDetail, [
        'card-123',
      ]);
      expect(cardRoute, equals('/card-detail/card-123'));
    });

    test('應該正確驗證路由有效性', () {
      // 有效路由
      expect(AppRoutes.isValidRoute('/card-list'), isTrue);
      expect(AppRoutes.isValidRoute('/settings'), isTrue);

      // 帶參數的有效路由
      expect(AppRoutes.isValidRoute('/card-detail/123'), isTrue);
      expect(AppRoutes.isValidRoute('/ocr-processing/image.jpg'), isTrue);

      // 無效路由
      expect(AppRoutes.isValidRoute('/invalid-route'), isFalse);
      expect(AppRoutes.isValidRoute('/non-existent'), isFalse);
    });

    test('應該正確識別需要參數的路由', () {
      // 需要參數的路由
      expect(AppRoutes.requiresParameters(AppRoutes.ocrProcessing), isTrue);
      expect(AppRoutes.requiresParameters(AppRoutes.cardDetail), isTrue);

      // 不需要參數的路由
      expect(AppRoutes.requiresParameters(AppRoutes.cardList), isFalse);
      expect(AppRoutes.requiresParameters(AppRoutes.settings), isFalse);
    });

    test('應該回傳正確的參數列表', () {
      final ocrParams = AppRoutes.getRequiredParameters(
        AppRoutes.ocrProcessing,
      );
      expect(ocrParams, equals(['imagePath']));

      final cardParams = AppRoutes.getRequiredParameters(AppRoutes.cardDetail);
      expect(cardParams, equals(['cardId']));

      final noParams = AppRoutes.getRequiredParameters(AppRoutes.cardList);
      expect(noParams, isEmpty);
    });

    test('應該正確判斷是否顯示底部導航', () {
      // 應該顯示底部導航的路由
      expect(AppRoutes.shouldShowBottomNav('/card-list'), isTrue);
      expect(AppRoutes.shouldShowBottomNav('/camera'), isTrue);
      expect(AppRoutes.shouldShowBottomNav('/settings'), isTrue);

      // 不應該顯示底部導航的路由
      expect(AppRoutes.shouldShowBottomNav('/ai-settings'), isFalse);
      expect(AppRoutes.shouldShowBottomNav('/ocr-processing'), isFalse);
      expect(AppRoutes.shouldShowBottomNav('/'), isFalse);
    });

    test('應該正確取得底部導航索引', () {
      expect(AppRoutes.getBottomNavIndex('/card-list'), equals(0));
      expect(AppRoutes.getBottomNavIndex('/camera'), equals(1));
      expect(AppRoutes.getBottomNavIndex('/settings'), equals(2));
      expect(AppRoutes.getBottomNavIndex('/ai-settings'), equals(-1));
    });

    test('應該根據索引取得正確的路由', () {
      expect(AppRoutes.getRouteByBottomNavIndex(0), equals('/card-list'));
      expect(AppRoutes.getRouteByBottomNavIndex(1), equals('/camera'));
      expect(AppRoutes.getRouteByBottomNavIndex(2), equals('/settings'));
      expect(AppRoutes.getRouteByBottomNavIndex(3), isNull);
      expect(AppRoutes.getRouteByBottomNavIndex(-1), isNull);
    });
  });

  group('路由參數配置測試', () {
    test('應該正確定義路由參數映射', () {
      const expectedParams = {
        '/ocr-processing': ['imagePath'],
        '/card-detail': ['cardId'],
      };

      expect(AppRoutes.routeParameters, equals(expectedParams));
    });

    test('應該處理空參數列表', () {
      final route = AppRoutes.buildRouteWithParams('/card-list', []);
      expect(route, equals('/card-list'));
    });

    test('應該處理多個參數', () {
      // 假設未來有需要多個參數的路由
      final route = AppRoutes.buildRouteWithParams('/complex-route', [
        'param1',
        'param2',
        'param3',
      ]);
      expect(route, equals('/complex-route/param1/param2/param3'));
    });
  });
}
