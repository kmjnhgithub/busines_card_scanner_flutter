import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_creation/pages/camera_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_creation/pages/ocr_processing_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_detail/pages/card_detail_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_detail/view_models/card_detail_state.dart';
import 'package:busines_card_scanner_flutter/presentation/features/home/pages/home_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/pages/ai_settings_page.dart';
import 'package:busines_card_scanner_flutter/presentation/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 應用程式路由配置
///
/// 負責管理整個應用程式的路由導航系統
/// 使用 GoRouter 實作聲明式路由配置
///
/// 主要功能：
/// - 路由配置與導航
/// - 路由守衛與重定向
/// - 底部導航列整合
/// - 錯誤處理與404頁面
/// - 深度連結支援
/// - 頁面轉場動畫
class AppRouter {
  late final GoRouter _router;

  static AppRouter? _instance;

  /// 取得 AppRouter 單例實例
  factory AppRouter() {
    _instance ??= AppRouter._();
    return _instance!;
  }

  // 私有建構函數
  AppRouter._() {
    _router = _createRouter();
  }

  /// 取得 GoRouter 實例
  GoRouter get router => _router;

  /// 建立 GoRouter 配置
  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      // 移除 404 頁面，改為記錄錯誤並返回上一頁
      errorBuilder: (context, state) {
        debugPrint('路由錯誤: ${state.error}');
        debugPrint('嘗試導航到: ${state.matchedLocation}');

        // 在手機 APP 中，不顯示 404 頁面
        // 而是顯示錯誤訊息並返回
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('頁面載入失敗'),
                backgroundColor: Colors.red,
              ),
            );
            // 如果可以返回，就返回上一頁
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
        });

        // 返回一個空的容器，因為會立即返回上一頁
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      routes: [
        // 啟動頁面路由
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          pageBuilder: (context, state) =>
              _buildPageWithTransition(context, state, const SplashScreen()),
        ),

        // 底部導航Shell路由
        ShellRoute(
          builder: (context, state, child) {
            final currentIndex = AppRoutes.getBottomNavIndex(
              state.matchedLocation,
            );
            return HomePage(
              currentIndex: currentIndex >= 0 ? currentIndex : 0,
              child: child,
            );
          },
          routes: [
            // 名片列表頁面
            GoRoute(
              path: AppRoutes.cardList,
              name: 'card-list',
              pageBuilder: (context, state) => _buildPageWithTransition(
                context,
                state,
                const CardListNavPage(),
              ),
            ),

            // 設定頁面
            GoRoute(
              path: AppRoutes.settings,
              name: 'settings',
              pageBuilder: (context, state) => _buildPageWithTransition(
                context,
                state,
                const SettingsNavPage(),
              ),
            ),
          ],
        ),

        // 全螢幕相機頁面（獨立路由）
        GoRoute(
          path: AppRoutes.camera,
          name: 'camera-fullscreen',
          pageBuilder: (context, state) => _buildFullscreenPageWithTransition(
            context,
            state,
            const CameraPage(),
          ),
        ),

        // OCR處理頁面（帶參數）
        GoRoute(
          path: '${AppRoutes.ocrProcessing}/:imagePath',
          name: 'ocr-processing',
          pageBuilder: (context, state) {
            final imagePath = state.pathParameters['imagePath'] ?? '';
            return _buildPageWithTransition(
              context,
              state,
              OCRProcessingPage(imagePath: imagePath),
            );
          },
        ),

        // 名片詳情頁面（檢視模式）
        GoRoute(
          path: '${AppRoutes.cardDetail}/:cardId',
          name: 'card-detail',
          pageBuilder: (context, state) {
            final cardId = state.pathParameters['cardId'] ?? '';
            return _buildPageWithTransition(
              context,
              state,
              CardDetailPage(cardId: cardId),
            );
          },
        ),

        // 名片編輯頁面
        GoRoute(
          path: '/card-detail/:cardId/edit',
          name: 'card-detail-edit',
          pageBuilder: (context, state) {
            final cardId = state.pathParameters['cardId'] ?? '';
            return _buildPageWithTransition(
              context,
              state,
              CardDetailPage(cardId: cardId, mode: CardDetailMode.editing),
            );
          },
        ),

        // 新增名片頁面（來自 OCR）
        GoRoute(
          path: '/card-detail/creating',
          name: 'card-detail-creating',
          pageBuilder: (context, state) {
            // 支援多種參數格式
            BusinessCard? parsedCard;

            if (state.extra is BusinessCard) {
              parsedCard = state.extra as BusinessCard;
            } else if (state.extra is Map<String, dynamic>) {
              final extraData = state.extra as Map<String, dynamic>;
              parsedCard = extraData['card'] as BusinessCard?;

              // 如果有圖片路徑，更新到名片資料
              if (extraData['imagePath'] != null && parsedCard != null) {
                parsedCard = parsedCard.copyWith(
                  imagePath: extraData['imagePath'] as String,
                );
              }
            }

            return _buildPageWithTransition(
              context,
              state,
              CardDetailPage(
                mode: CardDetailMode.creating,
                ocrParsedCard: parsedCard,
              ),
            );
          },
        ),

        // 手動建立名片頁面
        GoRoute(
          path: '/card-detail/manual',
          name: 'card-detail-manual',
          pageBuilder: (context, state) {
            return _buildPageWithTransition(
              context,
              state,
              const CardDetailPage(mode: CardDetailMode.manual),
            );
          },
        ),

        // AI設定頁面
        GoRoute(
          path: AppRoutes.aiSettings,
          name: 'ai-settings',
          pageBuilder: (context, state) =>
              _buildPageWithTransition(context, state, const AISettingsPage()),
        ),

        // 匯出資料頁面
        GoRoute(
          path: AppRoutes.export,
          name: 'export',
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            Scaffold(
              appBar: AppBar(title: const Text('匯出資料')),
              body: const Center(child: Text('匯出資料頁面')),
            ),
          ),
        ),

        // 404錯誤頁面
        GoRoute(
          path: AppRoutes.notFound,
          name: '404',
          pageBuilder: (context, state) =>
              _buildPageWithTransition(context, state, const NotFoundPage()),
        ),
      ],
      // 路由重定向
      redirect: (context, state) {
        final currentLocation = state.matchedLocation;

        // 如果在根路徑且不是啟動頁，重定向到名片列表
        if (currentLocation == '/' && state.path != AppRoutes.splash) {
          return AppRoutes.cardList;
        }

        return null;
      },
    );
  }

  /// 建立帶轉場動畫的頁面
  Page<T> _buildPageWithTransition<T extends Object?>(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // 使用滑動轉場動畫
        const begin = Offset(1, 0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  /// 建立全螢幕頁面的轉場動畫（從下往上滑入）
  Page<T> _buildFullscreenPageWithTransition<T extends Object?>(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // 使用從下往上的滑動轉場動畫（類似模態頁面）
        const begin = Offset(0, 1);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        final tween = Tween(begin: begin, end: end);
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return SlideTransition(
          position: tween.animate(curvedAnimation),
          child: child,
        );
      },
    );
  }
}

/// 啟動頁面
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 模擬初始化過程
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) {
        return;
      }

      // 導航到名片列表頁面
      context.go(AppRoutes.cardList);
    } on Exception catch (e) {
      if (!mounted) {
        return;
      }

      // 顯示錯誤訊息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('初始化失敗: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Business Card Scanner',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Initializing...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
