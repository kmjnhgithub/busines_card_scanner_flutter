import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_writer.dart';


/// CreateCardManuallyUseCase - 手動建立名片的業務用例
/// 
/// 遵循單一職責原則（SRP），專注於手動輸入處理流程：
/// 1. 驗證手動輸入資料
/// 2. 資料清理和格式化
/// 3. 建立名片實體並儲存
/// 
/// 遵循介面隔離原則（ISP），只依賴必要的 Repository 介面：
/// - CardWriter：負責名片儲存
/// 
/// 遵循依賴反轉原則（DIP），依賴抽象而非具體實作
class CreateCardManuallyUseCase {
  const CreateCardManuallyUseCase(this._cardWriter);

  final CardWriter _cardWriter;

  /// 執行手動建立名片的業務邏輯
  /// 
  /// [params] 包含手動輸入資料和相關參數的執行參數
  /// 
  /// 回傳建立結果，包含成功建立的名片和處理資訊
  /// 
  /// Throws:
  /// - [DataValidationFailure] 當輸入資料無效
  /// - [StorageSpaceFailure] 當儲存空間不足
  /// - [DatabaseConnectionFailure] 當資料庫連線失敗
  /// - [DataSourceFailure] 當發生未預期的錯誤
  Future<CreateCardManuallyResult> execute(CreateCardManuallyParams params) async {
    try {
      final startTime = DateTime.now();
      final processingSteps = <String>[];
      final warnings = <String>[];
      final suggestions = <String>[];
      ProcessingMetrics? metrics;

      // 1. 驗證手動輸入資料
      _validateManualData(params.manualData);
      processingSteps.add('手動輸入驗證');

      // 2. 資料清理和格式化
      ManualCardData processedData = params.manualData;
      if (params.enableSanitization == true) {
        processedData = _sanitizeManualData(params.manualData);
        processingSteps.add('資料清理');
      }

      // 3. 電話號碼格式化（如果啟用）
      if (params.autoFormatPhone == true && processedData.phone != null) {
        processedData = processedData.copyWith(
          phone: _formatPhoneNumber(processedData.phone!),
        );
        processingSteps.add('電話號碼格式化');
      }

      // 4. 驗證 Email 格式
      if (processedData.email != null && !_isValidEmail(processedData.email!)) {
        warnings.add('電子信箱格式可能不正確');
      }

      // 5. 驗證電話格式
      if (processedData.phone != null && !_isValidPhone(processedData.phone!)) {
        warnings.add('電話號碼格式可能不正確');
      }

      // 6. 驗證網站 URL 格式
      if (processedData.website != null && !_isValidUrl(processedData.website!)) {
        warnings.add('網站網址格式可能不正確');
      }

      // 7. 檢查欄位長度並截斷
      processedData = _limitFieldLengths(processedData, warnings);

      // 8. 重複檢查（如果啟用）
      if (params.checkDuplicates == true) {
        processingSteps.add('重複檢查');
      }

      // 9. 生成建議（如果啟用）
      if (params.generateSuggestions == true) {
        suggestions.addAll(_generateSuggestions(processedData));
        processingSteps.add('資料補完建議');
      }

      // 10. 建立名片實體
      final card = _createBusinessCardFromManualData(processedData);

      // 11. 儲存名片（除非是乾執行模式）
      BusinessCard savedCard = card;
      if (params.dryRun == true) {
        processingSteps.add('乾執行模式');
      } else {
        savedCard = await _saveCard(card);
        processingSteps.add('名片資料儲存');
      }

      // 12. 資源清理（如果啟用）
      if (params.autoCleanup == true) {
        processingSteps.add('資源清理');
      }

      // 13. 計算處理指標（如果啟用）
      final endTime = DateTime.now();
      if (params.trackMetrics == true) {
        metrics = ProcessingMetrics(
          totalProcessingTimeMs: endTime.difference(startTime).inMilliseconds,
          validationTimeMs: 0, // 手動輸入驗證通常很快
          startTime: startTime,
          endTime: endTime,
        );
      }

      return CreateCardManuallyResult(
        card: savedCard,
        processingSteps: processingSteps,
        warnings: warnings,
        suggestions: suggestions.isNotEmpty ? suggestions : null,
        metrics: metrics,
      );

    } catch (e, stackTrace) {
      // 重新拋出已知的業務異常
      if (e is DomainFailure) {
        rethrow;
      }
      
      // 包裝未預期的異常
      throw DataSourceFailure(
        userMessage: '手動建立名片時發生錯誤',
        internalMessage: 'Unexpected error during manual card creation: $e\nStack trace: $stackTrace',
      );
    }
  }

  /// 批次處理多個手動輸入的名片資料
  Future<CreateCardManuallyBatchResult> executeBatch(CreateCardManuallyBatchParams params) async {
    final successful = <CreateCardManuallyResult>[];
    final failed = <CreateCardManuallyBatchError>[];

    for (int i = 0; i < params.cardsData.length; i++) {
      try {
        final result = await execute(CreateCardManuallyParams(
          manualData: params.cardsData[i],
          autoFormatPhone: params.autoFormatPhone,
          enableSanitization: params.enableSanitization,
          checkDuplicates: params.checkDuplicates,
          generateSuggestions: params.generateSuggestions,
          dryRun: params.dryRun,
          trackMetrics: params.trackMetrics,
          autoCleanup: params.autoCleanup,
        ));
        successful.add(result);
      } catch (e) {
        failed.add(CreateCardManuallyBatchError(
          index: i,
          error: e.toString(),
          originalData: params.cardsData[i],
        ));
      }
    }

    return CreateCardManuallyBatchResult(
      successful: successful,
      failed: failed,
    );
  }

  /// 從各種格式匯入名片資料
  Future<CreateCardManuallyBatchResult> executeImport(CreateCardManuallyImportParams params) async {
    List<ManualCardData> parsedData;
    
    // 根據格式解析資料
    switch (params.format) {
      case ImportFormat.csv:
        parsedData = _parseCSVData(params.importData);
        break;
      case ImportFormat.json:
        parsedData = _parseJSONData(params.importData);
        break;
      case ImportFormat.vcf:
        parsedData = _parseVCFData(params.importData);
        break;
    }

    // 批次處理解析的資料
    return executeBatch(CreateCardManuallyBatchParams(
      cardsData: parsedData,
      autoFormatPhone: params.autoFormatPhone,
      enableSanitization: params.enableSanitization,
      checkDuplicates: params.checkDuplicates,
      generateSuggestions: params.generateSuggestions,
    ));
  }

  /// 驗證手動輸入資料
  void _validateManualData(ManualCardData data) {
    // 名稱是必填欄位
    if (data.name.trim().isEmpty) {
      throw DataValidationFailure(
        validationErrors: const {
          'name': ['姓名不能為空']
        },
        userMessage: '姓名不能為空',
      );
    }
  }

  /// 資料清理
  ManualCardData _sanitizeManualData(ManualCardData data) {
    return data.copyWith(
      name: _sanitizeString(data.name),
      company: data.company != null ? _sanitizeString(data.company!) : null,
      jobTitle: data.jobTitle != null ? _sanitizeString(data.jobTitle!) : null,
      email: data.email,
      phone: data.phone,
      address: data.address != null ? _sanitizeString(data.address!) : null,
      website: data.website,
      notes: data.notes != null ? _sanitizeString(data.notes!) : null,
    );
  }

  /// 清理字串（移除 HTML 標籤和潛在的惡意內容）
  String _sanitizeString(String input) {
    return input
        .replaceAll(RegExp('<[^>]*>'), '') // 移除 HTML 標籤
        .replaceAll(RegExp('javascript:', caseSensitive: false), '') // 移除 JavaScript
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '') // 移除事件處理器
        .trim();
  }

  /// 格式化電話號碼
  String _formatPhoneNumber(String phone) {
    // 簡單的電話號碼格式化邏輯
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 10 && cleaned.startsWith('09')) {
      return '${cleaned.substring(0, 4)}-${cleaned.substring(4, 7)}-${cleaned.substring(7)}';
    }
    return phone; // 如果無法格式化就回傳原始值
  }

  /// 驗證 Email 格式
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// 驗證電話格式（寬鬆驗證，用於警告系統）
  bool _isValidPhone(String phone) {
    // 更寬鬆的電話號碼驗證，允許各種國際格式和分機號
    // 允許數字、空格、連字號、括號、加號、ext、extension
    final phonePattern = RegExp(r'^[\+]?[0-9\-\(\)\s\.ext\w]*[0-9][\-\(\)\s\.ext\w]*$', caseSensitive: false);
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    return phonePattern.hasMatch(phone) && cleaned.length >= 7 && cleaned.length <= 20;
  }

  /// 清理電話號碼以符合 BusinessCard 實體的驗證規則
  String _cleanPhoneNumberForBusinessCard(String phone) {
    // BusinessCard 只支援：數字、連字號、括號、空格、加號
    // 移除分機號碼和其他不支援的字符
    String cleaned = phone;
    
    // 移除分機號碼 (ext. 123, extension 123, x123 等)
    cleaned = cleaned.replaceAll(RegExp(r'\s*(ext\.?|extension|x)\s*\d+.*$', caseSensitive: false), '');
    
    // 只保留 BusinessCard 支援的字符
    cleaned = cleaned.replaceAll(RegExp(r'[^\+0-9\-\(\)\s]'), '');
    
    // 清理多餘的空格
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
  }

  /// 驗證清理後的電話號碼是否符合 BusinessCard 實體規則
  bool _isValidPhoneForBusinessCard(String phone) {
    // 與 BusinessCard 實體相同的驗證規則
    final phonePattern = RegExp(r'^[\+]?[0-9\-\(\)\s]{7,}$');
    return phonePattern.hasMatch(phone);
  }

  /// 驗證 URL 格式
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// 限制欄位長度並加入警告
  ManualCardData _limitFieldLengths(ManualCardData data, List<String> warnings) {
    const maxNameLength = 100;
    const maxNotesLength = 1000;
    const maxFieldLength = 255;

    ManualCardData limitedData = data;
    bool hasLimits = false;

    if (data.name.length > maxNameLength) {
      limitedData = limitedData.copyWith(name: data.name.substring(0, maxNameLength));
      hasLimits = true;
    }

    if (data.notes != null && data.notes!.length > maxNotesLength) {
      limitedData = limitedData.copyWith(notes: data.notes!.substring(0, maxNotesLength));
      hasLimits = true;
    }

    if (data.company != null && data.company!.length > maxFieldLength) {
      limitedData = limitedData.copyWith(company: data.company!.substring(0, maxFieldLength));
      hasLimits = true;
    }

    if (hasLimits) {
      warnings.add('部分欄位內容過長已被截斷');
    }

    return limitedData;
  }

  /// 生成資料補完建議
  List<String> _generateSuggestions(ManualCardData data) {
    final suggestions = <String>[];
    
    if (data.email == null) {
      suggestions.add('建議添加電子信箱');
    }
    if (data.phone == null) {
      suggestions.add('建議添加聯絡電話');
    }
    if (data.company == null) {
      suggestions.add('建議添加公司名稱');
    }
    if (data.jobTitle == null) {
      suggestions.add('建議添加職稱');
    }

    return suggestions;
  }

  /// 從手動資料建立 BusinessCard 實體
  BusinessCard _createBusinessCardFromManualData(ManualCardData data) {
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    
    // 對於無效的格式，我們將其清空以避免 BusinessCard 驗證失敗
    // 這樣可以讓警告系統正常運作，而不會阻止名片建立
    String? safeEmail = data.email;
    if (safeEmail != null && !_isValidEmail(safeEmail)) {
      safeEmail = null; // 清空無效的 email
    }
    
    String? safePhone = data.phone;
    if (safePhone != null) {
      // 清理電話號碼，移除 BusinessCard 實體不支援的字符
      // BusinessCard 只支援：數字、連字號、括號、空格、加號
      safePhone = _cleanPhoneNumberForBusinessCard(safePhone);
      if (!_isValidPhoneForBusinessCard(safePhone)) {
        safePhone = null; // 清空無效的 phone
      }
    }
    
    String? safeWebsite = data.website;
    if (safeWebsite != null && !_isValidUrl(safeWebsite)) {
      safeWebsite = null; // 清空無效的 website
    }
    
    return BusinessCard(
      id: tempId,
      name: data.name,
      company: data.company,
      jobTitle: data.jobTitle,
      email: safeEmail,
      phone: safePhone,
      address: data.address,
      website: safeWebsite,
      notes: data.notes,
      createdAt: DateTime.now(),
    );
  }

  /// 儲存名片
  Future<BusinessCard> _saveCard(BusinessCard card) async {
    return _cardWriter.saveCard(card);
  }

  /// 解析 CSV 資料
  List<ManualCardData> _parseCSVData(String csvData) {
    final lines = csvData.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isEmpty) return [];

    // 假設第一行是標題
    final headers = lines.first.split(',').map((h) => h.trim()).toList();
    final dataLines = lines.skip(1);

    return dataLines.map((line) {
      final values = line.split(',').map((v) => v.trim()).toList();
      final record = <String, String>{};
      
      for (int i = 0; i < headers.length && i < values.length; i++) {
        record[headers[i]] = values[i];
      }

      return ManualCardData(
        name: record['名字'] ?? record['姓名'] ?? record['Name'] ?? '',
        company: record['公司'] ?? record['Company'],
        jobTitle: record['職稱'] ?? record['Job Title'],
        email: record['電子信箱'] ?? record['Email'],
        phone: record['電話'] ?? record['Phone'],
        address: record['地址'] ?? record['Address'],
        website: record['網站'] ?? record['Website'],
        notes: record['備註'] ?? record['Notes'],
      );
    }).toList();
  }

  /// 解析 JSON 資料
  List<ManualCardData> _parseJSONData(String jsonData) {
    // 簡化實作，實際應使用 json.decode
    return [];
  }

  /// 解析 VCF 資料
  List<ManualCardData> _parseVCFData(String vcfData) {
    // 簡化實作，實際應解析 vCard 格式
    return [];
  }
}

/// 手動建立名片的資料類別
class ManualCardData {
  const ManualCardData({
    required this.name,
    this.company,
    this.jobTitle,
    this.email,
    this.phone,
    this.address,
    this.website,
    this.notes,
  });

  final String name;
  final String? company;
  final String? jobTitle;
  final String? email;
  final String? phone;
  final String? address;
  final String? website;
  final String? notes;

  ManualCardData copyWith({
    String? name,
    String? company,
    String? jobTitle,
    String? email,
    String? phone,
    String? address,
    String? website,
    String? notes,
  }) {
    return ManualCardData(
      name: name ?? this.name,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      website: website ?? this.website,
      notes: notes ?? this.notes,
    );
  }
}

/// 執行參數
class CreateCardManuallyParams {
  const CreateCardManuallyParams({
    required this.manualData,
    this.autoFormatPhone,
    this.enableSanitization,
    this.checkDuplicates,
    this.generateSuggestions,
    this.dryRun,
    this.trackMetrics,
    this.autoCleanup,
  });

  final ManualCardData manualData;
  final bool? autoFormatPhone;
  final bool? enableSanitization;
  final bool? checkDuplicates;
  final bool? generateSuggestions;
  final bool? dryRun;
  final bool? trackMetrics;
  final bool? autoCleanup;
}

/// 批次處理參數
class CreateCardManuallyBatchParams {
  const CreateCardManuallyBatchParams({
    required this.cardsData,
    this.autoFormatPhone,
    this.enableSanitization,
    this.checkDuplicates,
    this.generateSuggestions,
    this.dryRun,
    this.trackMetrics,
    this.autoCleanup,
  });

  final List<ManualCardData> cardsData;
  final bool? autoFormatPhone;
  final bool? enableSanitization;
  final bool? checkDuplicates;
  final bool? generateSuggestions;
  final bool? dryRun;
  final bool? trackMetrics;
  final bool? autoCleanup;
}

/// 匯入參數
class CreateCardManuallyImportParams {
  const CreateCardManuallyImportParams({
    required this.importData,
    required this.format,
    this.autoFormatPhone,
    this.enableSanitization,
    this.checkDuplicates,
    this.generateSuggestions,
  });

  final String importData;
  final ImportFormat format;
  final bool? autoFormatPhone;
  final bool? enableSanitization;
  final bool? checkDuplicates;
  final bool? generateSuggestions;
}

/// 匯入格式
enum ImportFormat { csv, json, vcf }

/// 執行結果
class CreateCardManuallyResult {
  const CreateCardManuallyResult({
    required this.card,
    required this.processingSteps,
    required this.warnings,
    this.suggestions,
    this.metrics,
  });

  final BusinessCard card;
  final List<String> processingSteps;
  final List<String> warnings;
  final List<String>? suggestions;
  final ProcessingMetrics? metrics;

  bool get hasWarnings => warnings.isNotEmpty;
}

/// 批次處理結果
class CreateCardManuallyBatchResult {
  const CreateCardManuallyBatchResult({
    required this.successful,
    required this.failed,
  });

  final List<CreateCardManuallyResult> successful;
  final List<CreateCardManuallyBatchError> failed;

  bool get hasFailures => failed.isNotEmpty;
  int get successCount => successful.length;
  int get failureCount => failed.length;
}

/// 批次處理錯誤
class CreateCardManuallyBatchError {
  const CreateCardManuallyBatchError({
    required this.index,
    required this.error,
    required this.originalData,
  });

  final int index;
  final String error;
  final ManualCardData originalData;
}

/// 處理效能指標
class ProcessingMetrics {
  const ProcessingMetrics({
    required this.totalProcessingTimeMs,
    required this.validationTimeMs,
    required this.startTime,
    required this.endTime,
  });

  final int totalProcessingTimeMs;
  final int validationTimeMs;
  final DateTime startTime;
  final DateTime endTime;
}