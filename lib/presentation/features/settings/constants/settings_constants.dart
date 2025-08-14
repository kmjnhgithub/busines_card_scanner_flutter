/// Settings 模組常數定義
class SettingsConstants {
  // SharedPreferences Keys
  static const String languageKey = 'app_language';
  static const String themeKey = 'app_theme';
  static const String notificationsKey = 'notifications_enabled';

  // 預設值
  static const String defaultLanguage = 'system';
  static const String defaultTheme = 'system';
  static const bool defaultNotifications = true;

  // 語言代碼
  static const String systemLanguage = 'system';
  static const String chineseTWLanguage = 'zh_TW';
  static const String englishLanguage = 'en_US';

  // 主題代碼
  static const String systemTheme = 'system';
  static const String lightTheme = 'light';
  static const String darkTheme = 'dark';

  // 錯誤訊息
  static const String loadSettingsError = '載入設定失敗';
  static const String saveLanguageError = '儲存語言設定失敗';
  static const String saveThemeError = '儲存主題設定失敗';
  static const String saveNotificationError = '儲存通知設定失敗';
  static const String loadVersionError = '載入版本資訊失敗';
  static const String resetSettingsError = '重置設定失敗';
}
