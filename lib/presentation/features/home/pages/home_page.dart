import 'package:busines_card_scanner_flutter/presentation/features/card_creation/pages/camera_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_list/pages/card_list_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/pages/settings_page.dart';
import 'package:busines_card_scanner_flutter/presentation/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 應用程式主頁面
///
/// 包含底部導航列，管理三個主要功能模組：
/// - 名片列表
/// - 相機掃描
/// - 設定管理
class HomePage extends StatefulWidget {
  /// 當前選中的導航索引
  final int currentIndex;

  /// 子頁面Widget
  final Widget child;

  const HomePage({required this.currentIndex, required this.child, super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: '名片'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: '掃描'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }

  void _onBottomNavTap(int index) {
    final route = AppRoutes.getRouteByBottomNavIndex(index);
    if (route != null && index != widget.currentIndex) {
      context.go(route);
    }
  }
}

/// 名片列表導航頁面
class CardListNavPage extends StatelessWidget {
  const CardListNavPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CardListPage();
  }
}

/// 相機掃描導航頁面
class CameraNavPage extends StatelessWidget {
  const CameraNavPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CameraPage();
  }
}

/// 設定導航頁面
class SettingsNavPage extends StatelessWidget {
  const SettingsNavPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPage();
  }
}

/// 404 錯誤頁面
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('頁面不存在')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '404',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '找不到您要訪問的頁面',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.cardList),
              child: const Text('返回首頁'),
            ),
          ],
        ),
      ),
    );
  }
}
