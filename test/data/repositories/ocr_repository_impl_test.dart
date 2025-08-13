import 'dart:typed_data';

import 'package:busines_card_scanner_flutter/data/datasources/local/ocr_cache_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/ocr_service.dart';
import 'package:busines_card_scanner_flutter/data/repositories/ocr_repository_impl.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// OCRRepository 實作的測試
///
/// 遵循 TDD Red-Green-Refactor 開發流程
/// 測試涵蓋核心OCR功能、錯誤處理、快取機制等關鍵場景

// Mock classes using mocktail
class MockOCRService extends Mock implements OCRService {}

class MockOCRCacheService extends Mock implements OCRCacheService {}

// Fake classes for fallback values
class FakeOCROptions extends Fake implements OCROptions {}

class FakeOCRResult extends Fake implements OCRResult {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(FakeOCROptions());
    registerFallbackValue(FakeOCRResult());
  });

  group('OCRRepositoryImpl - TDD Red Phase', () {
    late OCRRepositoryImpl repository;
    late MockOCRService mockOCRService;
    late MockOCRCacheService mockCacheService;

    // 測試資料
    late Uint8List testImageData;
    late OCRResult expectedResult;

    setUp(() {
      mockOCRService = MockOCRService();
      mockCacheService = MockOCRCacheService();

      repository = OCRRepositoryImpl(
        ocrService: mockOCRService,
        cacheService: mockCacheService,
      );

      // 準備測試資料
      testImageData = Uint8List.fromList([1, 2, 3, 4, 5]);
      expectedResult = OCRResult(
        id: 'test-ocr-001',
        rawText: '張三\nABC科技公司\n產品經理\n02-1234-5678',
        detectedTexts: const ['張三', 'ABC科技公司', '產品經理', '02-1234-5678'],
        confidence: 0.92,
        imageData: testImageData,
        imageWidth: 800,
        imageHeight: 600,
        processedAt: DateTime(2024, 8, 12, 10, 30),
        processingTimeMs: 1200,
        ocrEngine: 'google_ml_kit',
      );
    });

    group('recognizeText', () {
      test('should return OCR result when recognition succeeds', () async {
        // Arrange
        const imageHash = 'test_image_hash';
        when(
          () => mockCacheService.getCacheKey(testImageData),
        ).thenReturn(imageHash);
        when(
          () => mockCacheService.getCachedResult(imageHash),
        ).thenThrow(Exception('Cache miss'));
        when(
          () => mockOCRService.recognizeText(
            testImageData,
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => expectedResult);
        when(
          () => mockCacheService.cacheResult(imageHash, expectedResult),
        ).thenAnswer((_) async => {});

        // Act
        final result = await repository.recognizeText(testImageData);

        // Assert
        expect(result.rawText, equals(expectedResult.rawText));
        expect(result.confidence, equals(expectedResult.confidence));
        expect(result.detectedTexts, hasLength(4));
        verify(
          () => mockOCRService.recognizeText(
            testImageData,
            options: any(named: 'options'),
          ),
        ).called(1);
      });

      test('should use cache when available and valid', () async {
        // Arrange
        const imageHash = 'cached_image_hash';
        when(
          () => mockCacheService.getCacheKey(testImageData),
        ).thenReturn(imageHash);
        when(
          () => mockCacheService.getCachedResult(imageHash),
        ).thenAnswer((_) async => expectedResult);
        when(
          () => mockCacheService.isCacheValid(expectedResult),
        ).thenReturn(true);

        // Act
        final result = await repository.recognizeText(testImageData);

        // Assert
        expect(result, equals(expectedResult));
        verify(() => mockCacheService.getCachedResult(imageHash)).called(1);
        verifyNever(
          () => mockOCRService.recognizeText(
            any(),
            options: any(named: 'options'),
          ),
        );
      });

      test('should fallback to OCR service when cache is invalid', () async {
        // Arrange
        const imageHash = 'cached_image_hash';
        final staleResult = expectedResult.copyWith(
          processedAt: DateTime.now().subtract(const Duration(days: 8)),
        );

        when(
          () => mockCacheService.getCacheKey(testImageData),
        ).thenReturn(imageHash);
        when(
          () => mockCacheService.getCachedResult(imageHash),
        ).thenAnswer((_) async => staleResult);
        when(
          () => mockCacheService.isCacheValid(staleResult),
        ).thenReturn(false);
        when(
          () => mockOCRService.recognizeText(
            testImageData,
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => expectedResult);
        when(
          () => mockCacheService.cacheResult(imageHash, expectedResult),
        ).thenAnswer((_) async => {});

        // Act
        final result = await repository.recognizeText(testImageData);

        // Assert
        expect(result, equals(expectedResult));
        verify(
          () => mockOCRService.recognizeText(
            testImageData,
            options: any(named: 'options'),
          ),
        ).called(1);
        verify(
          () => mockCacheService.cacheResult(imageHash, expectedResult),
        ).called(1);
      });

      test(
        'should throw OCRProcessingFailure when OCR service fails',
        () async {
          // Arrange
          const imageHash = 'test_image_hash';
          when(
            () => mockCacheService.getCacheKey(testImageData),
          ).thenReturn(imageHash);
          when(
            () => mockCacheService.getCachedResult(imageHash),
          ).thenThrow(Exception('Cache miss'));
          when(
            () => mockOCRService.recognizeText(
              testImageData,
              options: any(named: 'options'),
            ),
          ).thenThrow(const OCRProcessingFailure(userMessage: 'OCR 引擎處理失敗'));

          // Act & Assert
          await expectLater(
            repository.recognizeText(testImageData),
            throwsA(
              isA<OCRProcessingFailure>().having(
                (failure) => failure.userMessage,
                'userMessage',
                contains('OCR 引擎處理失敗'),
              ),
            ),
          );

          verify(
            () => mockOCRService.recognizeText(
              testImageData,
              options: any(named: 'options'),
            ),
          ).called(1);
        },
      );

      test(
        'should throw UnsupportedImageFormatFailure for invalid image format',
        () async {
          // Arrange
          final invalidImageData = Uint8List.fromList([
            0xFF,
            0xD8,
          ]); // 不完整的 JPEG header
          const imageHash = 'invalid_image_hash';

          when(
            () => mockCacheService.getCacheKey(invalidImageData),
          ).thenReturn(imageHash);
          when(
            () => mockCacheService.getCachedResult(imageHash),
          ).thenThrow(Exception('Cache miss'));
          when(
            () => mockOCRService.recognizeText(
              invalidImageData,
              options: any(named: 'options'),
            ),
          ).thenThrow(
            const UnsupportedImageFormatFailure(userMessage: '不支援的圖片格式'),
          );

          // Act & Assert
          await expectLater(
            repository.recognizeText(invalidImageData),
            throwsA(isA<UnsupportedImageFormatFailure>()),
          );
        },
      );

      test('should apply OCR options correctly', () async {
        // Arrange
        const imageHash = 'test_image_hash';
        const options = OCROptions(
          preferredLanguages: ['zh-Hant', 'en'],
          enableRotationCorrection: false,
          maxProcessingTimeMs: 5000,
          saveResult: true,
        );

        when(
          () => mockCacheService.getCacheKey(testImageData),
        ).thenReturn(imageHash);
        when(
          () => mockCacheService.getCachedResult(imageHash),
        ).thenThrow(Exception('Cache miss'));
        when(
          () => mockOCRService.recognizeText(testImageData, options: options),
        ).thenAnswer((_) async => expectedResult);
        when(
          () => mockCacheService.cacheResult(imageHash, expectedResult),
        ).thenAnswer((_) async => {});

        // Act
        final result = await repository.recognizeText(
          testImageData,
          options: options,
        );

        // Assert
        expect(result, equals(expectedResult));
        verify(
          () => mockOCRService.recognizeText(testImageData, options: options),
        ).called(1);
      });
    });

    group('recognizeTexts (batch processing)', () {
      test('should process multiple images successfully', () async {
        // Arrange
        final imageList = [
          Uint8List.fromList([1, 2, 3]),
          Uint8List.fromList([4, 5, 6]),
          Uint8List.fromList([7, 8, 9]),
        ];

        final expectedResults = [
          expectedResult.copyWith(id: 'ocr-001', rawText: '張三'),
          expectedResult.copyWith(id: 'ocr-002', rawText: '李四'),
          expectedResult.copyWith(id: 'ocr-003', rawText: '王五'),
        ];

        // 設定快取 mock 行為
        when(() => mockCacheService.getCacheKey(any())).thenAnswer((
          invocation,
        ) {
          final imageData = invocation.positionalArguments[0] as Uint8List;
          return 'hash_${imageData.first}';
        });
        when(
          () => mockCacheService.getCachedResult(any()),
        ).thenThrow(Exception('Cache miss'));
        when(
          () => mockCacheService.cacheResult(any(), any()),
        ).thenAnswer((_) async => {});

        when(
          () => mockOCRService.recognizeText(
            any(),
            options: any(named: 'options'),
          ),
        ).thenAnswer((invocation) async {
          final imageData = invocation.positionalArguments[0] as Uint8List;
          if (imageData.first == 1) {
            return expectedResults[0];
          }
          if (imageData.first == 4) {
            return expectedResults[1];
          }
          return expectedResults[2];
        });

        // Act
        final result = await repository.recognizeTexts(imageList);

        // Assert
        expect(result.successful, hasLength(3));
        expect(result.failed, isEmpty);
        expect(result.successRate, equals(1.0));
        expect(result.successful[0].rawText, equals('張三'));
        expect(result.successful[1].rawText, equals('李四'));
        expect(result.successful[2].rawText, equals('王五'));

        verify(
          () => mockOCRService.recognizeText(
            any(),
            options: any(named: 'options'),
          ),
        ).called(3);
      });

      test('should handle partial failures in batch processing', () async {
        // Arrange
        final imageList = [
          Uint8List.fromList([1, 2, 3]), // 成功
          Uint8List.fromList([4, 5, 6]), // 失敗
          Uint8List.fromList([7, 8, 9]), // 成功
        ];

        // 設定快取 mock 行為
        when(() => mockCacheService.getCacheKey(any())).thenAnswer((
          invocation,
        ) {
          final imageData = invocation.positionalArguments[0] as Uint8List;
          return 'hash_${imageData.first}';
        });
        when(
          () => mockCacheService.getCachedResult(any()),
        ).thenThrow(Exception('Cache miss'));
        when(
          () => mockCacheService.cacheResult(any(), any()),
        ).thenAnswer((_) async => {});

        when(
          () => mockOCRService.recognizeText(
            any(),
            options: any(named: 'options'),
          ),
        ).thenAnswer((invocation) async {
          final imageData = invocation.positionalArguments[0] as Uint8List;
          if (imageData.first == 1) {
            return expectedResult.copyWith(id: 'ocr-001', rawText: '張三');
          } else if (imageData.first == 4) {
            throw const OCRProcessingFailure(userMessage: '第二張圖片處理失敗');
          } else {
            return expectedResult.copyWith(id: 'ocr-003', rawText: '王五');
          }
        });

        // Act
        final result = await repository.recognizeTexts(imageList);

        // Assert
        expect(result.successful, hasLength(2));
        expect(result.failed, hasLength(1));
        expect(result.successRate, equals(2.0 / 3.0));
        expect(result.hasFailures, isTrue);
        expect(result.failed.first.index, equals(1));
        expect(result.failed.first.error, contains('OCRProcessingFailure'));
      });
    });

    group('saveOCRResult', () {
      test('should save OCR result successfully', () async {
        // Arrange
        final resultToSave = expectedResult.copyWith(id: 'temp-id');
        final savedResult = expectedResult.copyWith(id: 'generated-id-001');

        when(
          () => mockCacheService.saveResult(resultToSave),
        ).thenAnswer((_) async => savedResult);

        // Act
        final result = await repository.saveOCRResult(resultToSave);

        // Assert
        expect(result.id, equals('generated-id-001'));
        expect(result.rawText, equals(resultToSave.rawText));
        verify(() => mockCacheService.saveResult(resultToSave)).called(1);
      });

      test('should throw DataSourceFailure when save fails', () async {
        // Arrange
        when(
          () => mockCacheService.saveResult(any()),
        ).thenThrow(const DataSourceFailure(userMessage: '儲存失敗'));

        // Act & Assert
        await expectLater(
          repository.saveOCRResult(expectedResult),
          throwsA(isA<DataSourceFailure>()),
        );
      });
    });

    group('getOCRHistory', () {
      test('should return OCR history with default parameters', () async {
        // Arrange
        final historyResults = [
          expectedResult.copyWith(id: 'history-001'),
          expectedResult.copyWith(id: 'history-002'),
        ];

        when(
          () => mockCacheService.getHistory(),
        ).thenAnswer((_) async => historyResults);

        // Act
        final result = await repository.getOCRHistory();

        // Assert
        expect(result, hasLength(2));
        expect(result[0].id, equals('history-001'));
        verify(() => mockCacheService.getHistory()).called(1);
      });
    });

    group('deleteOCRResult', () {
      test('should delete OCR result successfully', () async {
        // Arrange
        const resultId = 'test-ocr-001';

        when(
          () => mockCacheService.deleteResult(resultId),
        ).thenAnswer((_) async => true);

        // Act
        final result = await repository.deleteOCRResult(resultId);

        // Assert
        expect(result, isTrue);
        verify(() => mockCacheService.deleteResult(resultId)).called(1);
      });
    });

    group('cleanupOldResults', () {
      test('should cleanup old results and return count', () async {
        // Arrange
        when(
          () => mockCacheService.cleanupOldResults(),
        ).thenAnswer((_) async => 5);

        // Act
        final result = await repository.cleanupOldResults();

        // Assert
        expect(result, equals(5));
        verify(() => mockCacheService.cleanupOldResults()).called(1);
      });
    });

    group('engine management', () {
      test('should return available OCR engines', () async {
        // Arrange
        final expectedEngines = [
          const OCREngineInfo(
            id: 'google_ml_kit',
            name: 'Google ML Kit',
            version: '0.15.0',
            supportedLanguages: ['zh-Hant', 'en', 'ja'],
            isAvailable: true,
            platform: 'cross-platform',
          ),
        ];

        when(
          () => mockOCRService.getAvailableEngines(),
        ).thenAnswer((_) async => expectedEngines);

        // Act
        final result = await repository.getAvailableEngines();

        // Assert
        expect(result, hasLength(1));
        expect(result[0].id, equals('google_ml_kit'));
        expect(result[0].isAvailable, isTrue);
      });

      test('should set preferred engine', () async {
        // Arrange
        const engineId = 'google_ml_kit';

        when(
          () => mockOCRService.setPreferredEngine(engineId),
        ).thenAnswer((_) async => {});

        // Act
        await repository.setPreferredEngine(engineId);

        // Assert
        verify(() => mockOCRService.setPreferredEngine(engineId)).called(1);
      });
    });
  });
}
