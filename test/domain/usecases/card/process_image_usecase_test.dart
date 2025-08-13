import 'dart:typed_data';

import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/process_image_usecase.dart';
import 'package:flutter_test/flutter_test.dart';


/// Mock OCRRepository 用於測試
class MockOCRRepository implements OCRRepository {
  OCRResult? _mockOCRResult;
  BatchOCRResult? _mockBatchResult;
  Uint8List? _mockPreprocessedImage;
  OCRStatistics? _mockStatistics;
  List<OCREngineInfo>? _mockEngines;
  OCREngineInfo? _mockCurrentEngine;
  OCREngineHealth? _mockEngineHealth;
  DomainFailure? _mockFailure;
  
  void setMockOCRResult(OCRResult result) => _mockOCRResult = result;
  void setMockBatchResult(BatchOCRResult result) => _mockBatchResult = result;
  void setMockPreprocessedImage(Uint8List image) => _mockPreprocessedImage = image;
  void setMockStatistics(OCRStatistics stats) => _mockStatistics = stats;
  void setMockEngines(List<OCREngineInfo> engines) => _mockEngines = engines;
  void setMockCurrentEngine(OCREngineInfo engine) => _mockCurrentEngine = engine;
  void setMockEngineHealth(OCREngineHealth health) => _mockEngineHealth = health;
  void setMockFailure(DomainFailure? failure) => _mockFailure = failure;
  void clearMockFailure() => _mockFailure = null;

  @override
  Future<OCRResult> recognizeText(Uint8List imageData, {OCROptions? options}) async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockOCRResult ?? OCRResult(
      id: 'ocr-${DateTime.now().millisecondsSinceEpoch}',
      rawText: 'Mock OCR result',
      confidence: 0.85,
      processingTimeMs: 1000,
      processedAt: DateTime.now(),
    );
  }

  @override
  Future<BatchOCRResult> recognizeTexts(List<Uint8List> imageDataList, {OCROptions? options}) async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockBatchResult ?? const BatchOCRResult(successful: [], failed: []);
  }

  @override
  Future<OCRResult> saveOCRResult(OCRResult result) async {
    if (_mockFailure != null) throw _mockFailure!;
    return result;
  }

  @override
  Future<List<OCRResult>> getOCRHistory({int limit = 50, bool includeImages = false}) async {
    if (_mockFailure != null) throw _mockFailure!;
    return [];
  }

  @override
  Future<OCRResult> getOCRResultById(String resultId, {bool includeImage = false}) async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockOCRResult ?? OCRResult(
      id: resultId,
      rawText: 'Test OCR result',
      confidence: 0.8,
      processingTimeMs: 1000,
      processedAt: DateTime.now(),
    );
  }

  @override
  Future<bool> deleteOCRResult(String resultId) async {
    if (_mockFailure != null) throw _mockFailure!;
    return true;
  }

  @override
  Future<int> cleanupOldResults({int daysOld = 30}) async {
    if (_mockFailure != null) throw _mockFailure!;
    return 5;
  }

  @override
  Future<List<OCREngineInfo>> getAvailableEngines() async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockEngines ?? [
      const OCREngineInfo(
        id: 'google-ml-kit',
        name: 'Google ML Kit',
        version: '0.15.0',
        supportedLanguages: ['zh-Hant', 'en'],
        isAvailable: true,
        platform: 'cross-platform',
      ),
    ];
  }

  @override
  Future<void> setPreferredEngine(String engineId) async {
    if (_mockFailure != null) throw _mockFailure!;
  }

  @override
  Future<OCREngineInfo> getCurrentEngine() async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockCurrentEngine ?? const OCREngineInfo(
      id: 'google-ml-kit',
      name: 'Google ML Kit',
      version: '0.15.0',
      supportedLanguages: ['zh-Hant', 'en'],
      isAvailable: true,
      platform: 'cross-platform',
    );
  }

  @override
  Future<OCREngineHealth> testEngine({String? engineId}) async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockEngineHealth ?? OCREngineHealth(
      engineId: engineId ?? 'google-ml-kit',
      isHealthy: true,
      responseTimeMs: 100,
      checkedAt: DateTime.now(),
    );
  }

  @override
  Future<Uint8List> preprocessImage(Uint8List imageData, {ImagePreprocessOptions? options}) async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockPreprocessedImage ?? imageData;
  }

  @override
  Future<OCRStatistics> getStatistics() async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockStatistics ?? OCRStatistics(
      totalProcessed: 100,
      averageConfidence: 0.85,
      averageProcessingTimeMs: 1200,
      engineUsage: {'google-ml-kit': 100},
      languageConfidence: {'zh-Hant': 0.9, 'en': 0.8},
      lastUpdated: DateTime.now(),
    );
  }
}

void main() {
  group('ProcessImageUseCase Tests', () {
    late ProcessImageUseCase useCase;
    late MockOCRRepository mockOCRRepository;
    late Uint8List testImageData;

    setUp(() {
      mockOCRRepository = MockOCRRepository();
      useCase = ProcessImageUseCase(mockOCRRepository);
      
      // 建立測試圖片資料
      testImageData = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, // JPEG header
        ...List.filled(1000, 0x00), // 模擬圖片內容
      ]);
    });

    group('基本圖片處理功能', () {
      test('should process single image successfully', () async {
        // Arrange
        final expectedOCRResult = OCRResult(
          id: 'ocr-123',
          rawText: '王大明\n軟體工程師\n科技股份有限公司',
          confidence: 0.92,
          processingTimeMs: 1200,
          processedAt: DateTime.now(),
        );
        mockOCRRepository.setMockOCRResult(expectedOCRResult);

        // Act
        final result = await useCase.execute(ProcessImageParams(
          imageData: testImageData,
        ));

        // Assert
        expect(result.ocrResult.id, 'ocr-123');
        expect(result.ocrResult.rawText, contains('王大明'));
        expect(result.ocrResult.confidence, 0.92);
        expect(result.processingSteps, contains('OCR 文字識別'));
        expect(result.isSuccess, true);
      });

      test('should apply OCR options correctly', () async {
        // Arrange
        const ocrOptions = OCROptions(
          preferredLanguages: ['zh-Hant', 'en'],
        );

        // Act
        final result = await useCase.execute(ProcessImageParams(
          imageData: testImageData,
          ocrOptions: ocrOptions,
        ));

        // Assert
        expect(result.ocrResult, isNotNull);
        expect(result.processingSteps, contains('OCR 文字識別'));
      });

      test('should preprocess image when enabled', () async {
        // Arrange
        final preprocessedImage = Uint8List.fromList([
          0xFF, 0xD8, 0xFF, 0xE0, // JPEG header
          ...List.filled(800, 0x01), // 模擬預處理後的圖片
        ]);
        mockOCRRepository.setMockPreprocessedImage(preprocessedImage);

        const preprocessOptions = ImagePreprocessOptions(
          contrast: 20,
          brightness: 10,
          sharpen: true,
        );

        // Act
        final result = await useCase.execute(ProcessImageParams(
          imageData: testImageData,
          preprocessOptions: preprocessOptions,
          enablePreprocessing: true,
        ));

        // Assert
        expect(result.processingSteps, contains('圖片預處理'));
        expect(result.isSuccess, true);
      });

      test('should handle low confidence OCR results', () async {
        // Arrange
        final lowConfidenceResult = OCRResult(
          id: 'ocr-low',
          rawText: '模糊文字',
          confidence: 0.35,
          processingTimeMs: 1500,
          processedAt: DateTime.now(),
        );
        mockOCRRepository.setMockOCRResult(lowConfidenceResult);

        // Act
        final result = await useCase.execute(ProcessImageParams(
          imageData: testImageData,
          confidenceThreshold: 0.7,
        ));

        // Assert
        expect(result.hasWarnings, true);
        expect(result.warnings.first, contains('信心度較低'));
        expect(result.ocrResult.confidence, 0.35);
      });

      test('should save OCR result when requested', () async {
        // Act
        final result = await useCase.execute(ProcessImageParams(
          imageData: testImageData,
          saveResult: true,
        ));

        // Assert
        expect(result.processingSteps, contains('OCR 結果儲存'));
        expect(result.isSuccess, true);
      });
    });

    group('輸入驗證', () {
      test('should reject empty image data', () async {
        // Arrange
        final emptyImageData = Uint8List(0);

        // Act & Assert
        expect(
          () => useCase.execute(ProcessImageParams(
            imageData: emptyImageData,
          )),
          throwsA(isA<InvalidInputFailure>()),
        );
      });

      test('should reject oversized image', () async {
        // Arrange
        const maxSizeBytes = 10 * 1024 * 1024; // 10MB
        final oversizedImageData = Uint8List(maxSizeBytes + 1000);

        // Act & Assert
        expect(
          () => useCase.execute(ProcessImageParams(
            imageData: oversizedImageData,
            maxImageSizeBytes: maxSizeBytes,
          )),
          throwsA(isA<InvalidInputFailure>()),
        );
      });

      test('should validate image format', () async {
        // Arrange - 無效的圖片格式
        final invalidImageData = Uint8List.fromList([
          0x00, 0x00, 0x00, 0x00, // 無效 header
          ...List.filled(100, 0x00),
        ]);

        // Act & Assert
        expect(
          () => useCase.execute(ProcessImageParams(
            imageData: invalidImageData,
            validateImageFormat: true,
          )),
          throwsA(isA<InvalidInputFailure>()),
        );
      });

      test('should validate confidence threshold range', () async {
        // Arrange - 確保沒有Mock failure
        mockOCRRepository.clearMockFailure();
        
        // Act & Assert
        expect(
          () => useCase.execute(ProcessImageParams(
            imageData: testImageData,
            confidenceThreshold: 1.5, // 無效範圍
          )),
          throwsA(isA<InvalidInputFailure>()),
        );

        expect(
          () => useCase.execute(ProcessImageParams(
            imageData: testImageData,
            confidenceThreshold: -0.1, // 無效範圍
          )),
          throwsA(isA<InvalidInputFailure>()),
        );
      });
    });

    group('批次處理功能', () {
      test('should process multiple images successfully', () async {
        // Arrange
        final imageDataList = [
          testImageData,
          Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(500, 0x01)]),
          Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(300, 0x02)]),
        ];

        final mockBatchResult = BatchOCRResult(
          successful: [
            OCRResult(
              id: 'batch-1',
              rawText: '名片 1',
              confidence: 0.9,
              processingTimeMs: 1000,
              processedAt: DateTime.now(),
            ),
            OCRResult(
              id: 'batch-2',
              rawText: '名片 2',
              confidence: 0.85,
              processingTimeMs: 1100,
              processedAt: DateTime.now(),
            ),
            OCRResult(
              id: 'batch-3',
              rawText: '名片 3',
              confidence: 0.8,
              processingTimeMs: 1200,
              processedAt: DateTime.now(),
            ),
          ],
          failed: [],
        );
        mockOCRRepository.setMockBatchResult(mockBatchResult);

        // Act
        final results = await useCase.executeBatch(ProcessImageBatchParams(
          imageDataList: imageDataList,
        ));

        // Assert
        expect(results.successful.length, 3);
        expect(results.failed.length, 0);
        expect(results.successCount, 3);
        expect(results.hasFailures, false);
      });

      test('should handle partial batch processing failures', () async {
        // Arrange
        final imageDataList = [
          testImageData,
          Uint8List(0), // 空圖片會失敗
          testImageData,
        ];

        final mockBatchResult = BatchOCRResult(
          successful: [
            OCRResult(
              id: 'batch-1',
              rawText: '名片 1',
              confidence: 0.9,
              processingTimeMs: 1000,
              processedAt: DateTime.now(),
            ),
            OCRResult(
              id: 'batch-3',
              rawText: '名片 3',
              confidence: 0.8,
              processingTimeMs: 1200,
              processedAt: DateTime.now(),
            ),
          ],
          failed: [
            BatchOCRError(
              index: 1,
              error: 'Empty image data',
              originalImageData: Uint8List(0),
            ),
          ],
        );
        mockOCRRepository.setMockBatchResult(mockBatchResult);

        // Act
        final results = await useCase.executeBatch(ProcessImageBatchParams(
          imageDataList: imageDataList,
        ));

        // Assert
        expect(results.successful.length, 2);
        expect(results.failed.length, 1);
        expect(results.hasFailures, true);
      });

      test('should support concurrent batch processing', () async {
        // Arrange
        final imageDataList = List.generate(5, (index) => 
          Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(100, index)]),
        );

        // 設定 Mock 批次結果
        final mockBatchResult = BatchOCRResult(
          successful: List.generate(5, (index) => OCRResult(
            id: 'concurrent-$index',
            rawText: '併發處理結果 $index',
            confidence: 0.85,
            processingTimeMs: 1000,
            processedAt: DateTime.now(),
          )),
          failed: [],
        );
        mockOCRRepository.setMockBatchResult(mockBatchResult);

        // Act
        final results = await useCase.executeBatch(ProcessImageBatchParams(
          imageDataList: imageDataList,
        ));

        // Assert
        expect(results.successful.length + results.failed.length, 5);
      });
    });

    group('OCR 引擎管理', () {
      test('should get available OCR engines', () async {
        // Arrange
        final mockEngines = [
          const OCREngineInfo(
            id: 'google-ml-kit',
            name: 'Google ML Kit',
            version: '0.15.0',
            supportedLanguages: ['zh-Hant', 'en'],
            isAvailable: true,
            platform: 'cross-platform',
          ),
          const OCREngineInfo(
            id: 'ios-vision',
            name: 'iOS Vision Framework',
            version: '17.0',
            supportedLanguages: ['zh-Hant', 'en', 'ja'],
            isAvailable: true,
            platform: 'ios',
          ),
        ];
        mockOCRRepository.setMockEngines(mockEngines);

        // Act
        final engines = await useCase.getAvailableEngines();

        // Assert
        expect(engines.length, 2);
        expect(engines.first.id, 'google-ml-kit');
        expect(engines.last.id, 'ios-vision');
      });

      test('should set preferred OCR engine', () async {
        // Act & Assert - 不應該拋出異常
        await expectLater(
          useCase.setPreferredEngine('google-ml-kit'),
          completes,
        );
      });

      test('should get current OCR engine', () async {
        // Arrange
        const currentEngine = OCREngineInfo(
          id: 'current-engine',
          name: 'Current Engine',
          version: '1.0.0',
          supportedLanguages: ['zh-Hant'],
          isAvailable: true,
          platform: 'cross-platform',
        );
        mockOCRRepository.setMockCurrentEngine(currentEngine);

        // Act
        final engine = await useCase.getCurrentEngine();

        // Assert
        expect(engine.id, 'current-engine');
        expect(engine.name, 'Current Engine');
      });

      test('should test OCR engine health', () async {
        // Arrange
        final mockHealth = OCREngineHealth(
          engineId: 'test-engine',
          isHealthy: true,
          responseTimeMs: 150,
          checkedAt: DateTime.now(),
        );
        mockOCRRepository.setMockEngineHealth(mockHealth);

        // Act
        final health = await useCase.testEngineHealth('test-engine');

        // Assert
        expect(health.engineId, 'test-engine');
        expect(health.isHealthy, true);
        expect(health.responseTimeMs, 150);
      });
    });

    group('統計與監控', () {
      test('should get OCR processing statistics', () async {
        // Arrange
        final mockStats = OCRStatistics(
          totalProcessed: 1000,
          averageConfidence: 0.87,
          averageProcessingTimeMs: 1150.5,
          engineUsage: {
            'google-ml-kit': 800,
            'ios-vision': 200,
          },
          languageConfidence: {
            'zh-Hant': 0.9,
            'en': 0.85,
            'ja': 0.8,
          },
          lastUpdated: DateTime.now(),
        );
        mockOCRRepository.setMockStatistics(mockStats);

        // Act
        final stats = await useCase.getStatistics();

        // Assert
        expect(stats.totalProcessed, 1000);
        expect(stats.averageConfidence, 0.87);
        expect(stats.engineUsage.length, 2);
        expect(stats.languageConfidence.length, 3);
      });

      test('should track processing metrics when enabled', () async {
        // Act
        final result = await useCase.execute(ProcessImageParams(
          imageData: testImageData,
          trackMetrics: true,
        ));

        // Assert
        expect(result.metrics, isNotNull);
        expect(result.metrics!.totalProcessingTimeMs, greaterThanOrEqualTo(0));
        expect(result.metrics!.preprocessingTimeMs, greaterThanOrEqualTo(0));
        expect(result.metrics!.ocrProcessingTimeMs, greaterThanOrEqualTo(0));
        expect(result.metrics!.startTime.isBefore(result.metrics!.endTime), true);
      });

      test('should cleanup old OCR results', () async {
        // Act
        final cleanupCount = await useCase.cleanupOldResults();

        // Assert
        expect(cleanupCount, greaterThanOrEqualTo(0));
      });
    });

    group('錯誤處理', () {
      test('should handle OCR service unavailable', () async {
        // Arrange
        mockOCRRepository.setMockFailure(
          const DataSourceFailure(
            userMessage: 'OCR 服務暫時無法使用',
            internalMessage: 'OCR service unavailable',
          ),
        );

        // Act & Assert
        expect(
          () => useCase.execute(ProcessImageParams(
            imageData: testImageData,
          )),
          throwsA(isA<DataSourceFailure>()),
        );
      });

      test('should handle processing timeout', () async {
        // Arrange
        mockOCRRepository.setMockFailure(
          const DataSourceFailure(
            userMessage: '圖片處理超時',
            internalMessage: 'Processing timeout exceeded',
          ),
        );

        // Act & Assert
        expect(
          () => useCase.execute(ProcessImageParams(
            imageData: testImageData,
            timeout: const Duration(seconds: 1),
          )),
          throwsA(isA<DataSourceFailure>()),
        );
      });

      test('should handle storage failure when saving result', () async {
        // Arrange
        mockOCRRepository.setMockFailure(
          const StorageSpaceFailure(
            availableSpaceBytes: 100,
            requiredSpaceBytes: 1000,
            userMessage: '儲存空間不足',
          ),
        );

        // Act & Assert
        expect(
          () => useCase.execute(ProcessImageParams(
            imageData: testImageData,
            saveResult: true,
          )),
          throwsA(isA<StorageSpaceFailure>()),
        );
      });

      test('should handle corrupted image data', () async {
        // Arrange
        final corruptedImageData = Uint8List.fromList([
          0xFF, 0xFF, 0xFF, 0xFF, // 損壞的 header
          ...List.filled(100, 0xFF),
        ]);

        mockOCRRepository.setMockFailure(
          const DataSourceFailure(
            userMessage: '圖片資料損壞',
            internalMessage: 'Corrupted image data',
          ),
        );

        // Act & Assert
        expect(
          () => useCase.execute(ProcessImageParams(
            imageData: corruptedImageData,
          )),
          throwsA(isA<DataSourceFailure>()),
        );
      });
    });

    group('進階功能', () {
      test('should support dry run mode without saving', () async {
        // Act
        final result = await useCase.execute(ProcessImageParams(
          imageData: testImageData,
          dryRun: true,
        ));

        // Assert
        expect(result.processingSteps, contains('乾執行模式'));
        expect(result.processingSteps, isNot(contains('OCR 結果儲存')));
        expect(result.isSuccess, true);
      });

      test('should auto-select best OCR engine', () async {
        // Act
        final result = await useCase.execute(ProcessImageParams(
          imageData: testImageData,
          autoSelectEngine: true,
        ));

        // Assert
        expect(result.processingSteps, contains('自動選擇引擎'));
        expect(result.isSuccess, true);
      });

      test('should validate result quality', () async {
        // Arrange
        final lowQualityResult = OCRResult(
          id: 'low-quality',
          rawText: 'a1b2c3', // 低品質結果
          confidence: 0.8, // 高信心度避免信心度警告
          processingTimeMs: 1000,
          processedAt: DateTime.now(),
        );
        mockOCRRepository.setMockOCRResult(lowQualityResult);

        // Act
        final result = await useCase.execute(ProcessImageParams(
          imageData: testImageData,
          validateQuality: true,
          minTextLength: 10, // rawText 只有6個字符，會觸發品質警告
          confidenceThreshold: 0.7, // 明確設定閾值
        ));

        // Assert
        expect(result.hasWarnings, true);
        expect(result.warnings.any((warning) => warning.contains('文字品質')), true);
      });

      test('should optimize image before processing', () async {
        // Act
        final result = await useCase.execute(ProcessImageParams(
          imageData: testImageData,
          optimizeImage: true,
          preprocessOptions: const ImagePreprocessOptions(
            contrast: 15,
            brightness: 5,
            sharpen: true,
          ),
        ));

        // Assert
        expect(result.processingSteps, contains('圖片最佳化'));
        expect(result.isSuccess, true);
      });
    });

    group('效能與資源管理', () {
      test('should handle concurrent processing efficiently', () async {
        // Arrange
        final futures = List.generate(3, (index) {
          return useCase.execute(ProcessImageParams(
            imageData: testImageData,
            trackMetrics: true,
          ));
        });

        // Act
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, 3);
        for (final result in results) {
          expect(result.isSuccess, true);
          expect(result.metrics, isNotNull);
        }
      });

      test('should cleanup resources properly', () async {
        // Act
        final result = await useCase.execute(ProcessImageParams(
          imageData: testImageData,
          autoCleanup: true,
        ));

        // Assert
        expect(result.processingSteps, contains('資源清理'));
      });

      test('should respect memory limits', () async {
        // Arrange
        final largeImageData = Uint8List(5 * 1024 * 1024); // 5MB

        // Act
        final result = await useCase.execute(ProcessImageParams(
          imageData: largeImageData,
          maxMemoryUsageMB: 10,
          trackMetrics: true,
        ));

        // Assert
        expect(result.metrics, isNotNull);
        expect(result.isSuccess, true);
      });

      test('should validate processing within reasonable time', () async {
        // Act
        final startTime = DateTime.now();
        final result = await useCase.execute(ProcessImageParams(
          imageData: testImageData,
          trackMetrics: true,
        ));
        final duration = DateTime.now().difference(startTime);

        // Assert
        expect(duration.inMilliseconds, lessThan(5000)); // < 5 秒
        expect(result.metrics!.totalProcessingTimeMs, lessThan(5000));
      });
    });
  });
}