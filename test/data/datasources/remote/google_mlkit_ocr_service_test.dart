import 'dart:typed_data';

import 'package:busines_card_scanner_flutter/core/errors/failures.dart';
import 'package:busines_card_scanner_flutter/core/services/security_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/google_mlkit_ocr_service.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

/// GoogleMLKitOCRService 的完整測試套件
/// 
/// 遵循 TDD Red-Green-Refactor 開發流程
/// 涵蓋所有方法的成功/失敗場景和邊界條件
/// 使用 mocktail 進行 mocking，確保單元測試的獨立性

// Mock classes using mocktail
class MockTextRecognizer extends Mock implements TextRecognizer {
  @override
  Future<void> close() async {
    // Mock implementation returns void wrapped in Future
  }
}
class MockSecurityService extends Mock implements SecurityService {}
class MockUuid extends Mock implements Uuid {}
class MockRecognizedText extends Mock implements RecognizedText {}
class MockTextBlock extends Mock implements TextBlock {}
class MockTextLine extends Mock implements TextLine {}
class MockTextElement extends Mock implements TextElement {}

// Fake classes for fallback values
class FakeInputImage extends Fake implements InputImage {}
class FakeImagePreprocessOptions extends Fake implements ImagePreprocessOptions {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(FakeInputImage());
    registerFallbackValue(FakeImagePreprocessOptions());
  });

  group('GoogleMLKitOCRService - TDD 測試套件', () {
    late GoogleMLKitOCRService ocrService;
    late MockTextRecognizer mockTextRecognizer;
    late MockSecurityService mockSecurityService;
    late MockUuid mockUuid;
    
    // 測試資料
    late Uint8List validJpegData;
    late Uint8List validPngData;
    late Uint8List invalidImageData;
    late RecognizedText mockRecognizedText;

    setUp(() {
      mockTextRecognizer = MockTextRecognizer();
      mockSecurityService = MockSecurityService();
      mockUuid = MockUuid();
      
      ocrService = GoogleMLKitOCRService(
        textRecognizer: mockTextRecognizer,
        securityService: mockSecurityService,
        uuid: mockUuid,
      );

      // 準備測試圖片資料
      validJpegData = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, // JPEG header
        ...List.generate(100, (i) => i % 256), // 模擬圖片資料
      ]);
      
      validPngData = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
        ...List.generate(100, (i) => i % 256), // 模擬圖片資料
      ]);
      
      invalidImageData = Uint8List.fromList([0x00, 0x01, 0x02]); // 無效格式
      
      // 設定 Mock RecognizedText
      mockRecognizedText = _createMockRecognizedText();
    });

    tearDown(() {
      ocrService.dispose();
    });
    
    group('recognizeText', () {
      test('should recognize text successfully with JPEG image', () async {
        // Arrange
        const testId = 'test-ocr-001';
        when(() => mockUuid.v4()).thenReturn(testId);
        when(() => mockSecurityService.validateContent(any()))
            .thenReturn(const Right('validated'));
        when(() => mockTextRecognizer.processImage(any()))
            .thenAnswer((_) async => mockRecognizedText);

        // Act
        final result = await ocrService.recognizeText(validJpegData);

        // Assert
        expect(result.id, equals(testId));
        expect(result.rawText, contains('張三'));
        expect(result.rawText, contains('ABC科技公司'));
        expect(result.detectedTexts, isNotNull);
        expect(result.detectedTexts, hasLength(4));
        expect(result.confidence, greaterThan(0.0));
        expect(result.confidence, lessThanOrEqualTo(1.0));
        expect(result.ocrEngine, equals('google_ml_kit'));
        expect(result.processingTimeMs, greaterThan(0));
        
        verify(() => mockTextRecognizer.processImage(any())).called(1);
        verify(() => mockSecurityService.validateContent(any())).called(1);
      });

      test('should recognize text successfully with PNG image', () async {
        // Arrange
        const testId = 'test-ocr-002';
        when(() => mockUuid.v4()).thenReturn(testId);
        when(() => mockSecurityService.validateContent(any()))
            .thenReturn(const Right('validated'));
        when(() => mockTextRecognizer.processImage(any()))
            .thenAnswer((_) async => mockRecognizedText);

        // Act
        final result = await ocrService.recognizeText(validPngData);

        // Assert
        expect(result.id, equals(testId));
        expect(result.ocrEngine, equals('google_ml_kit'));
        verify(() => mockTextRecognizer.processImage(any())).called(1);
      });

      test('should apply OCR options correctly', () async {
        // Arrange
        const testId = 'test-ocr-003';
        const options = OCROptions(
          preferredLanguages: ['zh-Hant', 'en'],
          enableRotationCorrection: false,
          maxProcessingTimeMs: 5000,
        );
        
        when(() => mockUuid.v4()).thenReturn(testId);
        when(() => mockSecurityService.validateContent(any()))
            .thenReturn(const Right('validated'));
        when(() => mockTextRecognizer.processImage(any()))
            .thenAnswer((_) async => mockRecognizedText);

        // Act
        final result = await ocrService.recognizeText(validJpegData, options: options);

        // Assert
        expect(result.id, equals(testId));
        expect(result.imageData, isNull); // saveResult = false
        verify(() => mockTextRecognizer.processImage(any())).called(1);
      });

      test('should throw UnsupportedImageFormatFailure for empty image data', () async {
        // Arrange
        final emptyImageData = Uint8List(0);

        // Act & Assert
        await expectLater(
          ocrService.recognizeText(emptyImageData),
          throwsA(isA<UnsupportedImageFormatFailure>().having(
            (failure) => failure.userMessage,
            'userMessage',
            contains('圖片資料不能為空'),
          )),
        );
        
        verifyNever(() => mockTextRecognizer.processImage(any()));
      });

      test('should throw UnsupportedImageFormatFailure for invalid image format', () async {
        // Act & Assert
        await expectLater(
          ocrService.recognizeText(invalidImageData),
          throwsA(isA<UnsupportedImageFormatFailure>().having(
            (failure) => failure.userMessage,
            'userMessage',
            contains('不支援的圖片格式'),
          )),
        );
        
        verifyNever(() => mockTextRecognizer.processImage(any()));
      });

      test('should throw ImageTooLargeFailure for oversized image', () async {
        // Arrange
        final oversizedData = Uint8List(25 * 1024 * 1024); // 25MB
        oversizedData.setAll(0, [0xFF, 0xD8, 0xFF]); // JPEG header

        // Act & Assert
        await expectLater(
          ocrService.recognizeText(oversizedData),
          throwsA(isA<ImageTooLargeFailure>().having(
            (failure) => failure.userMessage,
            'userMessage',
            contains('圖片檔案過大'),
          )),
        );
        
        verifyNever(() => mockTextRecognizer.processImage(any()));
      });

      test('should throw DataSourceFailure when security validation fails', () async {
        // Arrange
        const securityFailure = SecurityFailure(
          userMessage: '圖片包含惡意內容',
          internalMessage: 'Security validation failed',
        );
        when(() => mockSecurityService.validateContent(any()))
            .thenReturn(const Left(securityFailure));

        // Act & Assert
        await expectLater(
          ocrService.recognizeText(validJpegData),
          throwsA(isA<DataSourceFailure>().having(
            (failure) => failure.userMessage,
            'userMessage',
            contains('圖片安全驗證失敗'),
          )),
        );
        
        verifyNever(() => mockTextRecognizer.processImage(any()));
      });

      test('should throw OCRProcessingFailure when text recognition fails', () async {
        // Arrange
        when(() => mockSecurityService.validateContent(any()))
            .thenReturn(const Right('validated'));
        when(() => mockTextRecognizer.processImage(any()))
            .thenThrow(Exception('ML Kit processing failed'));

        // Act & Assert
        await expectLater(
          ocrService.recognizeText(validJpegData),
          throwsA(isA<OCRProcessingFailure>().having(
            (failure) => failure.userMessage,
            'userMessage',
            contains('OCR 處理發生未預期的錯誤'),
          )),
        );
        
        verify(() => mockTextRecognizer.processImage(any())).called(1);
      });

      test('should throw OCRProcessingFailure for unsupported language', () async {
        // Arrange
        const options = OCROptions(
          preferredLanguages: ['unsupported-lang'],
        );

        // Act & Assert
        await expectLater(
          ocrService.recognizeText(validJpegData, options: options),
          throwsA(isA<OCRProcessingFailure>().having(
            (failure) => failure.userMessage,
            'userMessage',
            contains('不支援的語言'),
          )),
        );
        
        verifyNever(() => mockTextRecognizer.processImage(any()));
      });

      test('should throw OCRProcessingFailure for too short timeout', () async {
        // Arrange
        const options = OCROptions(
          maxProcessingTimeMs: 500, // < 1000ms
        );

        // Act & Assert
        await expectLater(
          ocrService.recognizeText(validJpegData, options: options),
          throwsA(isA<OCRProcessingFailure>().having(
            (failure) => failure.userMessage,
            'userMessage',
            contains('處理超時時間不能少於 1 秒'),
          )),
        );
        
        verifyNever(() => mockTextRecognizer.processImage(any()));
      });
    });

    group('getAvailableEngines', () {
      test('should return Google ML Kit engine info', () async {
        // Act
        final engines = await ocrService.getAvailableEngines();

        // Assert
        expect(engines, hasLength(1));
        expect(engines[0].id, equals('google_ml_kit'));
        expect(engines[0].name, equals('Google ML Kit'));
        expect(engines[0].version, equals('0.15.0'));
        expect(engines[0].platform, equals('cross-platform'));
        expect(engines[0].isAvailable, isTrue);
        expect(engines[0].supportedLanguages, contains('zh-Hant'));
        expect(engines[0].supportedLanguages, contains('en'));
        expect(engines[0].supportedLanguages, contains('ja'));
      });
    });

    group('setPreferredEngine', () {
      test('should accept valid engine ID', () async {
        // Act & Assert
        await expectLater(
          ocrService.setPreferredEngine('google_ml_kit'),
          completes,
        );
      });

      test('should throw UnsupportedError for invalid engine ID', () async {
        // Act & Assert
        await expectLater(
          ocrService.setPreferredEngine('invalid_engine'),
          throwsA(isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('只支援引擎 ID: google_ml_kit'),
          )),
        );
      });
    });

    group('getCurrentEngine', () {
      test('should return current engine info', () async {
        // Act
        final engine = await ocrService.getCurrentEngine();

        // Assert
        expect(engine.id, equals('google_ml_kit'));
        expect(engine.name, equals('Google ML Kit'));
        expect(engine.isAvailable, isTrue);
      });
    });

    group('testEngine', () {
      test('should return healthy status for valid engine', () async {
        // Arrange
        when(() => mockSecurityService.validateContent(any()))
            .thenReturn(const Right('validated'));
        when(() => mockTextRecognizer.processImage(any()))
            .thenAnswer((_) async => mockRecognizedText);
        when(() => mockUuid.v4()).thenReturn('test-health-check');

        // Act
        final health = await ocrService.testEngine();

        // Assert
        expect(health.engineId, equals('google_ml_kit'));
        expect(health.isHealthy, isTrue);
        expect(health.error, isNull);
        expect(health.responseTimeMs, isNotNull);
        expect(health.responseTimeMs, greaterThan(0));
      });

      test('should return unhealthy status when test fails', () async {
        // Arrange
        when(() => mockSecurityService.validateContent(any()))
            .thenReturn(const Right('validated'));
        when(() => mockTextRecognizer.processImage(any()))
            .thenThrow(Exception('Test failed'));

        // Act
        final health = await ocrService.testEngine();

        // Assert
        expect(health.engineId, equals('google_ml_kit'));
        expect(health.isHealthy, isFalse);
        expect(health.error, isNotNull);
        expect(health.error, contains('Test failed'));
      });

      test('should return unhealthy status for unsupported engine ID', () async {
        // Act
        final health = await ocrService.testEngine(engineId: 'unsupported_engine');

        // Assert
        expect(health.engineId, equals('unsupported_engine'));
        expect(health.isHealthy, isFalse);
        expect(health.error, contains('不支援的引擎 ID'));
      });
    });

    group('preprocessImage', () {
      test('should return original image when no options provided', () async {
        // Arrange
        when(() => mockSecurityService.validateContent(any()))
            .thenReturn(const Right('validated'));

        // Act
        final result = await ocrService.preprocessImage(validJpegData);

        // Assert
        expect(result, equals(validJpegData));
        verify(() => mockSecurityService.validateContent(any())).called(1);
      });

      test('should preprocess image with options', () async {
        // Arrange
        const options = ImagePreprocessOptions(
          targetWidth: 1000,
          targetHeight: 800,
          contrast: 10,
          brightness: 5,
          grayscale: true,
          denoise: true,
          sharpen: true,
        );
        when(() => mockSecurityService.validateContent(any()))
            .thenReturn(const Right('validated'));

        // Act
        final result = await ocrService.preprocessImage(validPngData, options: options);

        // Assert
        expect(result, isNotNull);
        expect(result.length, greaterThan(0));
        expect(result, isNot(equals(validPngData))); // 應該有變化
        verify(() => mockSecurityService.validateContent(any())).called(1);
      });

      test('should throw UnsupportedImageFormatFailure for invalid image', () async {
        // Arrange
        when(() => mockSecurityService.validateContent(any()))
            .thenReturn(const Right('validated'));

        // Act & Assert
        await expectLater(
          ocrService.preprocessImage(invalidImageData),
          throwsA(isA<UnsupportedImageFormatFailure>()),
        );
      });
    });

    group('confidence estimation', () {
      test('should estimate confidence based on text characteristics', () async {
        // Arrange - 測試不同類型的文字
        when(() => mockUuid.v4()).thenReturn('test-confidence');
        when(() => mockSecurityService.validateContent(any()))
            .thenReturn(const Right('validated'));

        // 建立包含不同文字特徵的 mock
        final shortTextMock = _createMockRecognizedTextWithContent(['A']); // 短文字
        final longTextMock = _createMockRecognizedTextWithContent(['這是一段較長的中文文字識別測試']); // 長文字
        final suspiciousMock = _createMockRecognizedTextWithContent([r'|||\\///__']); // 可疑字符

        // Test short text (lower confidence)
        when(() => mockTextRecognizer.processImage(any()))
            .thenAnswer((_) async => shortTextMock);
        final shortResult = await ocrService.recognizeText(validJpegData);
        
        // Test long text (higher confidence)  
        when(() => mockTextRecognizer.processImage(any()))
            .thenAnswer((_) async => longTextMock);
        final longResult = await ocrService.recognizeText(validJpegData);
        
        // Test suspicious text (lower confidence)
        when(() => mockTextRecognizer.processImage(any()))
            .thenAnswer((_) async => suspiciousMock);
        final suspiciousResult = await ocrService.recognizeText(validJpegData);

        // Assert
        expect(longResult.confidence, greaterThan(shortResult.confidence));
        expect(shortResult.confidence, greaterThan(suspiciousResult.confidence));
        
        // 所有信心度都應該在有效範圍內
        expect(shortResult.confidence, greaterThanOrEqualTo(0.0));
        expect(shortResult.confidence, lessThanOrEqualTo(1.0));
        expect(longResult.confidence, greaterThanOrEqualTo(0.0));
        expect(longResult.confidence, lessThanOrEqualTo(1.0));
        expect(suspiciousResult.confidence, greaterThanOrEqualTo(0.0));
        expect(suspiciousResult.confidence, lessThanOrEqualTo(1.0));
      });
    });

    group('memory and resource management', () {
      test('should handle large image data efficiently', () async {
        // Arrange - 建立較大但合理的圖片資料
        final largeImageData = Uint8List(5 * 1024 * 1024); // 5MB
        largeImageData.setAll(0, [0xFF, 0xD8, 0xFF]); // JPEG header
        
        when(() => mockUuid.v4()).thenReturn('test-large-image');
        when(() => mockSecurityService.validateContent(any()))
            .thenReturn(const Right('validated'));
        when(() => mockTextRecognizer.processImage(any()))
            .thenAnswer((_) async => mockRecognizedText);

        // Act
        final result = await ocrService.recognizeText(largeImageData);

        // Assert
        expect(result, isNotNull);
        expect(result.processingTimeMs, isNotNull);
        verify(() => mockTextRecognizer.processImage(any())).called(1);
      });

      test('should dispose resources properly', () {
        // Act
        ocrService.dispose();

        // Assert - 驗證 TextRecognizer 被正確關閉
        verify(() => mockTextRecognizer.close()).called(1);
      });
    });

    group('error handling edge cases', () {
      test('should handle out of memory errors', () async {
        // Arrange
        when(() => mockSecurityService.validateContent(any()))
            .thenReturn(const Right('validated'));
        when(() => mockTextRecognizer.processImage(any()))
            .thenThrow(Exception('OutOfMemoryError'));

        // Act & Assert
        await expectLater(
          ocrService.recognizeText(validJpegData),
          throwsA(isA<ImageTooLargeFailure>().having(
            (failure) => failure.userMessage,
            'userMessage',
            contains('記憶體不足'),
          )),
        );
      });

      test('should handle timeout correctly', () async {
        // Arrange
        when(() => mockSecurityService.validateContent(any()))
            .thenReturn(const Right('validated'));
        when(() => mockTextRecognizer.processImage(any()))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(seconds: 31)); // 超過 30 秒超時
              return mockRecognizedText;
            });

        // Act & Assert
        await expectLater(
          ocrService.recognizeText(validJpegData),
          throwsA(isA<OCRServiceUnavailableFailure>().having(
            (failure) => failure.userMessage,
            'userMessage',
            contains('OCR 處理超時'),
          )),
        );
      }, timeout: const Timeout(Duration(seconds: 35))); // 設定測試超時時間
    });
  });
}

/// 建立 Mock RecognizedText 用於測試
RecognizedText _createMockRecognizedText() {
  return _createMockRecognizedTextWithContent([
    '張三',
    'ABC科技公司',
    '產品經理',
    '02-1234-5678',
  ]);
}

/// 建立包含指定內容的 Mock RecognizedText
RecognizedText _createMockRecognizedTextWithContent(List<String> contents) {
  final mockRecognizedText = MockRecognizedText();
  final mockBlocks = <TextBlock>[];

  for (final content in contents) {
    final mockBlock = MockTextBlock();
    final mockLine = MockTextLine();
    final mockElement = MockTextElement();
    
    when(() => mockElement.text).thenReturn(content);
    when(() => mockLine.text).thenReturn(content);
    when(() => mockLine.elements).thenReturn([mockElement]);
    when(() => mockBlock.lines).thenReturn([mockLine]);
    
    mockBlocks.add(mockBlock);
  }

  when(() => mockRecognizedText.blocks).thenReturn(mockBlocks);
  return mockRecognizedText;
}