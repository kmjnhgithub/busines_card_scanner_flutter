import 'dart:developer' as developer;

/// 日誌等級
enum LogLevel { debug, info, warning, error }

/// 日誌記錄工具類
///
/// 提供結構化的日誌記錄功能，包括：
/// - 分級日誌記錄（Debug、Info、Warning、Error）
/// - 安全的日誌輸出（避免敏感資訊洩露）
/// - 開發/生產環境區分
/// - 效能監控日誌
class LoggerUtils {
  // 防止實例化
  LoggerUtils._();

  /// 當前日誌等級（生產環境建議設為 info 以上）
  static LogLevel logLevel = LogLevel.debug;

  /// 是否啟用日誌記錄
  static bool enabled = true;

  /// 敏感關鍵字列表（會被自動遮蔽）
  static final List<String> _sensitiveKeywords = [
    'password',
    'pwd',
    'token',
    'key',
    'secret',
    'auth',
    'bearer',
    'api_key',
    'apikey',
  ];

  /// Debug 日誌
  static void debug(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.debug,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Info 日誌
  static void info(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.info,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Warning 日誌
  static void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.warning,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Error 日誌
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 記錄效能監控
  static void performance(String operation, Duration duration, {String? tag}) {
    info(
      'Performance: $operation completed in ${duration.inMilliseconds}ms',
      tag: tag ?? 'Performance',
    );
  }

  /// 記錄 API 請求
  static void apiRequest(
    String method,
    String url, {
    Map<String, dynamic>? headers,
  }) {
    final safeHeaders = headers != null ? _sanitizeData(headers) : null;
    debug(
      'API Request: $method $url${safeHeaders != null ? ' Headers: $safeHeaders' : ''}',
      tag: 'API',
    );
  }

  /// 記錄 API 回應
  static void apiResponse(String url, int statusCode, {String? responseBody}) {
    final safeBody = responseBody != null
        ? _sanitizeString(responseBody)
        : null;
    debug(
      'API Response: $url -> $statusCode${safeBody != null ? ' Body: ${_truncate(safeBody, 200)}' : ''}',
      tag: 'API',
    );
  }

  /// 記錄使用者動作
  static void userAction(String action, {Map<String, dynamic>? parameters}) {
    final safeParams = parameters != null ? _sanitizeData(parameters) : null;
    info(
      'User Action: $action${safeParams != null ? ' Params: $safeParams' : ''}',
      tag: 'User',
    );
  }

  /// 記錄安全事件
  static void security(String event, {String? details}) {
    final safeDetails = details != null ? _sanitizeString(details) : null;
    warning(
      'Security Event: $event${safeDetails != null ? ' Details: $safeDetails' : ''}',
      tag: 'Security',
    );
  }

  /// 內部日誌記錄方法
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!enabled || level.index < logLevel.index) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final levelString = level.name.toUpperCase();
    final tagString = tag != null ? '[$tag] ' : '';
    final safeMessage = _sanitizeString(message);

    final logMessage = '$timestamp $levelString: $tagString$safeMessage';

    // 使用 dart:developer 的 log 函數
    developer.log(
      logMessage,
      name: tag ?? 'App',
      level: _getDeveloperLogLevel(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 轉換到 dart:developer 的日誌等級
  static int _getDeveloperLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500; // FINE
      case LogLevel.info:
        return 800; // INFO
      case LogLevel.warning:
        return 900; // WARNING
      case LogLevel.error:
        return 1000; // SEVERE
    }
  }

  /// 清理字串中的敏感資訊
  static String _sanitizeString(String input) {
    String sanitized = input;

    for (final keyword in _sensitiveKeywords) {
      // 使用正規表達式匹配 key: value 或 key=value 格式
      final regex = RegExp(
        '($keyword${r')\s*[:=]\s*([^\s,})\]]+)'}',
        caseSensitive: false,
      );

      sanitized = sanitized.replaceAllMapped(regex, (match) {
        final key = match.group(1)!;
        return '$key: ***';
      });
    }

    return sanitized;
  }

  /// 清理 Map 中的敏感資訊
  static Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    data.forEach((key, value) {
      if (_isSensitiveKey(key)) {
        sanitized[key] = '***';
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeData(value);
      } else if (value is String) {
        sanitized[key] = _sanitizeString(value);
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  /// 檢查是否為敏感欄位名稱
  static bool _isSensitiveKey(String key) {
    final lowerKey = key.toLowerCase();
    return _sensitiveKeywords.any(lowerKey.contains);
  }

  /// 截斷過長的字串
  static String _truncate(String input, int maxLength) {
    if (input.length <= maxLength) {
      return input;
    }
    return '${input.substring(0, maxLength - 3)}...';
  }

  /// 獲取格式化的堆疊追蹤
  static String formatStackTrace(StackTrace stackTrace, {int maxLines = 10}) {
    final lines = stackTrace.toString().split('\n');
    final limitedLines = lines.take(maxLines).toList();
    return limitedLines.join('\n');
  }
}
