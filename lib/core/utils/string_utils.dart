/// 字串處理工具類
/// 
/// 提供常用的字串處理功能，包括：
/// - 格式化和清理
/// - 驗證和檢查
/// - 轉換和提取
class StringUtils {
  // 防止實例化
  StringUtils._();

  /// 清理字串中的多餘空白
  /// 
  /// 移除前後空白並將多個連續空白合併為單一空格
  static String cleanWhitespace(String input) {
    if (input.isEmpty) {
      return input;
    }
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 移除控制字元（保留換行符和製表符）
  static String removeControlCharacters(String input) {
    if (input.isEmpty) {
      return input;
    }
    return input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }

  /// 檢查字串是否為空或僅包含空白字元
  static bool isNullOrWhitespace(String? input) {
    return input?.trim().isEmpty ?? true;
  }

  /// 檢查字串是否僅包含數字
  static bool isNumericOnly(String input) {
    if (input.isEmpty) {
      return false;
    }
    return RegExp(r'^[0-9]+$').hasMatch(input);
  }

  /// 檢查字串是否包含中文字元
  static bool containsChinese(String input) {
    if (input.isEmpty) {
      return false;
    }
    return RegExp(r'[\u4e00-\u9fff]').hasMatch(input);
  }

  /// 檢查字串是否僅包含中英文字母、數字和基本標點符號
  static bool isSafeText(String input) {
    if (input.isEmpty) {
      return true;
    }
    // 檢查是否包含危險字元
    final dangerousChars = RegExp(r'[<>&"\\\x00-\x1F\x7F]');
    return !dangerousChars.hasMatch(input);
  }

  /// 截斷字串並添加省略號
  static String truncate(String input, int maxLength, {String suffix = '...'}) {
    if (input.length <= maxLength) {
      return input;
    }
    if (maxLength <= suffix.length) {
      return suffix.substring(0, maxLength);
    }
    return input.substring(0, maxLength - suffix.length) + suffix;
  }

  /// 格式化電話號碼（僅用於顯示）
  static String formatPhoneNumber(String phone) {
    if (phone.isEmpty) {
      return phone;
    }
    
    // 移除所有非數字字元
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // 台灣手機號碼格式 (09xxxxxxxx -> 09xx-xxx-xxx)
    if (cleanPhone.length == 10 && cleanPhone.startsWith('09')) {
      return '${cleanPhone.substring(0, 4)}-${cleanPhone.substring(4, 7)}-${cleanPhone.substring(7)}';
    }
    
    // 台灣市話格式 (0x-xxxxxxxx -> (0x) xxxx-xxxx)
    if (cleanPhone.length >= 9 && cleanPhone.startsWith('0') && !cleanPhone.startsWith('09')) {
      final areaCode = cleanPhone.substring(0, 2);
      final number = cleanPhone.substring(2);
      if (number.length >= 7) {
        final part1 = number.substring(0, 4);
        final part2 = number.substring(4);
        return '($areaCode) $part1-$part2';
      }
    }
    
    // 國際格式 (886xxxxxxxxxx)
    if (cleanPhone.length >= 12 && cleanPhone.startsWith('886')) {
      return '+${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 4)} ${cleanPhone.substring(4, 8)}-${cleanPhone.substring(8)}';
    }
    
    // 無法格式化，返回原始字串
    return phone;
  }

  /// 遮蔽敏感資訊
  static String maskSensitiveInfo(String input, {int visibleChars = 4}) {
    if (input.length <= visibleChars) {
      return '*' * input.length;
    }
    
    final visible = input.substring(input.length - visibleChars);
    final masked = '*' * (input.length - visibleChars);
    return masked + visible;
  }

  /// 提取英文名稱的首字母
  static String extractInitials(String name, {int maxInitials = 2}) {
    if (name.isEmpty) {
      return '';
    }
    
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words
        .where((word) => word.isNotEmpty)
        .take(maxInitials)
        .map((word) => word[0].toUpperCase())
        .join();
    
    return initials;
  }

  /// 判斷字串是否為有效的電子信箱格式（基礎檢查）
  static bool isValidEmailFormat(String email) {
    if (email.isEmpty) {
      return false;
    }
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z0-9]{1,}$').hasMatch(email);
  }

  /// 判斷字串是否為有效的網址格式（基礎檢查）
  static bool isValidUrlFormat(String url) {
    if (url.isEmpty) {
      return false;
    }
    return RegExp(r'^(https?|ftp)://[^\s/$.?#].[^\s]*$', caseSensitive: false).hasMatch(url);
  }

  /// 計算字串的位元組長度（UTF-8）
  static int getByteLength(String input) {
    return input.codeUnits.fold(0, (length, codeUnit) {
      if (codeUnit <= 0x7F) return length + 1;
      if (codeUnit <= 0x7FF) return length + 2;
      if (codeUnit <= 0xFFFF) return length + 3;
      return length + 4;
    });
  }

  /// 安全地比較兩個字串（防止時間攻擊）
  static bool safeEquals(String a, String b) {
    if (a.length != b.length) return false;
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// 清理檔案名稱，移除不安全字元
  static String sanitizeFileName(String fileName) {
    if (fileName.isEmpty) return 'unnamed';
    
    // 移除路徑分隔符號和其他危險字元
    const dangerousChars = r'[<>:"/\|?*\x00-\x1F]';
    String cleaned = fileName.replaceAll(RegExp(dangerousChars), '_');
    
    // 移除前後的點號和空白
    cleaned = cleaned.replaceAll(RegExp(r'^[.\s]+|[.\s]+$'), '');
    
    // 確保不為空
    if (cleaned.isEmpty) cleaned = 'unnamed';
    
    return cleaned;
  }

  /// 從文字中提取可能的電子信箱地址
  static List<String> extractEmails(String text) {
    if (text.isEmpty) return [];
    
    final emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    );
    
    return emailRegex
        .allMatches(text)
        .map((match) => match.group(0)!)
        .where(isValidEmailFormat)
        .toList();
  }

  /// 從文字中提取可能的電話號碼（支援國際格式）
  static List<String> extractPhoneNumbers(String text) {
    if (text.isEmpty) return [];
    
    // 支援多種國際電話格式的正則表達式
    final phoneRegex = RegExp(
      r'(?:\+?[\d\s\-\(\)]{7,})',
    );
    
    return phoneRegex
        .allMatches(text)
        .map((match) => match.group(0)!.trim())
        .where((phone) {
          // 移除所有非數字字元來計算長度
          final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
          // 電話號碼至少要有7位數字
          return digitsOnly.length >= 7;
        })
        .toList();
  }
}