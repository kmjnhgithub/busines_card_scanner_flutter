import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';

/// 本地名片解析器
///
/// 使用正則表達式解析名片文字，作為 AI 服務不可用時的 fallback 方案
class LocalCardParser {
  /// 解析名片文字
  ParsedCardData parseCard(String ocrText) {
    if (ocrText.trim().isEmpty) {
      return ParsedCardData(
        confidence: 0,
        source: ParseSource.local,
        parsedAt: DateTime.now(),
      );
    }

    // 提取各項資訊
    final name = _extractName(ocrText);
    final company = _extractCompany(ocrText);
    final jobTitle = _extractJobTitle(ocrText);
    final email = _extractEmail(ocrText);
    final phone = _extractPhone(ocrText);
    final mobile = _extractMobile(ocrText);
    final address = _extractAddress(ocrText);
    final website = _extractWebsite(ocrText);

    // 建立解析資料
    final extracted = {
      'name': name,
      'company': company,
      'jobTitle': jobTitle,
      'email': email,
      'phone': phone,
      'mobile': mobile,
      'address': address,
      'website': website,
    };

    // 計算信心度
    final confidence = _calculateConfidence(extracted);

    return ParsedCardData(
      name: name,
      company: company,
      jobTitle: jobTitle,
      phone: phone,
      mobile: mobile,
      email: email,
      address: address,
      website: website,
      confidence: confidence,
      source: ParseSource.local,
      parsedAt: DateTime.now(),
    );
  }

  // 提取姓名
  String? _extractName(String text) {
    // 優先提取中文姓名
    final chineseName = _extractChineseName(text);
    if (chineseName != null) {
      return chineseName;
    }

    // 其次提取英文姓名
    return _extractEnglishName(text);
  }

  // 提取中文姓名
  String? _extractChineseName(String text) {
    // 常見中文姓氏
    const commonSurnames = [
      '王',
      '李',
      '張',
      '劉',
      '陳',
      '楊',
      '黃',
      '趙',
      '吳',
      '周',
      '徐',
      '孫',
      '馬',
      '朱',
      '胡',
      '郭',
      '何',
      '高',
      '林',
      '鄭',
      '謝',
      '羅',
      '梁',
      '宋',
      '唐',
      '許',
      '韓',
      '馮',
      '鄧',
      '曹',
      '彭',
      '曾',
      '蕭',
      '田',
      '董',
      '袁',
      '潘',
      '於',
      '蔣',
      '蔡',
      '余',
      '杜',
      '葉',
      '程',
      '蘇',
      '魏',
      '呂',
      '丁',
      '任',
      '沈',
      '姚',
      '盧',
      '傅',
      '鍾',
      '姜',
      '崔',
      '譚',
      '廖',
      '范',
      '汪',
      '陸',
      '金',
      '石',
      '戴',
      '賈',
      '韋',
      '夏',
      '付',
      '方',
      '鄒',
      '熊',
      '白',
      '孟',
      '秦',
      '邱',
      '江',
      '尹',
      '薛',
      '閆',
      '段',
      '雷',
      '侯',
      '龍',
      '史',
      '陶',
      '黎',
      '賀',
      '顧',
      '毛',
      '郝',
      '龔',
      '邵',
      '萬',
      '錢',
      '嚴',
      '覃',
      '武',
      '戚',
      '莫',
      '孔',
      '向',
      '湯',
    ];

    // 按行分割文字
    final lines = text.split('\n');

    // 嘗試找出中文姓名（2-4個中文字）
    for (final line in lines) {
      final trimmed = line.trim();
      // 檢查是否符合中文姓名格式
      if (RegExp(r'^[\u4e00-\u9fa5]{2,4}$').hasMatch(trimmed)) {
        // 檢查是否以常見姓氏開頭
        for (final surname in commonSurnames) {
          if (trimmed.startsWith(surname)) {
            return trimmed;
          }
        }
        // 如果沒有匹配的姓氏，但符合格式，也可能是姓名
        if (trimmed.length >= 2 && trimmed.length <= 4) {
          return trimmed;
        }
      }
      // 處理有空格的中文姓名
      final spacedName = RegExp(r'([\u4e00-\u9fa5])\s+([\u4e00-\u9fa5]+)');
      final spacedMatch = spacedName.firstMatch(trimmed);
      if (spacedMatch != null) {
        final fullName = '${spacedMatch.group(1)}${spacedMatch.group(2)}'
            .replaceAll(' ', '');
        if (fullName.length >= 2 && fullName.length <= 4) {
          return fullName;
        }
      }
    }

    return null;
  }

  // 提取英文姓名
  String? _extractEnglishName(String text) {
    // 英文姓名模式：首字母大寫的單詞組合
    final englishNamePattern = RegExp(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)\b');

    // 按行分割，優先尋找在文本開頭的姓名
    final lines = text.split('\n');
    for (final line in lines) {
      final match = englishNamePattern.firstMatch(line.trim());
      if (match != null) {
        final name = match.group(1)!;
        // 排除一些常見的非姓名詞彙
        if (!_isLikelyNotName(name)) {
          return name;
        }
      }
    }
    return null;
  }

  // 判斷是否可能不是姓名
  bool _isLikelyNotName(String text) {
    final nonNameWords = [
      'Road',
      'Street',
      'Avenue',
      'Drive',
      'Lane',
      'Place',
      'Rd',
      'St',
      'Ave',
      'Dr',
      'Ln',
      'Pl',
      'District',
      'City',
      'County',
      'Building',
      'Floor',
      'Room',
      'Suite',
      'Unit',
      'Company',
      'Corporation',
      'Inc',
      'Ltd',
      'Limited',
      'Phone',
      'Mobile',
      'Email',
      'Address',
      'Website',
      'Senior',
      'Software',
      'Engineer',
      'Manager',
      'Director',
      'Xinyi',
      'Dist',
      'No',
    ];

    for (final word in nonNameWords) {
      if (text.contains(word)) {
        return true;
      }
    }
    return false;
  }

  // 提取公司名稱
  String? _extractCompany(String text) {
    // 中文公司名稱模式 - 捕獲完整公司名稱
    final chineseCompanyPattern = RegExp(
      r'([\u4e00-\u9fa5A-Za-z0-9]+(?:有限公司|股份有限公司|企業|集團|科技|公司|工作室|事務所))',
    );
    final chineseMatch = chineseCompanyPattern.firstMatch(text);
    if (chineseMatch != null) {
      return chineseMatch.group(1);
    }

    // 英文公司名稱模式
    final englishCompanyPattern = RegExp(
      r'([A-Za-z0-9\s]+(?:Inc\.|LLC|Ltd\.|Limited|Corporation|Corp\.|Company|Co\.))',
      caseSensitive: false,
    );
    final englishMatch = englishCompanyPattern.firstMatch(text);
    if (englishMatch != null) {
      return englishMatch.group(1)?.trim();
    }

    return null;
  }

  // 提取職稱
  String? _extractJobTitle(String text) {
    // 職稱模式 - 改進以捕獲完整職稱
    final jobTitlePatterns = [
      RegExp(
        r'([\u4e00-\u9fa5]*(?:經理|總監|主管|專員|工程師|設計師|顧問|分析師|總裁|執行長|董事|秘書|助理|主任|組長|課長))',
      ),
      RegExp(
        r'((?:Senior\s+|Junior\s+|Lead\s+|Chief\s+|Vice\s+|Assistant\s+|Associate\s+)?(?:Software\s+|Hardware\s+|System\s+)?(?:Manager|Director|CEO|CTO|CFO|Engineer|Designer|Consultant|Analyst|Executive|President|Supervisor))',
        caseSensitive: false,
      ),
    ];

    for (final pattern in jobTitlePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }

    return null;
  }

  // 提取 Email
  String? _extractEmail(String text) {
    final emailPattern = RegExp(
      r'\b([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})\b',
      caseSensitive: false,
    );
    final match = emailPattern.firstMatch(text);
    return match?.group(1);
  }

  // 提取電話
  String? _extractPhone(String text) {
    // 台灣市話模式
    final phonePatterns = [
      RegExp(r'(?:Tel|電話|Phone)?:?\s*(\(?0[2-8]\)?[\s-]?\d{3,4}[\s-]?\d{4})'),
      RegExp(r'(\(?0[2-8]\)?[\s-]?\d{3,4}[\s-]?\d{4})'),
      RegExp(r'(\+?886[\s-]?[2-8][\s-]?\d{3,4}[\s-]?\d{4})'),
    ];

    for (final pattern in phonePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }

    return null;
  }

  // 提取手機
  String? _extractMobile(String text) {
    // 台灣手機模式
    final mobilePatterns = [
      RegExp(r'(?:Mobile|手機|行動)?:?\s*(09\d{2}[\s-]?\d{3}[\s-]?\d{3})'),
      RegExp(r'(09\d{2}[\s-]?\d{3}[\s-]?\d{3})'),
      RegExp(r'(\+?886[\s-]?9\d{2}[\s-]?\d{3}[\s-]?\d{3})'),
    ];

    for (final pattern in mobilePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }

    return null;
  }

  // 提取地址
  String? _extractAddress(String text) {
    // 地址模式
    final addressPatterns = [
      RegExp(
        r'(?:地址|Address)?:?\s*(.+(?:路|街|巷|弄|號|樓|室|Road|Street|Avenue|Lane|Floor|Room)[^\n]*)',
      ),
      RegExp(r'([\u4e00-\u9fa5]+(?:市|縣|區|鄉|鎮|村|里).+(?:路|街|巷|弄|號|樓|室)[^\n]*)'),
    ];

    for (final pattern in addressPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final address = match.group(1)?.trim();
        if (address != null && address.length >= 10) {
          return address;
        }
      }
    }

    return null;
  }

  // 提取網址
  String? _extractWebsite(String text) {
    // 分行處理，避免將 email 域名誤判為網址
    final lines = text.split('\n');

    for (final line in lines) {
      // 跳過包含 @ 的行（可能是 email）
      if (line.contains('@')) {
        continue;
      }

      // 尋找網址模式
      final websitePattern = RegExp(
        r'(?:https?:\/\/)?(?:www\.)?[a-zA-Z0-9][a-zA-Z0-9-]*(?:\.[a-zA-Z0-9][a-zA-Z0-9-]*)+(?:\/[^\s]*)?',
        caseSensitive: false,
      );

      final match = websitePattern.firstMatch(line);
      if (match != null) {
        return match.group(0);
      }
    }

    return null;
  }

  // 計算信心度分數
  double _calculateConfidence(Map<String, dynamic> extracted) {
    int fieldCount = 0;
    int filledCount = 0;

    // 檢查各個欄位
    final fields = [
      'name',
      'email',
      'phone',
      'mobile',
      'company',
      'jobTitle',
      'address',
    ];
    for (final field in fields) {
      fieldCount++;
      if (extracted[field] != null && extracted[field].toString().isNotEmpty) {
        filledCount++;
      }
    }

    if (fieldCount == 0) {
      return 0;
    }

    // 基礎分數根據填充率
    double confidence = filledCount / fieldCount;

    // 關鍵欄位加權（調整權重以避免過高的分數）
    if (extracted['name'] != null) {
      confidence += 0.1;
    }
    if (extracted['email'] != null) {
      confidence += 0.05;
    }
    if (extracted['phone'] != null || extracted['mobile'] != null) {
      confidence += 0.05;
    }

    // 確保分數在 0.0 到 1.0 之間
    return confidence.clamp(0.0, 1.0);
  }
}
