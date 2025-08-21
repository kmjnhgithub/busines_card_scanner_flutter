import 'package:busines_card_scanner_flutter/data/datasources/local/secure/enhanced_secure_storage.dart';
import 'package:busines_card_scanner_flutter/data/repositories/api_key_repository_impl.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/api_key_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mock classes for testing
class MockEnhancedSecureStorage extends Mock implements EnhancedSecureStorage {}

void main() {
  group('ApiKeyRepositoryImpl', () {
    late ApiKeyRepository repository;
    late MockEnhancedSecureStorage mockSecureStorage;

    setUp(() {
      mockSecureStorage = MockEnhancedSecureStorage();
      repository = ApiKeyRepositoryImpl(secureStorage: mockSecureStorage);
    });

    group('storeApiKey', () {
      const testService = 'openai';
      const testApiKey = 'sk-123456789012345678901234567890123456789012345678';

      test('should store API key successfully when inputs are valid', () async {
        // Given
        when(
          () => mockSecureStorage.storeApiKey(testService, testApiKey),
        ).thenAnswer((_) async => const Right(null));

        // When
        final result = await repository.storeApiKey(testService, testApiKey);

        // Then
        expect(result, const Right(null));
        verify(
          () => mockSecureStorage.storeApiKey(testService, testApiKey),
        ).called(1);
      });

      test(
        'should return DomainValidationFailure when service name is empty',
        () async {
          // Given
          const emptyService = '';

          // When
          final result = await repository.storeApiKey(emptyService, testApiKey);

          // Then
          expect(result, isA<Left<DomainFailure, void>>());
          result.fold((failure) {
            expect(failure, isA<DomainValidationFailure>());
            final validationFailure = failure as DomainValidationFailure;
            expect(validationFailure.userMessage, equals('服務名稱和 API Key 不能為空'));
            expect(validationFailure.field, equals('service'));
          }, (_) => fail('Expected Left but got Right'));
          verifyNever(() => mockSecureStorage.storeApiKey(any(), any()));
        },
      );

      test(
        'should return DomainValidationFailure when API key is empty',
        () async {
          // Given
          const emptyApiKey = '';

          // When
          final result = await repository.storeApiKey(testService, emptyApiKey);

          // Then
          expect(result, isA<Left<DomainFailure, void>>());
          result.fold((failure) {
            expect(failure, isA<DomainValidationFailure>());
            final validationFailure = failure as DomainValidationFailure;
            expect(validationFailure.userMessage, equals('服務名稱和 API Key 不能為空'));
            expect(validationFailure.field, equals('apiKey'));
          }, (_) => fail('Expected Left but got Right'));
          verifyNever(() => mockSecureStorage.storeApiKey(any(), any()));
        },
      );

      test('should handle storage operation failure', () async {
        // Given
        const storageFailure = DataSourceFailure(
          userMessage: 'Storage operation failed',
          internalMessage: 'Keychain access denied',
        );
        when(
          () => mockSecureStorage.storeApiKey(testService, testApiKey),
        ).thenAnswer((_) async => Left(storageFailure));

        // When
        final result = await repository.storeApiKey(testService, testApiKey);

        // Then
        expect(result, isA<Left<DomainFailure, void>>());
        verify(
          () => mockSecureStorage.storeApiKey(testService, testApiKey),
        ).called(1);
      });
    });

    group('getApiKey', () {
      const testService = 'openai';
      const testApiKey = 'sk-123456789012345678901234567890123456789012345678';

      test('should return API key when storage contains the key', () async {
        // Given
        when(
          () => mockSecureStorage.getApiKey(testService),
        ).thenAnswer((_) async => const Right(testApiKey));

        // When
        final result = await repository.getApiKey(testService);

        // Then
        expect(result, const Right(testApiKey));
        verify(() => mockSecureStorage.getApiKey(testService)).called(1);
      });

      test(
        'should return DomainValidationFailure when service name is empty',
        () async {
          // Given
          const emptyService = '';

          // When
          final result = await repository.getApiKey(emptyService);

          // Then
          expect(result, isA<Left<DomainFailure, String>>());
          result.fold((failure) {
            expect(failure, isA<DomainValidationFailure>());
            final validationFailure = failure as DomainValidationFailure;
            expect(validationFailure.userMessage, equals('服務名稱不能為空'));
            expect(validationFailure.field, equals('service'));
          }, (_) => fail('Expected Left but got Right'));
          verifyNever(() => mockSecureStorage.getApiKey(any()));
        },
      );

      test('should handle storage operation failure', () async {
        // Given
        const storageFailure = DataSourceFailure(
          userMessage: 'Key not found',
          internalMessage: 'No key stored for service',
        );
        when(
          () => mockSecureStorage.getApiKey(testService),
        ).thenAnswer((_) async => Left(storageFailure));

        // When
        final result = await repository.getApiKey(testService);

        // Then
        expect(result, isA<Left<DomainFailure, String>>());
        verify(() => mockSecureStorage.getApiKey(testService)).called(1);
      });
    });

    group('deleteApiKey', () {
      const testService = 'openai';

      test('should delete API key successfully', () async {
        // Given
        when(
          () => mockSecureStorage.deleteApiKey(testService),
        ).thenAnswer((_) async => const Right(null));

        // When
        final result = await repository.deleteApiKey(testService);

        // Then
        expect(result, const Right(null));
        verify(() => mockSecureStorage.deleteApiKey(testService)).called(1);
      });

      test(
        'should return DomainValidationFailure when service name is empty',
        () async {
          // Given
          const emptyService = '';

          // When
          final result = await repository.deleteApiKey(emptyService);

          // Then
          expect(result, isA<Left<DomainFailure, void>>());
          result.fold((failure) {
            expect(failure, isA<DomainValidationFailure>());
            final validationFailure = failure as DomainValidationFailure;
            expect(validationFailure.userMessage, equals('服務名稱不能為空'));
            expect(validationFailure.field, equals('service'));
          }, (_) => fail('Expected Left but got Right'));
          verifyNever(() => mockSecureStorage.deleteApiKey(any()));
        },
      );
    });

    group('hasApiKey', () {
      const testService = 'openai';

      test('should return true when API key exists', () async {
        // Given
        when(
          () => mockSecureStorage.hasApiKey(testService),
        ).thenAnswer((_) async => const Right(true));

        // When
        final result = await repository.hasApiKey(testService);

        // Then
        expect(result, const Right(true));
        verify(() => mockSecureStorage.hasApiKey(testService)).called(1);
      });

      test('should return false when API key does not exist', () async {
        // Given
        when(
          () => mockSecureStorage.hasApiKey(testService),
        ).thenAnswer((_) async => const Right(false));

        // When
        final result = await repository.hasApiKey(testService);

        // Then
        expect(result, const Right(false));
        verify(() => mockSecureStorage.hasApiKey(testService)).called(1);
      });
    });

    group('validateApiKeyFormat', () {
      test('should validate OpenAI API key format correctly', () async {
        // Given
        const service = 'openai';
        const validKey = 'sk-123456789012345678901234567890123456789012345678';

        // When
        final result = await repository.validateApiKeyFormat(service, validKey);

        // Then
        expect(result, const Right(true));
      });

      test('should invalidate incorrect OpenAI API key format', () async {
        // Given
        const service = 'openai';
        const invalidKey = 'invalid-openai-key';

        // When
        final result = await repository.validateApiKeyFormat(
          service,
          invalidKey,
        );

        // Then
        expect(result, const Right(false));
      });

      test('should validate Anthropic API key format correctly', () async {
        // Given
        const service = 'anthropic';
        const validKey =
            'sk-ant-api03-1234567890abcdef1234567890abcdef1234567890abcdef';

        // When
        final result = await repository.validateApiKeyFormat(service, validKey);

        // Then
        expect(result, const Right(true));
      });

      test('should use generic validation for unknown services', () async {
        // Given
        const service = 'unknown';
        const validGenericKey = 'abcd1234efgh5678'; // >= 8 chars, alphanumeric

        // When
        final result = await repository.validateApiKeyFormat(
          service,
          validGenericKey,
        );

        // Then
        expect(result, const Right(true));
      });

      test(
        'should return DomainValidationFailure when service is empty',
        () async {
          // Given
          const emptyService = '';
          const validKey =
              'sk-123456789012345678901234567890123456789012345678';

          // When
          final result = await repository.validateApiKeyFormat(
            emptyService,
            validKey,
          );

          // Then
          expect(result, isA<Left<DomainFailure, bool>>());
          result.fold((failure) {
            expect(failure, isA<DomainValidationFailure>());
            final validationFailure = failure as DomainValidationFailure;
            expect(validationFailure.userMessage, equals('服務名稱和 API Key 不能為空'));
            expect(validationFailure.field, equals('service'));
          }, (_) => fail('Expected Left but got Right'));
        },
      );

      test(
        'should return DomainValidationFailure when API key is empty',
        () async {
          // Given
          const service = 'openai';
          const emptyKey = '';

          // When
          final result = await repository.validateApiKeyFormat(
            service,
            emptyKey,
          );

          // Then
          expect(result, isA<Left<DomainFailure, bool>>());
          result.fold((failure) {
            expect(failure, isA<DomainValidationFailure>());
            final validationFailure = failure as DomainValidationFailure;
            expect(validationFailure.userMessage, equals('服務名稱和 API Key 不能為空'));
            expect(validationFailure.field, equals('apiKey'));
          }, (_) => fail('Expected Left but got Right'));
        },
      );
    });

    group('getApiKeySummary', () {
      const testService = 'openai';
      const testApiKey = 'sk-123456789012345678901234567890123456789012345678';

      test('should return API key summary when key exists', () async {
        // Given
        when(
          () => mockSecureStorage.getApiKey(testService),
        ).thenAnswer((_) async => const Right(testApiKey));

        // When
        final result = await repository.getApiKeySummary(testService);

        // Then
        expect(result, isA<Right<DomainFailure, ApiKeySummary>>());
        result.fold((_) => fail('Expected Right but got Left'), (summary) {
          expect(summary.service, equals(testService));
          expect(summary.prefix, equals('sk-1'));
          expect(summary.length, equals(testApiKey.length));
          expect(summary.isValidFormat, isTrue);
        });
        verify(() => mockSecureStorage.getApiKey(testService)).called(1);
      });

      test('should handle short API key for summary', () async {
        // Given
        const shortApiKey = 'sk1';
        when(
          () => mockSecureStorage.getApiKey(testService),
        ).thenAnswer((_) async => const Right(shortApiKey));

        // When
        final result = await repository.getApiKeySummary(testService);

        // Then
        expect(result, isA<Right<DomainFailure, ApiKeySummary>>());
        result.fold((_) => fail('Expected Right but got Left'), (summary) {
          expect(
            summary.prefix,
            equals(shortApiKey),
          ); // Full key when < 4 chars
          expect(summary.length, equals(shortApiKey.length));
        });
        verify(() => mockSecureStorage.getApiKey(testService)).called(1);
      });

      test(
        'should return DomainValidationFailure when service name is empty',
        () async {
          // Given
          const emptyService = '';

          // When
          final result = await repository.getApiKeySummary(emptyService);

          // Then
          expect(result, isA<Left<DomainFailure, ApiKeySummary>>());
          result.fold((failure) {
            expect(failure, isA<DomainValidationFailure>());
            final validationFailure = failure as DomainValidationFailure;
            expect(validationFailure.userMessage, equals('服務名稱不能為空'));
            expect(validationFailure.field, equals('service'));
          }, (_) => fail('Expected Left but got Right'));
          verifyNever(() => mockSecureStorage.getApiKey(any()));
        },
      );
    });

    group('integration scenarios', () {
      const service1 = 'openai';
      const service2 = 'anthropic';
      const apiKey1 = 'sk-123456789012345678901234567890123456789012345678';
      const apiKey2 = 'sk-ant-api03-abcdef1234567890abcdef1234567890abcdef';

      test('should handle complete API key lifecycle', () async {
        // Given
        when(
          () => mockSecureStorage.storeApiKey(service1, apiKey1),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockSecureStorage.storeApiKey(service2, apiKey2),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockSecureStorage.hasApiKey(service1),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => mockSecureStorage.hasApiKey(service2),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => mockSecureStorage.getStoredServices(),
        ).thenAnswer((_) async => const Right([service1, service2]));
        when(
          () => mockSecureStorage.getApiKey(service1),
        ).thenAnswer((_) async => const Right(apiKey1));
        when(
          () => mockSecureStorage.getApiKey(service2),
        ).thenAnswer((_) async => const Right(apiKey2));
        when(
          () => mockSecureStorage.deleteApiKey(service1),
        ).thenAnswer((_) async => const Right(null));

        // When & Then - Store API keys
        final storeResult1 = await repository.storeApiKey(service1, apiKey1);
        final storeResult2 = await repository.storeApiKey(service2, apiKey2);
        expect(storeResult1, const Right(null));
        expect(storeResult2, const Right(null));

        // Check existence
        final hasResult1 = await repository.hasApiKey(service1);
        final hasResult2 = await repository.hasApiKey(service2);
        expect(hasResult1, const Right(true));
        expect(hasResult2, const Right(true));

        // Get services list
        final servicesResult = await repository.getStoredServices();
        expect(servicesResult, const Right([service1, service2]));

        // Retrieve API keys
        final getResult1 = await repository.getApiKey(service1);
        final getResult2 = await repository.getApiKey(service2);
        expect(getResult1, const Right(apiKey1));
        expect(getResult2, const Right(apiKey2));

        // Validate formats
        final validateResult1 = await repository.validateApiKeyFormat(
          service1,
          apiKey1,
        );
        final validateResult2 = await repository.validateApiKeyFormat(
          service2,
          apiKey2,
        );
        expect(validateResult1, const Right(true));
        expect(validateResult2, const Right(true));

        // Delete one key
        final deleteResult = await repository.deleteApiKey(service1);
        expect(deleteResult, const Right(null));

        // Verify operations were called
        verify(
          () => mockSecureStorage.storeApiKey(service1, apiKey1),
        ).called(1);
        verify(
          () => mockSecureStorage.storeApiKey(service2, apiKey2),
        ).called(1);
        verify(() => mockSecureStorage.hasApiKey(service1)).called(1);
        verify(() => mockSecureStorage.hasApiKey(service2)).called(1);
        verify(() => mockSecureStorage.getStoredServices()).called(1);
        verify(() => mockSecureStorage.getApiKey(service1)).called(1);
        verify(() => mockSecureStorage.getApiKey(service2)).called(1);
        verify(() => mockSecureStorage.deleteApiKey(service1)).called(1);
      });
    });
  });
}
