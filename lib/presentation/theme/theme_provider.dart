import 'package:busines_card_scanner_flutter/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// 簡化的主題提供者
///
/// 只提供淺色主題，移除了主題切換功能
class ThemeProvider {
  static ThemeData get lightTheme => AppTheme.lightTheme;
}
