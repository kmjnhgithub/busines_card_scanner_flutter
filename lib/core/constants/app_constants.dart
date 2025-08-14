/// 應用程式常數定義
///
/// 包含應用程式中使用的各種常數，如：
/// - 應用程式基本資訊
/// - 業務規則常數（長度限制、格式要求）
/// - 快取鍵值常數
/// - API 相關常數
/// - 檔案系統常數
class AppConstants {
  // 防止實例化
  AppConstants._();

  /// === 應用程式基本資訊 ===

  /// 應用程式名稱
  static const String appName = 'BusinessCard Scanner';

  /// === 業務規則常數 ===

  /// 姓名長度限制
  static const int maxNameLength = 100;
  static const int minNameLength = 1;

  /// 公司名稱長度限制
  static const int maxCompanyNameLength = 200;
  static const int minCompanyNameLength = 2;

  /// 電子信箱長度限制（RFC 5321）
  static const int maxEmailLength = 254;
  static const int maxEmailLocalPartLength = 64;

  /// 電話號碼格式
  static const int minPhoneLength = 9;
  static const int maxPhoneLength = 13;

  /// OCR 文字識別限制
  static const int maxOcrTextLength = 10000;
  static const int minOcrConfidence = 60; // 最低信心度 60%

  /// === 檔案系統常數 ===

  /// 支援的圖片格式
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'heic',
    'webp',
  ];

  /// 最大檔案大小 (10MB)
  static const int maxImageFileSize = 10 * 1024 * 1024;

  /// 圖片壓縮品質
  static const int imageCompressionQuality = 85;

  /// === 快取鍵值常數 ===

  /// 使用者偏好設定
  static const String cacheKeyUserPreferences = 'user_preferences';

  /// AI 服務設定
  static const String cacheKeyAiSettings = 'ai_settings';

  /// 名片列表快取
  static const String cacheKeyCardList = 'card_list';

  /// OCR 結果快取前綴
  static const String cacheKeyOcrPrefix = 'ocr_result_';

  /// === API 相關常數 ===

  /// 請求逾時時間
  static const Duration apiTimeout = Duration(seconds: 30);

  /// 重試次數
  static const int maxRetryAttempts = 3;

  /// 重試延遲
  static const Duration retryDelay = Duration(seconds: 2);

  /// === 安全性常數 ===

  /// 內容大小限制（防止 DoS 攻擊）
  static const int maxContentSize = 100000; // 100KB

  /// 控制字元比例限制
  static const double maxControlCharRatio = 0.2; // 20%

  /// 密碼遮蔽符號
  static const String maskingSymbol = '***';

  /// === UI 相關常數 ===

  /// 動畫持續時間
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  /// 載入延遲（避免閃爍）
  static const Duration loadingDelay = Duration(milliseconds: 100);

  /// === 效能常數 ===

  /// 大檔案處理的效能限制
  static const Duration maxProcessingTime = Duration(milliseconds: 500);

  /// 並發處理限制
  static const int maxConcurrentOperations = 3;

  /// === 測試相關常數 ===

  /// 測試模式標識
  static const String testModeKey = 'TEST_MODE';

  /// 模擬延遲時間
  static const Duration testDelay = Duration(milliseconds: 100);
}
