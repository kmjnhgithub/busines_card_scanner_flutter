import 'package:busines_card_scanner_flutter/presentation/router/app_router.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: BusinessCardScannerApp()));
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
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
