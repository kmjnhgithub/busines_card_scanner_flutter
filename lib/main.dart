import 'package:busines_card_scanner_flutter/presentation/features/settings/providers/settings_providers.dart';
import 'package:busines_card_scanner_flutter/presentation/router/app_router.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // 確保 Flutter binding 初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Override SharedPreferences provider
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const BusinessCardScannerApp(),
    ),
  );
}

class BusinessCardScannerApp extends ConsumerWidget {
  const BusinessCardScannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 建立路由器實例
    final appRouter = AppRouter();

    return MaterialApp.router(
      title: 'Business Card Scanner',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light, // 強制使用淺色模式
      routerConfig: appRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
