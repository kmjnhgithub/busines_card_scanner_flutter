import 'package:busines_card_scanner_flutter/data/datasources/local/secure/enhanced_secure_storage.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/openai_service.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}
class MockEnhancedSecureStorage extends Mock implements EnhancedSecureStorage {}
void main() {
  group('OpenAIService', () {
    late OpenAIService service;
    late MockDio mockDio;
    late MockEnhancedSecureStorage mockStorage;

    setUp(() {
      mockDio = MockDio();
      mockStorage = MockEnhancedSecureStorage();
      service = OpenAIServiceImpl(
        dio: mockDio,
        secureStorage: mockStorage,
      );
    });

    group('parseCardFromText', () {
      const testOcrText = '''
        張三
        ABC科技股份有限公司
        產品經理
        TEL: (02)1234-5678
        Mobile: 0912-345-678
        E-mail: zhang.san@abc.com.tw
        Address: 台北市信義區信義路100號8樓
        ''';

      test('should successfully parse card data with valid API key', () async {
        // Arrange
        const apiKey = 'test-api-key';
        final mockResponse = {
          'choices': [
            {
              'message': {
                'content': '''
{
                  "name": "張三",
                  "company": "ABC科技股份有限公司",
                  "jobTitle": "產品經理",
                  "phone": "(02)1234-5678",
                  "mobile": "0912-345-678",
                  "email": "zhang.san@abc.com.tw",
                  "address": "台北市信義區信義路100號8樓",
                  "confidence": 0.95
                }'''
              }
            }
          ]
        };

        when(() => mockStorage.getApiKey('openai_api_key'))
            .thenAnswer((_) async => const Right(apiKey));
        when(() => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          data: mockResponse,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

        // Act
        final result = await service.parseCardFromText(testOcrText);

        // Assert
        expect(result.name, equals('張三'));
        expect(result.company, equals('ABC科技股份有限公司'));
        expect(result.jobTitle, equals('產品經理'));
        expect(result.phone, equals('(02)1234-5678'));
        expect(result.mobile, equals('0912-345-678'));
        expect(result.email, equals('zhang.san@abc.com.tw'));
        expect(result.address, equals('台北市信義區信義路100號8樓'));
        expect(result.confidence, equals(0.95));
        expect(result.source, equals(ParseSource.ai));

        // 驗證 API 調用
        verify(() => mockStorage.getApiKey('openai_api_key')).called(1);
        verify(() => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).called(1);
      });

      test('should throw AIServiceUnavailableFailure when API key is missing', () async {
        // Arrange
        when(() => mockStorage.getApiKey('openai_api_key'))
            .thenAnswer((_) async => const Left(DataSourceFailure(userMessage: 'Not found')));

        // Act & Assert
        await expectLater(
          service.parseCardFromText(testOcrText),
          throwsA(isA<AIServiceUnavailableFailure>()),
        );

        verifyNever(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options')));
      });

      test('should throw AIServiceUnavailableFailure when API key is empty', () async {
        // Arrange
        when(() => mockStorage.getApiKey('openai_api_key'))
            .thenAnswer((_) async => const Right(''));

        // Act & Assert
        await expectLater(
          service.parseCardFromText(testOcrText),
          throwsA(isA<AIServiceUnavailableFailure>()),
        );
      });

      test('should throw InvalidInputFailure for empty or invalid text', () async {
        // Arrange
        const apiKey = 'test-api-key';
        when(() => mockStorage.getApiKey('openai_api_key'))
            .thenAnswer((_) async => const Right(apiKey));

        // Act & Assert - 空字串
        await expectLater(
          service.parseCardFromText(''),
          throwsA(isA<InvalidInputFailure>()),
        );

        // Act & Assert - 只有空格
        await expectLater(
          service.parseCardFromText('   '),
          throwsA(isA<InvalidInputFailure>()),
        );

        // Act & Assert - 超長文字（假設限制是 10000 字元）
        final longText = 'x' * 10001;
        await expectLater(
          service.parseCardFromText(longText),
          throwsA(isA<InvalidInputFailure>()),
        );
      });

      test('should throw AIQuotaExceededFailure when API quota is exceeded', () async {
        // Arrange
        const apiKey = 'test-api-key';
        when(() => mockStorage.getApiKey('openai_api_key'))
            .thenAnswer((_) async => const Right(apiKey));
        when(() => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(),
          response: Response(
            statusCode: 429,
            statusMessage: 'Too Many Requests',
            data: {'error': {'code': 'quota_exceeded'}},
            requestOptions: RequestOptions(),
          ),
        ));

        // Act & Assert
        await expectLater(
          service.parseCardFromText(testOcrText),
          throwsA(isA<AIQuotaExceededFailure>()),
        );
      });

      test('should throw AIRateLimitFailure when rate limit is exceeded', () async {
        // Arrange
        const apiKey = 'test-api-key';
        when(() => mockStorage.getApiKey('openai_api_key'))
            .thenAnswer((_) async => const Right(apiKey));
        when(() => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(),
          response: Response(
            statusCode: 429,
            statusMessage: 'Too Many Requests',
            data: {'error': {'code': 'rate_limit_exceeded'}},
            requestOptions: RequestOptions(),
          ),
        ));

        // Act & Assert
        await expectLater(
          service.parseCardFromText(testOcrText),
          throwsA(isA<AIRateLimitFailure>()),
        );
      });

      test('should handle malformed JSON response gracefully', () async {
        // Arrange
        const apiKey = 'test-api-key';
        final mockResponse = {
          'choices': [
            {
              'message': {
                'content': 'invalid json {'
              }
            }
          ]
        };

        when(() => mockStorage.getApiKey('openai_api_key'))
            .thenAnswer((_) async => const Right(apiKey));
        when(() => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          data: mockResponse,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

        // Act & Assert
        await expectLater(
          service.parseCardFromText(testOcrText),
          throwsA(isA<AIServiceUnavailableFailure>()),
        );
      });

      test('should sanitize and validate AI response data', () async {
        // Arrange
        const apiKey = 'test-api-key';
        final mockResponse = {
          'choices': [
            {
              'message': {
                'content': '''
{
                  "name": "",
                  "company": "ABC公司",
                  "email": "not-an-email",
                  "phone": "123",
                  "confidence": 1.5,
                  "maliciousField": "<script>alert('xss')</script>"
                }'''
              }
            }
          ]
        };

        when(() => mockStorage.getApiKey('openai_api_key'))
            .thenAnswer((_) async => const Right(apiKey));
        when(() => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          data: mockResponse,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

        // Act
        final result = await service.parseCardFromText(testOcrText);

        // Assert
        expect(result.name, isNull); // 空值被清理為 null
        expect(result.email, isNull); // 無效 email 被過濾
        expect(result.phone, isNull); // 無效電話被過濾
        expect(result.confidence, lessThanOrEqualTo(1.0)); // 信心度被修正
        expect(result.company, equals('ABC公司')); // 有效 company 欄位保留
      });

      test('should include proper prompt and model configuration', () async {
        // Arrange
        const apiKey = 'test-api-key';
        final mockResponse = {
          'choices': [
            {
              'message': {
                'content': '{"name": "張三", "confidence": 0.9}'
              }
            }
          ]
        };

        when(() => mockStorage.getApiKey('openai_api_key'))
            .thenAnswer((_) async => const Right(apiKey));
        when(() => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          data: mockResponse,
          statusCode: 200,
          requestOptions: RequestOptions(),
        ));

        // Act
        await service.parseCardFromText(testOcrText);

        // Assert
        final capturedCall = verify(() => mockDio.post(
          captureAny(),
          data: captureAny(named: 'data'),
          options: captureAny(named: 'options'),
        )).captured;

        final url = capturedCall[0] as String;
        final data = capturedCall[1] as Map<String, dynamic>;

        expect(url, contains('openai.com'));
        expect(data['model'], equals('gpt-3.5-turbo'));
        expect(data['messages'], isA<List>());
        expect(data['temperature'], equals(0.1)); // 低溫度確保一致性
        expect(data['max_tokens'], isA<int>());
        
        // 檢查 system prompt 包含適當的指示
        final messages = data['messages'] as List;
        final systemMessage = messages.firstWhere(
          (msg) => msg['role'] == 'system',
        );
        expect(systemMessage['content'], contains('JSON'));
        expect(systemMessage['content'], contains('名片'));
      });
    });

    group('parseCardsFromTexts', () {
      test('should handle batch processing successfully', () async {
        // TODO: 實作批次處理測試
      });

      test('should handle partial failures in batch', () async {
        // TODO: 實作批次處理部分失敗測試
      });
    });

    group('getServiceStatus', () {
      test('should return service status without exposing API key', () async {
        // Arrange
        const apiKey = 'test-api-key';
        when(() => mockStorage.getApiKey('openai_api_key'))
            .thenAnswer((_) async => const Right(apiKey));
        when(() => mockDio.get(
          any(),
          options: any(named: 'options'),
        )).thenAnswer((_) async => Response(
          data: {'data': []},
          statusCode: 200,
          requestOptions: RequestOptions(),
          headers: Headers.fromMap({
            'x-ratelimit-remaining-requests': ['100'],
            'x-ratelimit-reset-requests': ['2024-01-01T00:00:00Z'],
          }),
        ));

        // Act
        final status = await service.getServiceStatus();

        // Assert
        expect(status.isAvailable, isTrue);
        expect(status.remainingQuota, equals(100));
        expect(status.quotaResetAt, isA<DateTime>());
        expect(status.checkedAt, isA<DateTime>());
        expect(status.responseTimeMs, isA<double>());
        expect(status.error, isNull);
      });

      test('should handle service unavailable gracefully', () async {
        // Arrange
        when(() => mockStorage.getApiKey('openai_api_key'))
            .thenAnswer((_) async => const Left(DataSourceFailure(userMessage: 'Not found')));

        // Act
        final status = await service.getServiceStatus();

        // Assert
        expect(status.isAvailable, isFalse);
        expect(status.error, isNotNull);
      });
    });

    group('security and validation', () {
      test('should detect and reject malicious input', () async {
        // Arrange
        const maliciousTexts = [
          '<script>alert("xss")</script>',
          '<?xml version="1.0"?><!DOCTYPE foo [<!ELEMENT foo ANY><!ENTITY xxe SYSTEM "file:///etc/passwd">]><foo>&xxe;</foo>',
          'SELECT * FROM users WHERE id = 1; DROP TABLE users;--',
        ];

        // Act & Assert
        for (final maliciousText in maliciousTexts) {
          await expectLater(
            service.parseCardFromText(maliciousText),
            throwsA(isA<InvalidInputFailure>()),
          );
        }
      });

      test('should not log sensitive information', () async {
        // 此測試確保 API Key 不會出現在錯誤訊息或日誌中
        // 實際實作中需要檢查日誌輸出
        expect(true, isTrue); // 佔位符測試
      });
    });

    group('error handling and resilience', () {
      test('should implement exponential backoff for retries', () async {
        // TODO: 實作重試機制測試
      });

      test('should handle network timeouts gracefully', () async {
        // Arrange
        const apiKey = 'test-api-key';
        when(() => mockStorage.getApiKey('openai_api_key'))
            .thenAnswer((_) async => const Right(apiKey));
        when(() => mockDio.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.receiveTimeout,
        ));

        // Act & Assert
        await expectLater(
          service.parseCardFromText('test'),
          throwsA(isA<AIServiceUnavailableFailure>()),
        );
      });
    });
  });
}