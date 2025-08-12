import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_writer.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/create_card_from_image_usecase.dart';

void main() {
  test('Debug CreateCardFromImageUseCase 問題', () async {
    print('📋 開始調試測試');
    
    try {
      // 建立基本的測試資料
      final testImageData = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, // JPEG header
        ...List.filled(100, 0x00), // 模擬圖片內容
      ]);
      print('✅ 測試圖片資料建立成功: ${testImageData.length} bytes');

      // 建立最簡單的 Mock 實作
      final mockCardWriter = SimpleMockCardWriter();
      final mockOCRRepository = SimpleMockOCRRepository();
      final mockAIRepository = SimpleMockAIRepository();
      
      print('✅ Mock 物件建立成功');

      // 建立 UseCase
      final useCase = CreateCardFromImageUseCase(
        mockCardWriter,
        mockOCRRepository,
        mockAIRepository,
      );
      print('✅ UseCase 建立成功');

      // 執行最基本的測試
      print('🚀 開始執行 UseCase...');
      final result = await useCase.execute(CreateCardFromImageParams(
        imageData: testImageData,
      ));
      
      print('✅ UseCase 執行成功!');
      print('   - 名片名稱: ${result.card.name}');
      print('   - OCR 信心度: ${result.ocrResult.confidence}');
      print('   - 處理步驟數: ${result.processingSteps.length}');
      
    } catch (e, stackTrace) {
      print('❌ 測試失敗!');
      print('錯誤類型: ${e.runtimeType}');
      print('錯誤內容: $e');
      print('Stack Trace:');
      print(stackTrace);
      rethrow;
    }
  });
}

// 超級簡單的 Mock 實作
class SimpleMockCardWriter implements CardWriter {
  @override
  Future<BusinessCard> saveCard(BusinessCard card) async {
    print('📝 MockCardWriter.saveCard called');
    return card.copyWith(
      id: 'mock-saved-id-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<BatchSaveResult> saveCards(List<BusinessCard> cards) async =>
      BatchSaveResult(successful: cards, failed: []);

  @override
  Future<bool> deleteCard(String cardId) async => true;

  @override
  Future<BatchDeleteResult> deleteCards(List<String> cardIds) async =>
      BatchDeleteResult(successful: cardIds, failed: []);

  @override
  Future<BusinessCard> updateCard(BusinessCard card) async => card;

  @override
  Future<bool> softDeleteCard(String cardId) async => true;

  @override
  Future<bool> restoreCard(String cardId) async => true;

  @override
  Future<int> purgeDeletedCards({int daysOld = 30}) async => 0;
}

class SimpleMockOCRRepository implements OCRRepository {
  @override
  Future<OCRResult> recognizeText(Uint8List imageData, {OCROptions? options}) async {
    print('🔍 MockOCRRepository.recognizeText called');
    return OCRResult(
      id: 'mock-ocr-${DateTime.now().millisecondsSinceEpoch}',
      rawText: '王大明\n科技公司\n軟體工程師',
      confidence: 0.85,
      processingTimeMs: 1000,
      processedAt: DateTime.now(),
    );
  }

  @override
  Future<BatchOCRResult> recognizeTexts(List<Uint8List> imageDataList, {OCROptions? options}) async =>
      BatchOCRResult(successful: [], failed: []);

  @override
  Future<OCRResult> saveOCRResult(OCRResult result) async {
    print('💾 MockOCRRepository.saveOCRResult called');
    return result;
  }

  @override
  Future<List<OCRResult>> getOCRHistory({int limit = 50, bool includeImages = false}) async => [];

  @override
  Future<OCRResult> getOCRResultById(String resultId, {bool includeImage = false}) async =>
      OCRResult(
        id: resultId,
        rawText: 'Mock Result',
        confidence: 0.8,
        processingTimeMs: 1000,
        processedAt: DateTime.now(),
      );

  @override
  Future<bool> deleteOCRResult(String resultId) async => true;

  @override
  Future<bool> clearOCRHistory() async => true;

  @override
  Future<OCRHealthStatus> checkServiceHealth() async => OCRHealthStatus(
        isHealthy: true,
        responseTimeMs: 100,
        checkedAt: DateTime.now(),
      );

  @override
  Future<Uint8List> preprocessImage(Uint8List imageData, {ImagePreprocessOptions? options}) async {
    print('⚙️ MockOCRRepository.preprocessImage called');
    return imageData;
  }

  @override
  Future<OCRStatistics> getStatistics() async => OCRStatistics(
        totalProcessed: 0,
        averageConfidence: 0.0,
        averageProcessingTimeMs: 0.0,
        engineUsage: {},
        languageConfidence: {},
        lastUpdated: DateTime.now(),
      );
}

class SimpleMockAIRepository implements AIRepository {
  @override
  Future<ParsedCardData> parseCardFromText(String ocrText, {ParseHints? hints}) async {
    print('🤖 MockAIRepository.parseCardFromText called');
    return ParsedCardData(
      name: '王大明',
      company: '科技公司',
      jobTitle: '軟體工程師',
      confidence: 0.9,
      source: ParseSource.ai,
      parsedAt: DateTime.now(),
    );
  }

  @override
  Future<BatchParseResult> parseCardsFromTexts(List<OCRResult> ocrResults, {ParseHints? hints}) async =>
      BatchParseResult(successful: [], failed: []);

  @override
  Future<CardCompletionSuggestions> suggestCardCompletion(BusinessCard incompleteCard, {CompletionContext? context}) async =>
      CardCompletionSuggestions(suggestions: {}, confidence: {});

  @override
  Future<ParsedCardData> validateAndSanitizeResult(Map<String, dynamic> parsedData) async {
    print('🔒 MockAIRepository.validateAndSanitizeResult called');
    return ParsedCardData(
      name: parsedData['name']?.toString() ?? 'Unknown',
      company: parsedData['company']?.toString(),
      jobTitle: parsedData['jobTitle']?.toString(),
      email: parsedData['email']?.toString(),
      phone: parsedData['phone']?.toString(),
      address: parsedData['address']?.toString(),
      website: parsedData['website']?.toString(),
      notes: parsedData['notes']?.toString(),
      confidence: 0.85,
      source: ParseSource.ai,
      parsedAt: DateTime.now(),
    );
  }

  @override
  Future<AIServiceStatus> getServiceStatus() async => AIServiceStatus(
        isAvailable: true,
        responseTimeMs: 200,
        remainingQuota: 1000,
        quotaResetAt: DateTime.now().add(Duration(hours: 1)),
        checkedAt: DateTime.now(),
      );

  @override
  Future<List<AIModelInfo>> getAvailableModels() async => [];

  @override
  Future<void> setPreferredModel(String modelId) async {}

  @override
  Future<AIModelInfo> getCurrentModel() async => AIModelInfo(
        id: 'mock-model',
        name: 'Mock Model',
        version: '1.0.0',
        supportedLanguages: ['zh-TW', 'en'],
        isAvailable: true,
      );

  @override
  Future<AIUsageStatistics> getUsageStatistics() async => AIUsageStatistics(
        totalRequests: 0,
        successfulRequests: 0,
        averageConfidence: 0.0,
        averageResponseTimeMs: 0.0,
        modelUsage: {},
        lastUpdated: DateTime.now(),
      );

  @override
  Future<bool> isTextSafeForProcessing(String text) async => true;

  @override
  Future<FormattedFieldResult> formatField(String fieldName, String rawValue) async =>
      FormattedFieldResult(formattedValue: rawValue, confidence: 0.9);

  @override
  Future<DuplicateDetectionResult> detectDuplicates(ParsedCardData cardData, List<BusinessCard> existingCards) async =>
      DuplicateDetectionResult(hasDuplicates: false, potentialDuplicates: [], similarityScores: {});

  @override
  Future<String> generateCardSummary(BusinessCard card) async => 'Mock summary for ${card.name}';
}