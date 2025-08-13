import 'package:intl/intl.dart';

/// 日期時間處理工具類
/// 
/// 提供常用的日期時間操作功能，包括：
/// - 格式化顯示
/// - 相對時間計算
/// - 時區處理
/// - 業務日期邏輯
class DateTimeUtils {
  // 防止實例化
  DateTimeUtils._();

  /// 常用的日期格式
  static const String defaultDateFormat = 'yyyy-MM-dd';
  static const String defaultTimeFormat = 'HH:mm:ss';
  static const String defaultDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'yyyy年MM月dd日';
  static const String displayTimeFormat = 'HH:mm';
  static const String displayDateTimeFormat = 'yyyy年MM月dd日 HH:mm';
  static const String compactDateFormat = 'yyyyMMdd';
  static const String iso8601Format = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";

  /// 格式化日期為顯示字串
  static String formatDate(DateTime date, {String format = displayDateFormat}) {
    return DateFormat(format, 'zh_TW').format(date);
  }

  /// 格式化時間為顯示字串
  static String formatTime(DateTime dateTime, {String format = displayTimeFormat}) {
    return DateFormat(format, 'zh_TW').format(dateTime);
  }

  /// 格式化日期時間為顯示字串
  static String formatDateTime(DateTime dateTime, {String format = displayDateTimeFormat}) {
    return DateFormat(format, 'zh_TW').format(dateTime);
  }

  /// 格式化為 ISO 8601 字串
  static String formatToIso8601(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// 從 ISO 8601 字串解析日期時間
  static DateTime? parseIso8601(String dateString) {
    try {
      return DateTime.parse(dateString);
    } on FormatException {
      return null;
    }
  }

  /// 安全地解析日期字串
  static DateTime? parseDate(String dateString, {String format = defaultDateFormat}) {
    try {
      return DateFormat(format).parse(dateString);
    } on FormatException {
      return null;
    }
  }

  /// 獲取相對時間描述（如：2小時前、昨天、上週）
  static String getRelativeTime(DateTime dateTime, {DateTime? relativeTo}) {
    final now = relativeTo ?? DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      // 未來時間
      final futureDiff = dateTime.difference(now);
      if (futureDiff.inMinutes < 1) {
        return '即將';
      }
      if (futureDiff.inMinutes < 60) {
        return '${futureDiff.inMinutes}分鐘後';
      }
      if (futureDiff.inHours < 24) {
        return '${futureDiff.inHours}小時後';
      }
      if (futureDiff.inDays < 7) {
        return '${futureDiff.inDays}天後';
      }
      return formatDate(dateTime);
    }

    // 過去時間
    if (difference.inSeconds < 60) {
      return '剛剛';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分鐘前';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}小時前';
    }
    if (difference.inDays < 7) {
      if (difference.inDays == 1) {
        return '昨天';
      }
      if (difference.inDays == 2) {
        return '前天';
      }
      return '${difference.inDays}天前';
    }
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}週前';
    }
    if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}個月前';
    }
    
    final years = (difference.inDays / 365).floor();
    return years == 1 ? '1年前' : '$years年前';
  }

  /// 檢查是否為今天
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// 檢查是否為昨天
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  /// 檢查是否為本週
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
  }

  /// 檢查是否為本月
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// 檢查是否為本年
  static bool isThisYear(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }

  /// 獲取日期範圍的描述
  static String getDateRangeDescription(DateTime start, DateTime end) {
    if (isSameDay(start, end)) {
      return formatDate(start);
    }
    
    if (start.year == end.year) {
      if (start.month == end.month) {
        return '${start.year}年${start.month}月${start.day}日 - ${end.day}日';
      } else {
        return '${start.year}年${start.month}月${start.day}日 - ${end.month}月${end.day}日';
      }
    } else {
      return '${formatDate(start)} - ${formatDate(end)}';
    }
  }

  /// 檢查兩個日期是否為同一天
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  /// 獲取一天的開始時間 (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 獲取一天的結束時間 (23:59:59.999)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// 獲取一週的開始時間（週一 00:00:00）
  static DateTime startOfWeek(DateTime date) {
    final startDay = date.subtract(Duration(days: date.weekday - 1));
    return startOfDay(startDay);
  }

  /// 獲取一週的結束時間（週日 23:59:59.999）
  static DateTime endOfWeek(DateTime date) {
    final endDay = date.add(Duration(days: 7 - date.weekday));
    return endOfDay(endDay);
  }

  /// 獲取一個月的開始時間
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month);
  }

  /// 獲取一個月的結束時間
  static DateTime endOfMonth(DateTime date) {
    final nextMonth = date.month == 12 ? 1 : date.month + 1;
    final year = date.month == 12 ? date.year + 1 : date.year;
    return DateTime(year, nextMonth).subtract(const Duration(milliseconds: 1));
  }

  /// 計算兩個日期之間的工作日數量（週一到週五）
  static int getWorkingDays(DateTime start, DateTime end) {
    if (end.isBefore(start)) return 0;
    
    int workingDays = 0;
    DateTime current = startOfDay(start);
    final endDate = startOfDay(end);
    
    while (!current.isAfter(endDate)) {
      if (current.weekday >= 1 && current.weekday <= 5) {
        workingDays++;
      }
      current = current.add(const Duration(days: 1));
    }
    
    return workingDays;
  }

  /// 獲取時間戳（毫秒）
  static int getTimestamp(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch;
  }

  /// 從時間戳創建 DateTime
  static DateTime fromTimestamp(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// 驗證日期字串格式
  static bool isValidDateFormat(String dateString, String format) {
    try {
      DateFormat(format).parseStrict(dateString);
      return true;
    } on FormatException {
      return false;
    }
  }

  /// 計算年齡
  static int calculateAge(DateTime birthDate, {DateTime? asOf}) {
    final referenceDate = asOf ?? DateTime.now();
    int age = referenceDate.year - birthDate.year;
    
    if (referenceDate.month < birthDate.month ||
        (referenceDate.month == birthDate.month && referenceDate.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  /// 獲取季度
  static int getQuarter(DateTime date) {
    return ((date.month - 1) ~/ 3) + 1;
  }

  /// 獲取一年中的第幾週
  static int getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
  }
}