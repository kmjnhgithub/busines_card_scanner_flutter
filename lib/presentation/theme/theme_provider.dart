import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:busines_card_scanner_flutter/presentation/theme/app_theme.dart';

/// 應用程式主題模式枚舉
///
/// 定義應用程式支援的主題模式
enum AppThemeMode {
  /// 淺色主題
  light,

  /// 深色主題
  dark,

  /// 跟隨系統設定
  system,
}

/// 主題設定類別
///
/// 封裝主題相關的狀態和配置
@immutable
class ThemeSettings {
  const ThemeSettings({
    required this.themeMode,
    required this.isSystemDarkMode,
  });

  /// 當前主題模式
  final AppThemeMode themeMode;

  /// 系統是否為深色模式
  final bool isSystemDarkMode;

  /// 當前實際使用的是否為深色主題
  bool get isDarkMode {
    switch (themeMode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        return isSystemDarkMode;
    }
  }

  /// 當前主題資料
  ThemeData get currentTheme {
    return isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
  }

  /// 複製並更新主題設定
  ThemeSettings copyWith({AppThemeMode? themeMode, bool? isSystemDarkMode}) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      isSystemDarkMode: isSystemDarkMode ?? this.isSystemDarkMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeSettings &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          isSystemDarkMode == other.isSystemDarkMode;

  @override
  int get hashCode => themeMode.hashCode ^ isSystemDarkMode.hashCode;

  @override
  String toString() {
    return 'ThemeSettings(themeMode: $themeMode, isSystemDarkMode: $isSystemDarkMode, isDarkMode: $isDarkMode)';
  }
}

/// 主題 Notifier
///
/// 管理應用程式主題狀態，包括主題切換和系統主題跟隨
class ThemeNotifier extends StateNotifier<ThemeSettings> {
  ThemeNotifier() : super(_getInitialThemeSettings()) {
    // 監聽系統主題變化
    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        _updateSystemTheme;
  }

  /// 獲取初始主題設定
  static ThemeSettings _getInitialThemeSettings() {
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return ThemeSettings(
      themeMode: AppThemeMode.system, // 預設跟隨系統
      isSystemDarkMode: brightness == Brightness.dark,
    );
  }

  /// 更新系統主題
  void _updateSystemTheme() {
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    final isSystemDarkMode = brightness == Brightness.dark;

    if (state.isSystemDarkMode != isSystemDarkMode) {
      state = state.copyWith(isSystemDarkMode: isSystemDarkMode);
    }
  }

  /// 設定主題模式
  void setThemeMode(AppThemeMode mode) {
    if (state.themeMode != mode) {
      state = state.copyWith(themeMode: mode);
    }
  }

  /// 切換到淺色主題
  void setLightTheme() {
    setThemeMode(AppThemeMode.light);
  }

  /// 切換到深色主題
  void setDarkTheme() {
    setThemeMode(AppThemeMode.dark);
  }

  /// 跟隨系統主題
  void setSystemTheme() {
    setThemeMode(AppThemeMode.system);
  }

  /// 切換主題（在淺色和深色之間切換）
  void toggleTheme() {
    switch (state.themeMode) {
      case AppThemeMode.light:
        setDarkTheme();
        break;
      case AppThemeMode.dark:
        setLightTheme();
        break;
      case AppThemeMode.system:
        // 如果當前跟隨系統，則切換到與系統相反的主題
        if (state.isSystemDarkMode) {
          setLightTheme();
        } else {
          setDarkTheme();
        }
        break;
    }
  }

  /// 重置為系統主題
  void resetToSystemTheme() {
    setSystemTheme();
  }

  /// 檢查是否為淺色主題
  bool get isLightTheme => !state.isDarkMode;

  /// 檢查是否為深色主題
  bool get isDarkTheme => state.isDarkMode;

  /// 檢查是否跟隨系統主題
  bool get isSystemTheme => state.themeMode == AppThemeMode.system;

  /// 獲取主題模式描述
  String getThemeModeDescription() {
    switch (state.themeMode) {
      case AppThemeMode.light:
        return '淺色主題';
      case AppThemeMode.dark:
        return '深色主題';
      case AppThemeMode.system:
        return '跟隨系統';
    }
  }

  /// 獲取當前主題描述
  String getCurrentThemeDescription() {
    if (state.themeMode == AppThemeMode.system) {
      return '跟隨系統 (${state.isDarkMode ? '深色' : '淺色'})';
    }
    return getThemeModeDescription();
  }
}

/// 主題 Provider
///
/// 提供主題設定的全域狀態管理
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeSettings>((
  ref,
) {
  return ThemeNotifier();
});

/// 當前主題資料 Provider
///
/// 提供當前主題的 ThemeData
final currentThemeProvider = Provider<ThemeData>((ref) {
  final themeSettings = ref.watch(themeProvider);
  return themeSettings.currentTheme;
});

/// 當前是否為深色主題 Provider
///
/// 提供當前是否為深色主題的布林值
final isDarkThemeProvider = Provider<bool>((ref) {
  final themeSettings = ref.watch(themeProvider);
  return themeSettings.isDarkMode;
});

/// 當前主題亮度 Provider
///
/// 提供當前主題的亮度
final currentBrightnessProvider = Provider<Brightness>((ref) {
  final isDark = ref.watch(isDarkThemeProvider);
  return isDark ? Brightness.dark : Brightness.light;
});

/// 主題切換按鈕輔助方法
///
/// 提供主題切換的便利方法
extension ThemeProviderExtension on WidgetRef {
  /// 獲取主題設定
  ThemeSettings get themeSettings => watch(themeProvider);

  /// 獲取主題 Notifier
  ThemeNotifier get themeNotifier => read(themeProvider.notifier);

  /// 獲取當前主題
  ThemeData get currentTheme => watch(currentThemeProvider);

  /// 檢查是否為深色主題
  bool get isDarkTheme => watch(isDarkThemeProvider);

  /// 獲取當前亮度
  Brightness get currentBrightness => watch(currentBrightnessProvider);

  /// 切換主題
  void toggleTheme() => themeNotifier.toggleTheme();

  /// 設定淺色主題
  void setLightTheme() => themeNotifier.setLightTheme();

  /// 設定深色主題
  void setDarkTheme() => themeNotifier.setDarkTheme();

  /// 設定跟隨系統主題
  void setSystemTheme() => themeNotifier.setSystemTheme();
}

/// 主題相關的便利方法
class ThemeUtils {
  ThemeUtils._();

  /// 根據亮度獲取對應的主題資料
  static ThemeData getThemeData(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppTheme.darkTheme
        : AppTheme.lightTheme;
  }

  /// 檢查當前平台的主題偏好
  static Brightness get systemBrightness {
    return SchedulerBinding.instance.platformDispatcher.platformBrightness;
  }

  /// 檢查系統是否為深色模式
  static bool get isSystemDarkMode {
    return systemBrightness == Brightness.dark;
  }

  /// 獲取主題模式的圖示
  static IconData getThemeModeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  /// 獲取下一個主題模式（用於循環切換）
  static AppThemeMode getNextThemeMode(AppThemeMode current) {
    switch (current) {
      case AppThemeMode.light:
        return AppThemeMode.dark;
      case AppThemeMode.dark:
        return AppThemeMode.system;
      case AppThemeMode.system:
        return AppThemeMode.light;
    }
  }

  /// 獲取所有可用的主題模式
  static List<AppThemeMode> get allThemeModes {
    return AppThemeMode.values;
  }

  /// 獲取主題模式的本地化名稱
  static String getThemeModeLocalizedName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return '淺色';
      case AppThemeMode.dark:
        return '深色';
      case AppThemeMode.system:
        return '跟隨系統';
    }
  }
}
