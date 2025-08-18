/// 應用程式路由常數定義
///
/// 集中管理所有路由路徑，確保路由配置的一致性和可維護性
///
/// 路由命名規範：
/// - 使用 kebab-case 格式
/// - 清楚描述頁面功能
/// - 參數路由使用 : 前綴
class AppRoutes {
  // 私有建構函數，防止實例化
  AppRoutes._();

  /// 根路由 - 啟動頁
  static const String splash = '/';

  /// 名片列表頁
  static const String cardList = '/card-list';

  /// 相機拍攝頁
  static const String camera = '/camera';

  /// OCR 處理頁（帶圖片路徑參數）
  static const String ocrProcessing = '/ocr-processing';

  /// 名片詳情頁（帶名片ID參數）
  static const String cardDetail = '/card-detail';

  /// 設定頁
  static const String settings = '/settings';

  /// AI 設定頁
  static const String aiSettings = '/ai-settings';

  /// 匯出資料頁
  static const String export = '/export';

  /// 404 錯誤頁
  static const String notFound = '/404';

  /// 取得所有路由路徑列表
  static List<String> get allRoutes => [
    splash,
    cardList,
    camera,
    ocrProcessing,
    cardDetail,
    settings,
    aiSettings,
    export,
    notFound,
  ];

  /// 需要底部導航列的頁面
  static List<String> get bottomNavRoutes => [cardList, camera, settings];

  /// 參數路由配置
  ///
  /// 定義各個路由所需的參數
  static const Map<String, List<String>> routeParameters = {
    ocrProcessing: ['imagePath'],
    cardDetail: ['cardId'],
  };

  /// 建構帶參數的路由路徑
  ///
  /// [route] 基礎路由路徑
  /// [parameters] 參數值列表
  ///
  /// 範例：
  /// ```dart
  /// final route = AppRoutes.buildRouteWithParams(
  ///   AppRoutes.cardDetail,
  ///   ['card-123']
  /// );
  /// // 結果：'/card-detail/card-123'
  /// ```
  static String buildRouteWithParams(String route, List<String> parameters) {
    if (parameters.isEmpty) {
      return route;
    }

    return '$route/${parameters.join('/')}';
  }

  /// 驗證路由路徑是否有效
  ///
  /// [route] 要驗證的路由路徑
  ///
  /// 回傳 true 如果路由有效，否則回傳 false
  static bool isValidRoute(String route) {
    // 移除參數部分，只檢查基礎路由
    final baseRoute = route.split('/').take(2).join('/');
    return allRoutes.contains(baseRoute);
  }

  /// 檢查路由是否需要參數
  ///
  /// [route] 路由路徑
  ///
  /// 回傳 true 如果路由需要參數
  static bool requiresParameters(String route) {
    return routeParameters.containsKey(route);
  }

  /// 取得路由所需的參數名稱列表
  ///
  /// [route] 路由路徑
  ///
  /// 回傳參數名稱列表，如果路由不需要參數則回傳空列表
  static List<String> getRequiredParameters(String route) {
    return routeParameters[route] ?? [];
  }

  /// 檢查路由是否應該顯示底部導航列
  ///
  /// [route] 當前路由路徑
  ///
  /// 回傳 true 如果應該顯示底部導航列
  static bool shouldShowBottomNav(String route) {
    // 移除參數部分，只檢查基礎路由
    final baseRoute = route.split('/').take(2).join('/');
    return bottomNavRoutes.contains(baseRoute);
  }

  /// 取得底部導航列索引
  ///
  /// [route] 當前路由路徑
  ///
  /// 回傳底部導航列的索引，如果不在底部導航列中則回傳 -1
  static int getBottomNavIndex(String route) {
    final baseRoute = route.split('/').take(2).join('/');
    return bottomNavRoutes.indexOf(baseRoute);
  }

  /// 根據底部導航列索引取得路由
  ///
  /// [index] 底部導航列索引
  ///
  /// 回傳對應的路由路徑，如果索引無效則回傳 null
  static String? getRouteByBottomNavIndex(int index) {
    if (index < 0 || index >= bottomNavRoutes.length) {
      return null;
    }
    return bottomNavRoutes[index];
  }
}
