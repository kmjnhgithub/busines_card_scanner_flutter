import 'dart:typed_data';

import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OCRResult Entity Tests', () {
    late DateTime testDateTime;
    late Uint8List testImageData;

    setUp(() {
      testDateTime = DateTime(2024, 1, 15, 10, 30);
      // Create a small test image (1x1 pixel)
      testImageData = Uint8List.fromList([255, 255, 255, 255]);
    });

    group('Construction and Properties', () {
      test('should create OCRResult with all fields', () {
        // Arrange
        final detectedTexts = ['John Doe', 'Software Engineer', 'john@example.com'];
        const confidence = 0.95;

        // Act
        final result = OCRResult(
          id: 'ocr-123',
          rawText: 'John Doe\nSoftware Engineer\njohn@example.com',
          detectedTexts: detectedTexts,
          confidence: confidence,
          imageData: testImageData,
          imageWidth: 100,
          imageHeight: 200,
          processedAt: testDateTime,
          processingTimeMs: 1500,
          ocrEngine: 'Google ML Kit',
        );

        // Assert
        expect(result.id, 'ocr-123');
        expect(result.rawText, 'John Doe\nSoftware Engineer\njohn@example.com');
        expect(result.detectedTexts, detectedTexts);
        expect(result.confidence, confidence);
        expect(result.imageData, testImageData);
        expect(result.imageWidth, 100);
        expect(result.imageHeight, 200);
        expect(result.processedAt, testDateTime);
        expect(result.processingTimeMs, 1500);
        expect(result.ocrEngine, 'Google ML Kit');
      });

      test('should create OCRResult with minimal required fields', () {
        // Arrange & Act
        final result = OCRResult(
          id: 'ocr-456',
          rawText: 'Simple text',
          confidence: 0.8,
          processedAt: testDateTime,
        );

        // Assert
        expect(result.id, 'ocr-456');
        expect(result.rawText, 'Simple text');
        expect(result.confidence, 0.8);
        expect(result.processedAt, testDateTime);
        expect(result.detectedTexts, isNull);
        expect(result.imageData, isNull);
        expect(result.imageWidth, isNull);
        expect(result.imageHeight, isNull);
        expect(result.processingTimeMs, isNull);
        expect(result.ocrEngine, isNull);
      });

      test('should handle empty detected texts list', () {
        // Arrange & Act
        final result = OCRResult(
          id: 'ocr-789',
          rawText: '',
          detectedTexts: const [],
          confidence: 0,
          processedAt: testDateTime,
        );

        // Assert
        expect(result.detectedTexts, isEmpty);
        expect(result.confidence, 0.0);
      });
    });

    group('Validation Logic', () {
      test('should validate required fields', () {
        expect(
          () => OCRResult(
            id: '', // Empty id should be invalid
            rawText: 'Some text',
            confidence: 0.5,
            processedAt: testDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => OCRResult(
            id: 'ocr-123',
            rawText: 'Some text',
            confidence: -0.1, // Negative confidence should be invalid
            processedAt: testDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => OCRResult(
            id: 'ocr-123',
            rawText: 'Some text',
            confidence: 1.1, // Confidence > 1.0 should be invalid
            processedAt: testDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should validate image dimensions if provided', () {
        expect(
          () => OCRResult(
            id: 'ocr-123',
            rawText: 'Some text',
            confidence: 0.5,
            imageWidth: 0, // Zero width should be invalid
            imageHeight: 100,
            processedAt: testDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => OCRResult(
            id: 'ocr-123',
            rawText: 'Some text',
            confidence: 0.5,
            imageWidth: 100,
            imageHeight: -50, // Negative height should be invalid
            processedAt: testDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should validate processing time if provided', () {
        expect(
          () => OCRResult(
            id: 'ocr-123',
            rawText: 'Some text',
            confidence: 0.5,
            processingTimeMs: -100, // Negative processing time should be invalid
            processedAt: testDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should allow valid values', () {
        expect(
          () => OCRResult(
            id: 'ocr-123',
            rawText: 'Valid text',
            confidence: 0.85,
            imageWidth: 800,
            imageHeight: 600,
            processingTimeMs: 2000,
            processedAt: testDateTime,
          ),
          returnsNormally,
        );
      });
    });

    group('Equality and Hash Code', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        final result1 = OCRResult(
          id: 'ocr-123',
          rawText: 'Same text',
          confidence: 0.9,
          processedAt: testDateTime,
        );

        final result2 = OCRResult(
          id: 'ocr-123',
          rawText: 'Same text',
          confidence: 0.9,
          processedAt: testDateTime,
        );

        // Act & Assert
        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('should not be equal when ids are different', () {
        // Arrange
        final result1 = OCRResult(
          id: 'ocr-123',
          rawText: 'Same text',
          confidence: 0.9,
          processedAt: testDateTime,
        );

        final result2 = OCRResult(
          id: 'ocr-456',
          rawText: 'Same text',
          confidence: 0.9,
          processedAt: testDateTime,
        );

        // Act & Assert
        expect(result1, isNot(equals(result2)));
      });

      test('should not be equal when confidence is different', () {
        // Arrange
        final result1 = OCRResult(
          id: 'ocr-123',
          rawText: 'Same text',
          confidence: 0.9,
          processedAt: testDateTime,
        );

        final result2 = OCRResult(
          id: 'ocr-123',
          rawText: 'Same text',
          confidence: 0.8,
          processedAt: testDateTime,
        );

        // Act & Assert
        expect(result1, isNot(equals(result2)));
      });
    });

    group('toString Method', () {
      test('should return proper string representation', () {
        // Arrange
        final result = OCRResult(
          id: 'ocr-123',
          rawText: 'Test text',
          confidence: 0.85,
          ocrEngine: 'TestEngine',
          processedAt: testDateTime,
        );

        // Act
        final stringResult = result.toString();

        // Assert
        expect(stringResult, contains('OCRResult'));
        expect(stringResult, contains('ocr-123'));
        expect(stringResult, contains('0.85'));
        expect(stringResult, contains('TestEngine'));
      });

      test('should not expose sensitive data in toString', () {
        // Arrange
        final result = OCRResult(
          id: 'ocr-123',
          rawText: 'Confidential information',
          confidence: 0.9,
          imageData: testImageData,
          processedAt: testDateTime,
        );

        // Act
        final stringResult = result.toString();

        // Assert
        // Should not expose full raw text or image data
        expect(stringResult, isNot(contains('Confidential information')));
        expect(stringResult, isNot(contains(testImageData.toString())));
      });
    });

    group('Business Logic Methods', () {
      test('should check if result is high confidence', () {
        // Arrange
        final highConfidenceResult = OCRResult(
          id: 'ocr-123',
          rawText: 'Clear text',
          confidence: 0.95,
          processedAt: testDateTime,
        );

        final lowConfidenceResult = OCRResult(
          id: 'ocr-456',
          rawText: 'Unclear text',
          confidence: 0.6,
          processedAt: testDateTime,
        );

        // Act & Assert
        expect(highConfidenceResult.isHighConfidence(), isTrue);
        expect(lowConfidenceResult.isHighConfidence(), isFalse);
      });

      test('should check if result has detected texts', () {
        // Arrange
        final resultWithTexts = OCRResult(
          id: 'ocr-123',
          rawText: 'Some text',
          detectedTexts: const ['Text 1', 'Text 2'],
          confidence: 0.8,
          processedAt: testDateTime,
        );

        final resultWithoutTexts = OCRResult(
          id: 'ocr-456',
          rawText: 'Some text',
          confidence: 0.8,
          processedAt: testDateTime,
        );

        // Act & Assert
        expect(resultWithTexts.hasDetectedTexts(), isTrue);
        expect(resultWithoutTexts.hasDetectedTexts(), isFalse);
      });

      test('should get processing performance info', () {
        // Arrange
        final result = OCRResult(
          id: 'ocr-123',
          rawText: 'Test text',
          confidence: 0.8,
          processingTimeMs: 1500,
          processedAt: testDateTime,
        );

        // Act
        final performance = result.getPerformanceInfo();

        // Assert
        expect(performance['processingTimeMs'], 1500);
        expect(performance['confidence'], 0.8);
        expect(performance['textLength'], 9); // 'Test text'.length
      });

      test('should extract email addresses from detected texts', () {
        // Arrange
        final result = OCRResult(
          id: 'ocr-123',
          rawText: 'John Doe john@example.com Software Engineer',
          detectedTexts: const [
            'John Doe',
            'john@example.com',
            'jane@company.org',
            'Software Engineer',
            'invalid-email'
          ],
          confidence: 0.8,
          processedAt: testDateTime,
        );

        // Act
        final emails = result.extractEmails();

        // Assert
        expect(emails, hasLength(2));
        expect(emails, contains('john@example.com'));
        expect(emails, contains('jane@company.org'));
        expect(emails, isNot(contains('invalid-email')));
      });

      test('should extract phone numbers from detected texts', () {
        // Arrange
        final result = OCRResult(
          id: 'ocr-123',
          rawText: 'John Doe +1-555-123-4567',
          detectedTexts: const [
            'John Doe',
            '+1-555-123-4567',
            '02-1234-5678',
            'Software Engineer',
            '123' // Too short to be a phone number
          ],
          confidence: 0.8,
          processedAt: testDateTime,
        );

        // Act
        final phones = result.extractPhoneNumbers();

        // Assert
        expect(phones, hasLength(2));
        expect(phones, contains('+1-555-123-4567'));
        expect(phones, contains('02-1234-5678'));
        expect(phones, isNot(contains('123')));
      });

      test('should create copy with updated fields', () {
        // Arrange
        final original = OCRResult(
          id: 'ocr-123',
          rawText: 'Original text',
          confidence: 0.8,
          ocrEngine: 'Engine 1',
          processedAt: testDateTime,
        );

        // Act
        final updated = original.copyWith(
          rawText: 'Updated text',
          confidence: 0.9,
          ocrEngine: 'Engine 2',
        );

        // Assert
        expect(updated.id, original.id); // Should remain same
        expect(updated.rawText, 'Updated text');
        expect(updated.confidence, 0.9);
        expect(updated.ocrEngine, 'Engine 2');
        expect(updated.processedAt, original.processedAt); // Should remain same
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle very long text correctly', () {
        // Arrange
        final longText = 'A' * 10000;

        // Act & Assert
        expect(
          () => OCRResult(
            id: 'ocr-123',
            rawText: longText,
            confidence: 0.8,
            processedAt: testDateTime,
          ),
          returnsNormally,
        );
      });

      test('should handle special characters in text', () {
        // Arrange
        const specialText = r'特殊字符 José García-López 🚀 @#$%^&*()';

        // Act & Assert
        expect(
          () => OCRResult(
            id: 'ocr-123',
            rawText: specialText,
            confidence: 0.8,
            processedAt: testDateTime,
          ),
          returnsNormally,
        );
      });

      test('should handle large image dimensions', () {
        // Act & Assert
        expect(
          () => OCRResult(
            id: 'ocr-123',
            rawText: 'Test',
            confidence: 0.8,
            imageWidth: 4096,
            imageHeight: 4096,
            processedAt: testDateTime,
          ),
          returnsNormally,
        );
      });

      test('should handle empty raw text', () {
        // Act & Assert
        expect(
          () => OCRResult(
            id: 'ocr-123',
            rawText: '',
            confidence: 0,
            processedAt: testDateTime,
          ),
          returnsNormally,
        );
      });
    });

    group('Security Considerations', () {
      test('should not allow malicious content in text fields', () {
        expect(
          () => OCRResult(
            id: 'ocr-123',
            rawText: '<script>alert("XSS")</script>',
            confidence: 0.8,
            processedAt: testDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should sanitize OCR engine name', () {
        expect(
          () => OCRResult(
            id: 'ocr-123',
            rawText: 'Clean text',
            confidence: 0.8,
            ocrEngine: '<script>malicious</script>',
            processedAt: testDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle safe content correctly', () {
        expect(
          () => OCRResult(
            id: 'ocr-123',
            rawText: 'Safe business card text with numbers 123 and symbols @#%',
            confidence: 0.8,
            ocrEngine: 'Google ML Kit v2.0',
            processedAt: testDateTime,
          ),
          returnsNormally,
        );
      });
    });

    group('Performance Tests', () {
      test('should handle multiple detected texts efficiently', () {
        // Arrange
        final manyTexts = List.generate(1000, (i) => 'Text $i');

        // Act
        final stopwatch = Stopwatch()..start();
        final result = OCRResult(
          id: 'ocr-123',
          rawText: manyTexts.join('\n'),
          detectedTexts: manyTexts,
          confidence: 0.8,
          processedAt: testDateTime,
        );
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(result.detectedTexts, hasLength(1000));
      });

      test('should handle large image data efficiently', () {
        // Arrange
        final largeImageData = Uint8List(1024 * 1024); // 1MB

        // Act & Assert
        expect(
          () => OCRResult(
            id: 'ocr-123',
            rawText: 'Text from large image',
            confidence: 0.8,
            imageData: largeImageData,
            processedAt: testDateTime,
          ),
          returnsNormally,
        );
      });
    });
  });
}