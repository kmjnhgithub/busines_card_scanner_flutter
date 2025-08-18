import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'test_permissions_page.dart';

/// 測試權限用的 main 檔案
/// 使用方式: flutter run lib/main_test_permissions.dart
void main() {
  runApp(const ProviderScope(child: TestPermissionsApp()));
}

class TestPermissionsApp extends StatelessWidget {
  const TestPermissionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Permissions',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const TestPermissionsPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
