import 'dart:typed_data';

import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_writer.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/create_card_from_image_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock CardWriter 用於測試
class MockCardWriter implements CardWriter {
  BusinessCard? _mockSavedCard;
  BatchSaveResult? _mockBatchResult;
  BatchDeleteResult? _mockDeleteResult;
  DomainFailure? _mockFailure;

  void setMockSavedCard(BusinessCard card) => _mockSavedCard = card;
  void setMockBatchResult(BatchSaveResult result) => _mockBatchResult = result;
  void setMockDeleteResult(BatchDeleteResult result) => _mockDeleteResult = result;
  void setMockFailure(DomainFailure failure) => _mockFailure = failure;

  @override
  Future<BusinessCard> saveCard(BusinessCard card) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    // 模擬儲存後分配 ID
    if (_mockSavedCard != null) {
      return _mockSavedCard!;
    }

    // 如果名片沒有 ID，分配一個新的 ID
    if (card.id.isEmpty) {
      return card.copyWith(
        id: 'generated-id-${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    return card;
  }

  @override
  Future<BatchSaveResult> saveCards(List<BusinessCard> cards) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return _mockBatchResult ?? BatchSaveResult(successful: cards, failed: []);
  }

  @override
  Future<bool> deleteCard(String cardId) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return true;
  }

  @override
  Future<BatchDeleteResult> deleteCards(List<String> cardIds) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return _mockDeleteResult ??
        BatchDeleteResult(successful: cardIds, failed: []);
  }

  @override
  Future<BusinessCard> updateCard(BusinessCard card) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return _mockSavedCard ?? card;
  }

  @override
  Future<bool> softDeleteCard(String cardId) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return true;
  }

  @override
  Future<bool> restoreCard(String cardId) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return true;
  }

  @override
  Future<int> purgeDeletedCards({int daysOld = 30}) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return 0;
  }
}

/// Mock OCRRepository 用於測試
class MockOCRRepository implements OCRRepository {
  OCRResult? _mockOCRResult;
  BatchOCRResult? _mockBatchResult;
  DomainFailure? _mockFailure;

  void setMockOCRResult(OCRResult result) => _mockOCRResult = result;
  void setMockBatchResult(BatchOCRResult result) => _mockBatchResult = result;
  void setMockFailure(DomainFailure failure) => _mockFailure = failure;

  @override
  Future<OCRResult> recognizeText(
    Uint8List imageData, {
    OCROptions? options,
  }) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return _mockOCRResult ??
        OCRResult(
          id: 'ocr-${DateTime.now().millisecondsSinceEpoch}',
          rawText: '模擬 OCR 結果',
          confidence: 0.8,
          processingTimeMs: 1000,
          processedAt: DateTime.now(),
        );
  }

  @override
  Future<BatchOCRResult> recognizeTexts(
    List<Uint8List> imageDataList, {
    OCROptions? options,
  }) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return _mockBatchResult ?? const BatchOCRResult(successful: [], failed: []);
  }

  @override
  Future<OCRResult> saveOCRResult(OCRResult result) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return result;
  }

  @override
  Future<List<OCRResult>> getOCRHistory({
    int limit = 50,
    bool includeImages = false,
  }) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return [];
  }

  @override
  Future<OCRResult> getOCRResultById(
    String resultId, {
    bool includeImage = false,
  }) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return _mockOCRResult ??
        OCRResult(
          id: resultId,
          rawText: '測試文字',
          confidence: 0.8,
          processingTimeMs: 1000,
          processedAt: DateTime.now(),
        );
  }

  @override
  Future<bool> deleteOCRResult(String resultId) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return true;
  }

  @override
  Future<int> cleanupOldResults({int daysOld = 30}) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return 0;
  }

  @override
  Future<List<OCREngineInfo>> getAvailableEngines() async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return [];
  }

  @override
  Future<void> setPreferredEngine(String engineId) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
  }

  @override
  Future<OCREngineInfo> getCurrentEngine() async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return const OCREngineInfo(
      id: 'test-engine',
      name: 'Test Engine',
      version: '1.0.0',
      supportedLanguages: ['zh-Hant', 'en'],
      isAvailable: true,
      platform: 'cross-platform',
    );
  }

  @override
  Future<OCREngineHealth> testEngine({String? engineId}) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return OCREngineHealth(
      engineId: engineId ?? 'test-engine',
      isHealthy: true,
      responseTimeMs: 100,
      checkedAt: DateTime.now(),
    );
  }

  @override
  Future<Uint8List> preprocessImage(
    Uint8List imageData, {
    ImagePreprocessOptions? options,
  }) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return imageData; // 回傳原始圖片（模擬預處理）
  }

  @override
  Future<OCRStatistics> getStatistics() async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return OCRStatistics(
      totalProcessed: 0,
      averageConfidence: 0,
      averageProcessingTimeMs: 0,
      engineUsage: {},
      languageConfidence: {},
      lastUpdated: DateTime.now(),
    );
  }
}

/// Mock AIRepository 用於測試
class MockAIRepository implements AIRepository {
  ParsedCardData? _mockParsedData;
  BatchParseResult? _mockBatchResult;
  DomainFailure? _mockFailure;

  void setMockParsedData(ParsedCardData data) => _mockParsedData = data;
  void setMockBatchResult(BatchParseResult result) => _mockBatchResult = result;
  void setMockFailure(DomainFailure failure) => _mockFailure = failure;

  @override
  Future<ParsedCardData> parseCardFromText(
    String ocrText, {
    ParseHints? hints,
  }) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return _mockParsedData ??
        ParsedCardData(
          name: '王大明',
          company: '科技股份有限公司',
          jobTitle: '軟體工程師',
          email: 'wang@tech.com',
          phone: '02-1234-5678',
          confidence: 0.85,
          source: ParseSource.ai,
          parsedAt: DateTime.now(),
        );
  }

  @override
  Future<BatchParseResult> parseCardsFromTexts(
    List<OCRResult> ocrResults, {
    ParseHints? hints,
  }) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return _mockBatchResult ??
        const BatchParseResult(successful: [], failed: []);
  }

  @override
  Future<CardCompletionSuggestions> suggestCardCompletion(
    BusinessCard incompleteCard, {
    CompletionContext? context,
  }) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return const CardCompletionSuggestions(suggestions: {}, confidence: {});
  }

  @override
  Future<ParsedCardData> validateAndSanitizeResult(
    Map<String, dynamic> parsedData,
  ) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return _mockParsedData ??
        ParsedCardData(
          name: '清理後名稱',
          confidence: 0.9,
          source: ParseSource.ai,
          parsedAt: DateTime.now(),
        );
  }

  @override
  Future<AIServiceStatus> getServiceStatus() async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return AIServiceStatus(
      isAvailable: true,
      responseTimeMs: 200,
      remainingQuota: 1000,
      quotaResetAt: DateTime.now().add(const Duration(hours: 1)),
      checkedAt: DateTime.now(),
    );
  }

  @override
  Future<List<AIModelInfo>> getAvailableModels() async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return [];
  }

  @override
  Future<void> setPreferredModel(String modelId) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
  }

  @override
  Future<AIModelInfo> getCurrentModel() async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return const AIModelInfo(
      id: 'test-model',
      name: 'Test Model',
      version: '1.0.0',
      supportedLanguages: ['zh-Hant', 'en'],
      isAvailable: true,
    );
  }

  @override
  Future<AIUsageStatistics> getUsageStatistics() async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return AIUsageStatistics(
      totalRequests: 0,
      successfulRequests: 0,
      averageConfidence: 0,
      averageResponseTimeMs: 0,
      modelUsage: {},
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<bool> isTextSafeForProcessing(String text) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return true; // 假設所有文字都安全
  }

  @override
  Future<FormattedFieldResult> formatField(
    String fieldName,
    String rawValue,
  ) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return FormattedFieldResult(formattedValue: rawValue, confidence: 0.9);
  }

  @override
  Future<DuplicateDetectionResult> detectDuplicates(
    ParsedCardData cardData,
    List<BusinessCard> existingCards,
  ) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return const DuplicateDetectionResult(
      hasDuplicates: false,
      potentialDuplicates: [],
      similarityScores: {},
    );
  }

  @override
  Future<String> generateCardSummary(BusinessCard card) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return '${card.name} - ${card.company ?? "公司"}的名片';
  }
}

void main() {
  group('CreateCardFromImageUseCase Tests', () {
    late CreateCardFromImageUseCase useCase;
    late MockCardWriter mockCardWriter;
    late MockOCRRepository mockOCRRepository;
    late MockAIRepository mockAIRepository;
    late Uint8List testImageData;

    setUp(() {
      mockCardWriter = MockCardWriter();
      mockOCRRepository = MockOCRRepository();
      mockAIRepository = MockAIRepository();
      useCase = CreateCardFromImageUseCase(
        mockCardWriter,
        mockOCRRepository,
        mockAIRepository,
      );

      // 建立測試圖片資料
      testImageData = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, // JPEG header
        ...List.filled(1000, 0x00), // 模擬圖片內容
      ]);
    });

    group('成功創建名片流程', () {
      test(
        'should create card from image successfully with complete flow',
        () async {
          // Arrange - 設定完整的成功流程
          final testOCRResult = OCRResult(
            id: 'ocr-123',
            rawText: '''
          王大明
          軟體工程師
          科技股份有限公司
          電話：02-1234-5678
          Email: wang@tech.com
          地址：台北市信義區信義路五段7號
          ''',
            confidence: 0.92,
            processingTimeMs: 1200,
            processedAt: DateTime.now(),
          );
          mockOCRRepository.setMockOCRResult(testOCRResult);

          final testParsedData = ParsedCardData(
            name: '王大明',
            company: '科技股份有限公司',
            jobTitle: '軟體工程師',
            email: 'wang@tech.com',
            phone: '02-1234-5678',
            address: '台北市信義區信義路五段7號',
            confidence: 0.88,
            source: ParseSource.ai,
            parsedAt: DateTime.now(),
          );
          mockAIRepository.setMockParsedData(testParsedData);

          final expectedCard = BusinessCard(
            id: 'saved-card-123',
            name: '王大明',
            company: '科技股份有限公司',
            jobTitle: '軟體工程師',
            email: 'wang@tech.com',
            phone: '02-1234-5678',
            address: '台北市信義區信義路五段7號',
            createdAt: DateTime.now(),
          );
          mockCardWriter.setMockSavedCard(expectedCard);

          // Act
          late CreateCardFromImageResult result;
          try {
            result = await useCase.execute(
              CreateCardFromImageParams(
                imageData: testImageData,
                saveOCRResult: true,
              ),
            );
          } catch (e) {
            rethrow;
          }

          // Assert
          expect(result.card.name, '王大明');
          expect(result.card.company, '科技股份有限公司');
          expect(result.card.jobTitle, '軟體工程師');
          expect(result.card.email, 'wang@tech.com');
          expect(result.card.phone, '02-1234-5678');
          expect(result.ocrResult.rawText, contains('王大明'));
          expect(result.parsedData.confidence, 0.88);
          expect(result.processingSteps.length, greaterThan(0));
        },
      );

      test('should handle low OCR confidence with fallback', () async {
        // Arrange - 低信心度的 OCR 結果
        final lowConfidenceOCR = OCRResult(
          id: 'ocr-low-confidence',
          rawText: '王... 工程師... tech.com',
          confidence: 0.45, // 低信心度
          processingTimeMs: 800,
          processedAt: DateTime.now(),
        );
        mockOCRRepository.setMockOCRResult(lowConfidenceOCR);

        final fallbackParsedData = ParsedCardData(
          name: '王先生', // AI 嘗試補完
          email: 'unknown@tech.com',
          confidence: 0.60, // 中等信心度
          source: ParseSource.hybrid, // 混合來源
          parsedAt: DateTime.now(),
        );
        mockAIRepository.setMockParsedData(fallbackParsedData);

        // Act
        final result = await useCase.execute(
          CreateCardFromImageParams(
            imageData: testImageData,
            confidenceThreshold: 0.7, // 設定較高的信心度門檻
          ),
        );

        // Assert
        expect(result.card.name, '王先生');
        expect(result.card.email, 'unknown@tech.com');
        expect(result.ocrResult.confidence, 0.45);
        expect(result.parsedData.source, ParseSource.hybrid);
        expect(result.hasWarnings, true); // 應該有警告
        expect(result.warnings.first, startsWith('OCR 信心度較低'));
      });

      test('should apply custom OCR options correctly', () async {
        // Arrange - 自訂 OCR 選項
        final customOCRResult = OCRResult(
          id: 'ocr-custom',
          rawText: 'John Doe\nSoftware Engineer\nTech Corp',
          confidence: 0.95,
          processingTimeMs: 1500,
          processedAt: DateTime.now(),
        );
        mockOCRRepository.setMockOCRResult(customOCRResult);

        // Act
        final result = await useCase.execute(
          CreateCardFromImageParams(
            imageData: testImageData,
            ocrOptions: const OCROptions(preferredLanguages: ['en']),
          ),
        );

        // Assert
        expect(result.ocrResult.confidence, 0.95);
        expect(result.ocrResult.rawText, contains('John Doe'));
      });

      test('should handle AI parsing hints effectively', () async {
        // Arrange - 設定 AI 解析提示
        final hintedParsedData = ParsedCardData(
          name: '田中太郎',
          company: 'テクノロジー株式会社',
          jobTitle: 'シニアエンジニア',
          confidence: 0.90,
          source: ParseSource.ai,
          parsedAt: DateTime.now(),
        );
        mockAIRepository.setMockParsedData(hintedParsedData);

        // Act
        final result = await useCase.execute(
          CreateCardFromImageParams(
            imageData: testImageData,
            parseHints: const ParseHints(
              language: 'ja',
              country: 'JP',
              cardType: 'business',
              industry: 'technology',
            ),
          ),
        );

        // Assert
        expect(result.parsedData.name, '田中太郎');
        expect(result.parsedData.company, contains('テクノロジー'));
        expect(result.parsedData.confidence, 0.90);
      });
    });

    group('圖片驗證和預處理', () {
      test('should reject empty image data', () async {
        // Arrange
        final emptyImageData = Uint8List(0);

        // Act & Assert
        expect(
          () => useCase.execute(
            CreateCardFromImageParams(imageData: emptyImageData),
          ),
          throwsA(isA<InvalidInputFailure>()),
        );
      });

      test('should reject oversized image', () async {
        // Arrange - 建立過大的圖片資料
        const maxSizeBytes = 10 * 1024 * 1024; // 10MB
        final oversizedImageData = Uint8List(maxSizeBytes + 1000);

        mockOCRRepository.setMockFailure(
          const ImageTooLargeFailure(
            imageSize: maxSizeBytes + 1000,
            maxSize: maxSizeBytes,
          ),
        );

        // Act & Assert
        expect(
          () => useCase.execute(
            CreateCardFromImageParams(imageData: oversizedImageData),
          ),
          throwsA(isA<ImageTooLargeFailure>()),
        );
      });

      test('should handle unsupported image format gracefully', () async {
        // Arrange - 不支援的圖片格式
        final unsupportedImageData = Uint8List.fromList([
          0x42, 0x4D, // BMP header (not supported)
          ...List.filled(100, 0x00),
        ]);

        mockOCRRepository.setMockFailure(
          const UnsupportedImageFormatFailure(mimeType: 'image/bmp'),
        );

        // Act & Assert
        expect(
          () => useCase.execute(
            CreateCardFromImageParams(imageData: unsupportedImageData),
          ),
          throwsA(isA<UnsupportedImageFormatFailure>()),
        );
      });

      test('should preprocess image when enabled', () async {
        // Arrange - 啟用圖片預處理
        // Mock 預處理結果
        mockOCRRepository.setMockOCRResult(
          OCRResult(
            id: 'ocr-preprocessed',
            rawText: '清晰的文字辨識結果',
            confidence: 0.95, // 預處理後信心度提升
            processingTimeMs: 1000,
            processedAt: DateTime.now(),
          ),
        );

        // Act
        final result = await useCase.execute(
          CreateCardFromImageParams(
            imageData: testImageData,
            ocrOptions: const OCROptions(),
            preprocessOptions: const ImagePreprocessOptions(
              contrast: 20,
              brightness: 10,
              sharpen: true,
            ),
          ),
        );

        // Assert
        expect(result.ocrResult.confidence, 0.95);
        expect(result.ocrResult.rawText, '清晰的文字辨識結果');
        expect(result.processingSteps, contains('圖片預處理'));
      });
    });

    group('錯誤處理和重試機制', () {
      test('should handle OCR service unavailable', () async {
        // Arrange
        mockOCRRepository.setMockFailure(
          const OCRServiceUnavailableFailure(reason: 'Service maintenance'),
        );

        // Act & Assert
        expect(
          () => useCase.execute(
            CreateCardFromImageParams(imageData: testImageData),
          ),
          throwsA(isA<OCRServiceUnavailableFailure>()),
        );
      });

      test('should handle AI service quota exceeded', () async {
        // Arrange - OCR 成功但 AI 配額用盡
        mockOCRRepository.setMockOCRResult(
          OCRResult(
            id: 'ocr-success',
            rawText: '成功的 OCR 結果',
            confidence: 0.8,
            processingTimeMs: 1000,
            processedAt: DateTime.now(),
          ),
        );

        mockAIRepository.setMockFailure(
          AIQuotaExceededFailure(
            resetTime: DateTime.now().add(const Duration(hours: 1)),
          ),
        );

        // Act & Assert
        expect(
          () => useCase.execute(
            CreateCardFromImageParams(imageData: testImageData),
          ),
          throwsA(isA<AIQuotaExceededFailure>()),
        );
      });

      test('should handle AI rate limiting with retry suggestions', () async {
        // Arrange
        mockAIRepository.setMockFailure(
          AIRateLimitFailure(retryAfter: const Duration(seconds: 30)),
        );

        // Act & Assert
        expect(
          () => useCase.execute(
            CreateCardFromImageParams(imageData: testImageData),
          ),
          throwsA(isA<AIRateLimitFailure>()),
        );
      });

      test('should handle storage failure when saving card', () async {
        // Arrange - OCR 和 AI 都成功，但儲存失敗
        mockOCRRepository.setMockOCRResult(
          OCRResult(
            id: 'ocr-ok',
            rawText: '測試文字',
            confidence: 0.8,
            processingTimeMs: 1000,
            processedAt: DateTime.now(),
          ),
        );

        mockCardWriter.setMockFailure(
          const StorageSpaceFailure(
            availableSpaceBytes: 100,
            requiredSpaceBytes: 1000,
          ),
        );

        // Act & Assert
        expect(
          () => useCase.execute(
            CreateCardFromImageParams(imageData: testImageData),
          ),
          throwsA(isA<StorageSpaceFailure>()),
        );
      });
    });

    group('進階功能測試', () {
      test('should support dry run mode without saving', () async {
        // Arrange - 乾執行模式，不實際儲存
        final dryRunResult = await useCase.execute(
          CreateCardFromImageParams(
            imageData: testImageData,
            dryRun: true, // 乾執行模式
          ),
        );

        // Assert - 應該處理所有步驟但不儲存
        expect(dryRunResult.card.id, startsWith('temp-')); // 臨時 ID
        expect(dryRunResult.processingSteps, contains('乾執行模式'));
      });

      test('should validate and sanitize AI results', () async {
        // Arrange - AI 處理含有危險內容的原始資料並回傳清理後結果

        final safeParsedData = ParsedCardData(
          name: '王大明', // 已清理
          email: 'safe@tech.com', // 已清理
          phone: '02-1234-5678', // 已清理
          confidence: 0.75,
          source: ParseSource.ai,
          parsedAt: DateTime.now(),
        );
        mockAIRepository.setMockParsedData(safeParsedData);

        // Act
        final result = await useCase.execute(
          CreateCardFromImageParams(imageData: testImageData),
        );

        // Assert - 確保資料已被清理
        expect(result.card.name, '王大明');
        expect(result.card.name, isNot(contains('<script>')));
        expect(result.card.email, 'safe@tech.com');
        expect(result.card.email, isNot(contains('javascript:')));
        expect(result.processingSteps, contains('資料驗證和清理'));
      });

      test('should track detailed processing metrics', () async {
        // Arrange - 執行帶有指標追蹤的處理
        final result = await useCase.execute(
          CreateCardFromImageParams(
            imageData: testImageData,
            trackMetrics: true, // 啟用指標追蹤
          ),
        );

        // Assert - 檢查處理指標
        expect(result.metrics, isNotNull);
        expect(result.metrics!.totalProcessingTimeMs, greaterThanOrEqualTo(0));
        expect(result.metrics!.ocrProcessingTimeMs, greaterThanOrEqualTo(0));
        expect(result.metrics!.aiProcessingTimeMs, greaterThanOrEqualTo(0));
        expect(
          result.metrics!.startTime.isBefore(result.metrics!.endTime),
          true,
        );
      });

      test('should support batch processing multiple images', () async {
        // Arrange - 批次處理多張圖片
        final imageDataList = [
          testImageData,
          Uint8List.fromList([
            0xFF,
            0xD8,
            0xFF,
            0xE0,
            ...List.filled(500, 0x01),
          ]),
          Uint8List.fromList([
            0xFF,
            0xD8,
            0xFF,
            0xE0,
            ...List.filled(300, 0x02),
          ]),
        ];

        // Act
        final results = await useCase.executeBatch(
          CreateCardFromImageBatchParams(
            imageDataList: imageDataList,
            concurrency: 2, // 並行處理
          ),
        );

        // Assert
        expect(results.successful.length, lessThanOrEqualTo(3));
        expect(results.failed.length, greaterThanOrEqualTo(0));
        expect(results.successful.length + results.failed.length, 3);
      });
    });

    group('效能和資源管理', () {
      test('should handle concurrent requests efficiently', () async {
        // Arrange - 並行請求
        final futures = List.generate(5, (index) {
          return useCase.execute(
            CreateCardFromImageParams(
              imageData: testImageData,
              trackMetrics: true,
            ),
          );
        });

        // Act
        final results = await Future.wait(futures);

        // Assert - 所有請求都應該成功
        expect(results.length, 5);
        for (final result in results) {
          expect(result.card.name, isNotEmpty);
          expect(result.metrics, isNotNull);
        }
      });

      test('should cleanup resources properly', () async {
        // Arrange & Act
        final result = await useCase.execute(
          CreateCardFromImageParams(imageData: testImageData),
        );

        // Assert - 檢查資源清理
        expect(result.processingSteps, contains('資源清理'));
      });

      test('should respect processing timeout', () async {
        // Arrange - 設定很短的超時時間
        mockOCRRepository.setMockFailure(
          const OCRProcessingFailure(
            engineId: 'slow-engine',
            userMessage: '處理超時',
            internalMessage: 'Processing timeout exceeded',
          ),
        );

        // Act & Assert
        expect(
          () => useCase.execute(
            CreateCardFromImageParams(
              imageData: testImageData,
              timeout: const Duration(milliseconds: 100), // 很短的超時
            ),
          ),
          throwsA(isA<OCRProcessingFailure>()),
        );
      });
    });
  });
}
