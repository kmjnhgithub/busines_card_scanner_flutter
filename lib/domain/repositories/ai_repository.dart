import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';

/// AI 服務 Repository 介面
///
/// 負責管理 AI 相關功能，包括名片資訊解析、智慧建議等。
/// 重要的安全性設計：
/// - **不暴露 API Key 管理方法**：確保 Domain 層不直接處理敏感資訊
/// - **輸入驗證**：所有輸入都經過安全檢查
/// - **錯誤處理**：不洩露 AI 服務的內部錯誤資訊
/// - **使用限制**：支援配額管理和頻率限制
abstract class AIRepository {
  /// 使用 AI 解析 OCR 文字為結構化名片資料
  ///
  /// [ocrText] OCR 識別的原始文字
  /// [hints] 可選的解析提示（如語言、國家等）
  ///
  /// 回傳解析後的名片資料，包含信心度評分
  ///
  /// Throws:
  /// - [AIServiceUnavailableFailure] 當 AI 服務無法使用
  /// - [InvalidInputFailure] 當輸入文字無效或包含惡意內容
  /// - [AIQuotaExceededFailure] 當 API 配額用盡
  /// - [AIRateLimitFailure] 當請求頻率超過限制
  Future<ParsedCardData> parseCardFromText(String ocrText, {ParseHints? hints});

  /// 批次解析多個 OCR 結果
  ///
  /// [ocrResults] OCR 結果列表
  /// [hints] 可選的解析提示
  ///
  /// 回傳批次解析結果
  Future<BatchParseResult> parseCardsFromTexts(
    List<OCRResult> ocrResults, {
    ParseHints? hints,
  });

  /// 智慧補全名片資訊
  ///
  /// [incompleteCard] 部分完成的名片資料
  /// [context] 可選的上下文資訊（如其他相關名片）
  ///
  /// 回傳建議的補全資訊
  Future<CardCompletionSuggestions> suggestCardCompletion(
    BusinessCard incompleteCard, {
    CompletionContext? context,
  });

  /// 驗證和清理 AI 解析結果
  ///
  /// [parsedData] AI 解析的原始結果
  ///
  /// 回傳驗證和清理後的安全資料
  Future<ParsedCardData> validateAndSanitizeResult(
    Map<String, dynamic> parsedData,
  );

  /// 取得 AI 服務狀態
  ///
  /// 回傳服務健康狀態，不包含敏感資訊（如 API Key 狀態）
  Future<AIServiceStatus> getServiceStatus();

  /// 取得可用的 AI 模型列表
  ///
  /// 回傳當前可用的 AI 模型資訊
  Future<List<AIModelInfo>> getAvailableModels();

  /// 設定偏好的 AI 模型
  ///
  /// [modelId] AI 模型的識別碼
  ///
  /// 設定後續的 AI 操作會優先使用指定模型
  Future<void> setPreferredModel(String modelId);

  /// 取得當前使用的 AI 模型
  Future<AIModelInfo> getCurrentModel();

  /// 取得使用統計（不含敏感資訊）
  ///
  /// 回傳 AI 服務使用統計，用於監控和優化
  Future<AIUsageStatistics> getUsageStatistics();

  /// 檢查輸入文字的安全性
  ///
  /// [text] 要檢查的文字內容
  ///
  /// 回傳 true 如果文字安全，可以發送給 AI 服務
  Future<bool> isTextSafeForProcessing(String text);

  /// 智慧糾錯和格式化
  ///
  /// [fieldName] 欄位名稱（如 'email', 'phone'）
  /// [rawValue] 原始值
  ///
  /// 回傳格式化後的值和信心度
  Future<FormattedFieldResult> formatField(String fieldName, String rawValue);

  /// 檢測重複名片
  ///
  /// [cardData] 要檢查的名片資料
  /// [existingCards] 現有名片列表
  ///
  /// 回傳重複檢測結果
  Future<DuplicateDetectionResult> detectDuplicates(
    ParsedCardData cardData,
    List<BusinessCard> existingCards,
  );

  /// 生成名片摘要或描述
  ///
  /// [card] 要生成摘要的名片
  ///
  /// 回傳智慧生成的摘要文字
  Future<String> generateCardSummary(BusinessCard card);
}

/// 解析提示
class ParseHints {
  /// 預期的語言代碼
  final String? language;

  /// 預期的國家/地區代碼
  final String? country;

  /// 名片類型提示（如 'business', 'personal'）
  final String? cardType;

  /// 行業提示（如 'technology', 'finance'）
  final String? industry;

  const ParseHints({this.language, this.country, this.cardType, this.industry});
}

/// 解析後的名片資料
class ParsedCardData {
  final String? name;
  final String? nameEnglish;
  final String? company;
  final String? companyEnglish;
  final String? jobTitle;
  final String? jobTitleEnglish;
  final String? department;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? fax;
  final String? address;
  final String? addressEnglish;
  final String? website;
  final String? notes;
  final double confidence;
  final ParseSource source;
  final DateTime parsedAt;
  final Map<String, double>? fieldConfidence;

  const ParsedCardData({
    required this.confidence,
    required this.source,
    required this.parsedAt,
    this.name,
    this.nameEnglish,
    this.company,
    this.companyEnglish,
    this.jobTitle,
    this.jobTitleEnglish,
    this.department,
    this.email,
    this.phone,
    this.mobile,
    this.fax,
    this.address,
    this.addressEnglish,
    this.website,
    this.notes,
    this.fieldConfidence,
  });

  /// 轉換為 BusinessCard 實體
  BusinessCard toBusinessCard({String? id}) {
    return BusinessCard(
      id: id ?? '',
      name: name ?? '',
      jobTitle: jobTitle,
      company: company,
      email: email,
      phone: phone ?? mobile,
      address: address,
      website: website,
      notes: notes,
      createdAt: parsedAt,
    );
  }
}

/// 解析來源
enum ParseSource { ai, local, manual, hybrid }

/// 批次解析結果
class BatchParseResult {
  final List<ParsedCardData> successful;
  final List<BatchParseError> failed;

  const BatchParseResult({required this.successful, required this.failed});

  bool get hasFailures => failed.isNotEmpty;
  int get successCount => successful.length;
  int get failureCount => failed.length;
}

/// 批次解析錯誤
class BatchParseError {
  final int index;
  final String error;
  final OCRResult? originalResult;

  const BatchParseError({
    required this.index,
    required this.error,
    this.originalResult,
  });
}

/// 名片補全建議
class CardCompletionSuggestions {
  final Map<String, List<String>> suggestions;
  final Map<String, double> confidence;

  const CardCompletionSuggestions({
    required this.suggestions,
    required this.confidence,
  });
}

/// 補全上下文
class CompletionContext {
  final List<BusinessCard>? relatedCards;
  final String? industry;
  final String? location;

  const CompletionContext({this.relatedCards, this.industry, this.location});
}

/// AI 服務狀態
class AIServiceStatus {
  final bool isAvailable;
  final String? error;
  final double responseTimeMs;
  final int remainingQuota;
  final DateTime quotaResetAt;
  final DateTime checkedAt;

  const AIServiceStatus({
    required this.isAvailable,
    required this.responseTimeMs,
    required this.remainingQuota,
    required this.quotaResetAt,
    required this.checkedAt,
    this.error,
  });
}

/// AI 模型資訊
class AIModelInfo {
  final String id;
  final String name;
  final String version;
  final List<String> supportedLanguages;
  final bool isAvailable;
  final Map<String, dynamic>? capabilities;

  const AIModelInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.supportedLanguages,
    required this.isAvailable,
    this.capabilities,
  });
}

/// AI 使用統計
class AIUsageStatistics {
  final int totalRequests;
  final int successfulRequests;
  final double averageConfidence;
  final double averageResponseTimeMs;
  final Map<String, int> modelUsage;
  final DateTime lastUpdated;

  const AIUsageStatistics({
    required this.totalRequests,
    required this.successfulRequests,
    required this.averageConfidence,
    required this.averageResponseTimeMs,
    required this.modelUsage,
    required this.lastUpdated,
  });
}

/// 格式化欄位結果
class FormattedFieldResult {
  final String formattedValue;
  final double confidence;
  final List<String>? suggestions;

  const FormattedFieldResult({
    required this.formattedValue,
    required this.confidence,
    this.suggestions,
  });
}

/// 重複檢測結果
class DuplicateDetectionResult {
  final bool hasDuplicates;
  final List<BusinessCard> potentialDuplicates;
  final Map<String, double> similarityScores;

  const DuplicateDetectionResult({
    required this.hasDuplicates,
    required this.potentialDuplicates,
    required this.similarityScores,
  });
}
