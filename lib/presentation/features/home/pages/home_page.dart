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
    // 特殊處理相機 tab（index 1）：使用 push 導航到全螢幕頁面
    if (index == 1) {
      context.push(AppRoutes.camera);
      return;
    }

    // 其他 tab 使用原有的 go 導航邏輯
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

/// 設定導航頁面
class SettingsNavPage extends StatelessWidget {
  const SettingsNavPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPage();
  }
}
