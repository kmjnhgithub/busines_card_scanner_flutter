import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/settings_constants.dart';

part 'settings_view_model.freezed.dart';
part 'settings_view_model.g.dart';

/// 語言設定列舉
enum SettingsLanguage {
  system(SettingsConstants.systemLanguage),
  zh_TW(SettingsConstants.chineseTWLanguage),
  en_US(SettingsConstants.englishLanguage);

  const SettingsLanguage(this.code);
  final String code;

  static SettingsLanguage fromString(String? value) {
    switch (value) {
      case SettingsConstants.chineseTWLanguage:
        return SettingsLanguage.zh_TW;
      case SettingsConstants.englishLanguage:
        return SettingsLanguage.en_US;
      case SettingsConstants.systemLanguage:
      default:
        return SettingsLanguage.system;
    }
  }
}

/// 主題設定列舉
enum SettingsTheme {
  system(SettingsConstants.systemTheme),
  light(SettingsConstants.lightTheme),
  dark(SettingsConstants.darkTheme);

  const SettingsTheme(this.code);
  final String code;

  static SettingsTheme fromString(String? value) {
    switch (value) {
      case SettingsConstants.lightTheme:
        return SettingsTheme.light;
      case SettingsConstants.darkTheme:
        return SettingsTheme.dark;
      case SettingsConstants.systemTheme:
      default:
        return SettingsTheme.system;
    }
  }
}

/// 設定頁面狀態
@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(false) bool isLoading,
    @Default(SettingsLanguage.system) SettingsLanguage language,
    @Default(SettingsTheme.system) SettingsTheme theme,
    @Default(true) bool notificationsEnabled,
    @Default('') String appVersion,
    @Default('') String buildNumber,
    String? error,
  }) = _SettingsState;
}

/// 設定頁面 ViewModel
class SettingsViewModel extends StateNotifier<SettingsState> {
  final SharedPreferences _preferences;
  final DeviceInfoPlugin _deviceInfo;

  SettingsViewModel({
    required SharedPreferences preferences,
    required DeviceInfoPlugin deviceInfo,
  })  : _preferences = preferences,
        _deviceInfo = deviceInfo,
        super(const SettingsState()) {
    _initializeSettings();
  }

  /// 初始化設定值
  void _initializeSettings() {
    try {
      // 載入儲存的設定
      final language = SettingsLanguage.fromString(
        _preferences.getString(SettingsConstants.languageKey),
      );
      final theme = SettingsTheme.fromString(
        _preferences.getString(SettingsConstants.themeKey),
      );
      final notificationsEnabled = _preferences.getBool(SettingsConstants.notificationsKey) 
          ?? SettingsConstants.defaultNotifications;

      state = state.copyWith(
        language: language,
        theme: theme,
        notificationsEnabled: notificationsEnabled,
      );
    } catch (e) {
      state = state.copyWith(
        error: '${SettingsConstants.loadSettingsError}：$e',
      );
    }
  }

  /// 變更語言設定
  Future<void> changeLanguage(SettingsLanguage language) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _preferences.setString(SettingsConstants.languageKey, language.code);

      state = state.copyWith(
        language: language,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '${SettingsConstants.saveLanguageError}：$e',
      );
    }
  }

  /// 變更主題設定
  Future<void> changeTheme(SettingsTheme theme) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _preferences.setString(SettingsConstants.themeKey, theme.code);

      state = state.copyWith(
        theme: theme,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '${SettingsConstants.saveThemeError}：$e',
      );
    }
  }

  /// 切換通知設定
  Future<void> toggleNotifications(bool enabled) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _preferences.setBool(SettingsConstants.notificationsKey, enabled);

      state = state.copyWith(
        notificationsEnabled: enabled,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '${SettingsConstants.saveNotificationError}：$e',
      );
    }
  }

  /// 載入應用版本資訊
  Future<void> loadAppVersion() async {
    try {
      // 不設定 isLoading，因為版本載入不應該影響整個頁面的顯示
      final packageInfo = await PackageInfo.fromPlatform();

      state = state.copyWith(
        appVersion: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
      );
    } catch (e) {
      state = state.copyWith(
        error: '${SettingsConstants.loadVersionError}：$e',
      );
    }
  }

  /// 重置所有設定
  Future<void> resetSettings() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // 清除所有儲存的設定
      await _preferences.remove(SettingsConstants.languageKey);
      await _preferences.remove(SettingsConstants.themeKey);
      await _preferences.remove(SettingsConstants.notificationsKey);

      // 重置為預設值
      state = state.copyWith(
        language: SettingsLanguage.system,
        theme: SettingsTheme.system,
        notificationsEnabled: SettingsConstants.defaultNotifications,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '${SettingsConstants.resetSettingsError}：$e',
      );
    }
  }

  /// 清除錯誤狀態
  void clearError() {
    state = state.copyWith(error: null);
  }
}

