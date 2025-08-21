import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/api_key_repository.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/ai/manage_api_key_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mock classes for testing
class MockApiKeyRepository extends Mock implements ApiKeyRepository {}

void main() {
  group('ManageApiKeyUseCase', () {
    late ManageApiKeyUseCase useCase;
    late MockApiKeyRepository mockRepository;

    setUp(() {
      mockRepository = MockApiKeyRepository();
      useCase = ManageApiKeyUseCaseImpl(repository: mockRepository);
    });

    group('storeApiKey', () {
      const testService = 'openai';
      const validApiKey = 'sk-123456789012345678901234567890123456789012345678';
      const invalidApiKey = 'invalid-key';

      test('should store API key when format is valid', () async {
        // Given
        when(
          () => mockRepository.validateApiKeyFormat(testService, validApiKey),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => mockRepository.storeApiKey(testService, validApiKey),
        ).thenAnswer((_) async => const Right(null));

        // When
        final result = await useCase.storeApiKey(testService, validApiKey);

        // Then
        expect(result, const Right(null));
        verify(
          () => mockRepository.validateApiKeyFormat(testService, validApiKey),
        ).called(1);
        verify(
          () => mockRepository.storeApiKey(testService, validApiKey),
        ).called(1);
      });

      test(
        'should return ValidationFailure when API key format is invalid',
        () async {
          // Given
          when(
            () =>
                mockRepository.validateApiKeyFormat(testService, invalidApiKey),
          ).thenAnswer((_) async => const Right(false));

          // When
          final result = await useCase.storeApiKey(testService, invalidApiKey);

          // Then
          expect(result, isA<Left<DomainFailure, void>>());
          result.fold((failure) {
            expect(failure, isA<DomainValidationFailure>());
            final validationFailure = failure as DomainValidationFailure;
            expect(validationFailure.userMessage, equals('無效的 API Key 格式'));
            expect(validationFailure.field, equals('apiKey'));
          }, (_) => fail('Expected Left but got Right'));

          verify(
            () =>
                mockRepository.validateApiKeyFormat(testService, invalidApiKey),
          ).called(1);
          verifyNever(() => mockRepository.storeApiKey(any(), any()));
        },
      );

      test('should return failure when format validation fails', () async {
        // Given
        const failure = DataSourceFailure(
          userMessage: 'Validation service unavailable',
          internalMessage: 'Network error',
        );
        when(
          () => mockRepository.validateApiKeyFormat(testService, validApiKey),
        ).thenAnswer((_) async => Left(failure));

        // When
        final result = await useCase.storeApiKey(testService, validApiKey);

        // Then
        expect(result, Left(failure));
        verify(
          () => mockRepository.validateApiKeyFormat(testService, validApiKey),
        ).called(1);
        verifyNever(() => mockRepository.storeApiKey(any(), any()));
      });

      test('should return failure when storage fails', () async {
        // Given
        const storageFailure = DataSourceFailure(
          userMessage: 'Storage failed',
          internalMessage: 'Disk full',
        );
        when(
          () => mockRepository.validateApiKeyFormat(testService, validApiKey),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => mockRepository.storeApiKey(testService, validApiKey),
        ).thenAnswer((_) async => Left(storageFailure));

        // When
        final result = await useCase.storeApiKey(testService, validApiKey);

        // Then
        expect(result, Left(storageFailure));
        verify(
          () => mockRepository.validateApiKeyFormat(testService, validApiKey),
        ).called(1);
        verify(
          () => mockRepository.storeApiKey(testService, validApiKey),
        ).called(1);
      });
    });

    group('getApiKey', () {
      const testService = 'openai';
      const testApiKey = 'sk-123456789012345678901234567890123456789012345678';

      test('should return API key when service exists', () async {
        // Given
        when(
          () => mockRepository.getApiKey(testService),
        ).thenAnswer((_) async => const Right(testApiKey));

        // When
        final result = await useCase.getApiKey(testService);

        // Then
        expect(result, const Right(testApiKey));
        verify(() => mockRepository.getApiKey(testService)).called(1);
      });

      test('should return failure when API key does not exist', () async {
        // Given
        const failure = DataSourceFailure(
          userMessage: 'API key not found',
          internalMessage: 'No key stored for service',
        );
        when(
          () => mockRepository.getApiKey(testService),
        ).thenAnswer((_) async => Left(failure));

        // When
        final result = await useCase.getApiKey(testService);

        // Then
        expect(result, Left(failure));
        verify(() => mockRepository.getApiKey(testService)).called(1);
      });
    });

    group('deleteApiKey', () {
      const testService = 'openai';

      test('should delete API key successfully', () async {
        // Given
        when(
          () => mockRepository.deleteApiKey(testService),
        ).thenAnswer((_) async => const Right(null));

        // When
        final result = await useCase.deleteApiKey(testService);

        // Then
        expect(result, const Right(null));
        verify(() => mockRepository.deleteApiKey(testService)).called(1);
      });

      test('should return failure when deletion fails', () async {
        // Given
        const failure = DataSourceFailure(
          userMessage: 'Failed to delete API key',
          internalMessage: 'Storage operation failed',
        );
        when(
          () => mockRepository.deleteApiKey(testService),
        ).thenAnswer((_) async => Left(failure));

        // When
        final result = await useCase.deleteApiKey(testService);

        // Then
        expect(result, Left(failure));
        verify(() => mockRepository.deleteApiKey(testService)).called(1);
      });
    });

    group('hasApiKey', () {
      const testService = 'openai';

      test('should return true when API key exists', () async {
        // Given
        when(
          () => mockRepository.hasApiKey(testService),
        ).thenAnswer((_) async => const Right(true));

        // When
        final result = await useCase.hasApiKey(testService);

        // Then
        expect(result, const Right(true));
        verify(() => mockRepository.hasApiKey(testService)).called(1);
      });

      test('should return false when API key does not exist', () async {
        // Given
        when(
          () => mockRepository.hasApiKey(testService),
        ).thenAnswer((_) async => const Right(false));

        // When
        final result = await useCase.hasApiKey(testService);

        // Then
        expect(result, const Right(false));
        verify(() => mockRepository.hasApiKey(testService)).called(1);
      });
    });

    group('validateApiKeyFormat', () {
      const testService = 'openai';
      const validKey = 'sk-123456789012345678901234567890123456789012345678';
      const invalidKey = 'invalid-format';

      test('should return true for valid API key format', () async {
        // Given
        when(
          () => mockRepository.validateApiKeyFormat(testService, validKey),
        ).thenAnswer((_) async => const Right(true));

        // When
        final result = await useCase.validateApiKeyFormat(
          testService,
          validKey,
        );

        // Then
        expect(result, const Right(true));
        verify(
          () => mockRepository.validateApiKeyFormat(testService, validKey),
        ).called(1);
      });

      test('should return false for invalid API key format', () async {
        // Given
        when(
          () => mockRepository.validateApiKeyFormat(testService, invalidKey),
        ).thenAnswer((_) async => const Right(false));

        // When
        final result = await useCase.validateApiKeyFormat(
          testService,
          invalidKey,
        );

        // Then
        expect(result, const Right(false));
        verify(
          () => mockRepository.validateApiKeyFormat(testService, invalidKey),
        ).called(1);
      });
    });

    group('getApiKeySummary', () {
      const testService = 'openai';
      final testSummary = ApiKeySummary(
        service: testService,
        prefix: 'sk-1',
        length: 51,
        storedAt: DateTime(2024, 1, 1),
        isValidFormat: true,
      );

      test('should return API key summary when service exists', () async {
        // Given
        when(
          () => mockRepository.getApiKeySummary(testService),
        ).thenAnswer((_) async => Right(testSummary));

        // When
        final result = await useCase.getApiKeySummary(testService);

        // Then
        expect(result, Right(testSummary));
        verify(() => mockRepository.getApiKeySummary(testService)).called(1);
      });

      test('should return failure when summary generation fails', () async {
        // Given
        const failure = DataSourceFailure(
          userMessage: 'Failed to generate API key summary',
          internalMessage: 'Summary generation error',
        );
        when(
          () => mockRepository.getApiKeySummary(testService),
        ).thenAnswer((_) async => Left(failure));

        // When
        final result = await useCase.getApiKeySummary(testService);

        // Then
        expect(result, Left(failure));
        verify(() => mockRepository.getApiKeySummary(testService)).called(1);
      });
    });

    group('edge cases', () {
      test('should handle multiple consecutive operations', () async {
        // Given
        const service = 'openai';
        const apiKey = 'sk-123456789012345678901234567890123456789012345678';

        when(
          () => mockRepository.validateApiKeyFormat(service, apiKey),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => mockRepository.storeApiKey(service, apiKey),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockRepository.hasApiKey(service),
        ).thenAnswer((_) async => const Right(true));
        when(
          () => mockRepository.getApiKey(service),
        ).thenAnswer((_) async => Right(apiKey));
        when(
          () => mockRepository.deleteApiKey(service),
        ).thenAnswer((_) async => const Right(null));

        // When & Then
        final storeResult = await useCase.storeApiKey(service, apiKey);
        expect(storeResult, const Right(null));

        final hasResult = await useCase.hasApiKey(service);
        expect(hasResult, const Right(true));

        final getResult = await useCase.getApiKey(service);
        expect(getResult, Right(apiKey));

        final deleteResult = await useCase.deleteApiKey(service);
        expect(deleteResult, const Right(null));

        // Verify call order and count
        verifyInOrder([
          () => mockRepository.validateApiKeyFormat(service, apiKey),
          () => mockRepository.storeApiKey(service, apiKey),
          () => mockRepository.hasApiKey(service),
          () => mockRepository.getApiKey(service),
          () => mockRepository.deleteApiKey(service),
        ]);
      });
    });
  });
}
