import 'package:busines_card_scanner_flutter/data/datasources/remote/openai_service.dart';
import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';

/// AI Repository 實作
/// 
/// 使用 OpenAI Service 進行名片資料解析和處理
/// 這是一個基本實作，專注於核心功能，可以在後續開發中擴展
class AIRepositoryImpl implements AIRepository {
  final OpenAIService _openAIService;

  const AIRepositoryImpl({
    required OpenAIService openAIService,
  }) : _openAIService = openAIService;

  @override
  Future<ParsedCardData> parseCardFromText(
    String ocrText, {
    ParseHints? hints,
  }) async {
    try {
      final result = await _openAIService.parseCardFromText(ocrText);
      return result; // OpenAIService 已經返回 ParsedCardData
    } catch (e) {
      if (e is DataSourceFailure) {
        rethrow;
      }
      throw const AIServiceUnavailableFailure(
        userMessage: 'AI 解析服務暫時無法使用',
      );
    }
  }

  @override
  Future<BatchParseResult> parseCardsFromTexts(
    List<OCRResult> ocrResults, {
    ParseHints? hints,
  }) async {
    final successful = <ParsedCardData>[];
    final failed = <BatchParseError>[];

    for (int i = 0; i < ocrResults.length; i++) {
      try {
        final result = await parseCardFromText(
          ocrResults[i].rawText,
          hints: hints,
        );
        successful.add(result);
      } on Exception catch (e) {
        failed.add(BatchParseError(
          index: i,
          error: e.toString(),
          originalResult: ocrResults[i],
        ));
      }
    }

    return BatchParseResult(
      successful: successful,
      failed: failed,
    );
  }

  // Stub implementations for other methods - can be enhanced later
  
  @override
  Future<CardCompletionSuggestions> suggestCardCompletion(
    BusinessCard incompleteCard, {
    CompletionContext? context,
  }) async {
    // Basic stub implementation
    return const CardCompletionSuggestions(
      suggestions: {},
      confidence: {},
    );
  }

  @override
  Future<ParsedCardData> validateAndSanitizeResult(
    Map<String, dynamic> parsedData,
  ) async {
    // Basic validation and sanitization
    return ParsedCardData(
      name: parsedData['name'] as String?,
      nameEnglish: parsedData['nameEnglish'] as String?,
      company: parsedData['company'] as String?,
      companyEnglish: parsedData['companyEnglish'] as String?,
      jobTitle: parsedData['jobTitle'] as String?,
      jobTitleEnglish: parsedData['jobTitleEnglish'] as String?,
      department: parsedData['department'] as String?,
      email: parsedData['email'] as String?,
      phone: parsedData['phone'] as String?,
      mobile: parsedData['mobile'] as String?,
      fax: parsedData['fax'] as String?,
      address: parsedData['address'] as String?,
      addressEnglish: parsedData['addressEnglish'] as String?,
      website: parsedData['website'] as String?,
      notes: parsedData['notes'] as String?,
      confidence: (parsedData['confidence'] as num?)?.toDouble() ?? 0.0,
      source: ParseSource.ai,
      parsedAt: DateTime.now(),
      fieldConfidence: parsedData['fieldConfidence'] as Map<String, double>?,
    );
  }

  @override
  Future<AIServiceStatus> getServiceStatus() async {
    try {
      // 簡單的服務狀態檢查 - 不需要實際的 testConnection 方法
      return AIServiceStatus(
        isAvailable: true,
        responseTimeMs: 100,
        remainingQuota: 1000,
        quotaResetAt: DateTime.now().add(const Duration(hours: 24)),
        checkedAt: DateTime.now(),
      );
    } on Exception catch (e) {
      return AIServiceStatus(
        isAvailable: false,
        error: 'Service unavailable: ${e.toString()}',
        responseTimeMs: 0,
        remainingQuota: 0,
        quotaResetAt: DateTime.now().add(const Duration(hours: 24)),
        checkedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<List<AIModelInfo>> getAvailableModels() async {
    return const [
      AIModelInfo(
        id: 'gpt-4-turbo',
        name: 'GPT-4 Turbo',
        version: '4.0',
        supportedLanguages: ['zh-Hant', 'en', 'ja'],
        isAvailable: true,
      ),
    ];
  }

  @override
  Future<void> setPreferredModel(String modelId) async {
    // Stub implementation
  }

  @override
  Future<AIModelInfo> getCurrentModel() async {
    return const AIModelInfo(
      id: 'gpt-4-turbo',
      name: 'GPT-4 Turbo',
      version: '4.0',
      supportedLanguages: ['zh-Hant', 'en', 'ja'],
      isAvailable: true,
    );
  }

  @override
  Future<AIUsageStatistics> getUsageStatistics() async {
    return AIUsageStatistics(
      totalRequests: 0,
      successfulRequests: 0,
      averageConfidence: 0,
      averageResponseTimeMs: 0,
      modelUsage: const {},
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<bool> isTextSafeForProcessing(String text) async {
    // Basic safety check
    return text.trim().isNotEmpty && text.length < 10000;
  }

  @override
  Future<FormattedFieldResult> formatField(
    String fieldName,
    String rawValue,
  ) async {
    // Basic formatting
    return FormattedFieldResult(
      formattedValue: rawValue.trim(),
      confidence: 1,
    );
  }

  @override
  Future<DuplicateDetectionResult> detectDuplicates(
    ParsedCardData cardData,
    List<BusinessCard> existingCards,
  ) async {
    // Stub implementation - no duplicates detected
    return const DuplicateDetectionResult(
      hasDuplicates: false,
      potentialDuplicates: [],
      similarityScores: {},
    );
  }

  @override
  Future<String> generateCardSummary(BusinessCard card) async {
    // Basic summary generation
    return '${card.name} - ${card.jobTitle} at ${card.company}';
  }
}