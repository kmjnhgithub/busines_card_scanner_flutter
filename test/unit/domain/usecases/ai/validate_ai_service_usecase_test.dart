import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/ai/validate_ai_service_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mock classes for testing
class MockAIRepository extends Mock implements AIRepository {}

void main() {
  group('ValidateAIServiceUseCase', () {
    late ValidateAIServiceUseCase useCase;
    late MockAIRepository mockRepository;

    setUp(() {
      mockRepository = MockAIRepository();
      useCase = ValidateAIServiceUseCaseImpl(repository: mockRepository);
    });

    group('getServiceStatus', () {
      final testStatus = AIServiceStatus(
        isAvailable: true,
        responseTimeMs: 250.0,
        remainingQuota: 950,
        quotaResetAt: DateTime(2024, 1, 2),
        checkedAt: DateTime(2024, 1, 1),
        error: null,
      );

      test(
        'should return service status when repository call succeeds',
        () async {
          // Given
          when(
            () => mockRepository.getServiceStatus(),
          ).thenAnswer((_) async => testStatus);

          // When
          final result = await useCase.getServiceStatus();

          // Then
          expect(result, Right(testStatus));
          verify(() => mockRepository.getServiceStatus()).called(1);
        },
      );

      test(
        'should return DataSourceFailure when repository throws exception',
        () async {
          // Given
          final exception = Exception('Network connection failed');
          when(() => mockRepository.getServiceStatus()).thenThrow(exception);

          // When
          final result = await useCase.getServiceStatus();

          // Then
          expect(result, isA<Left<DomainFailure, AIServiceStatus>>());
          result.fold((failure) {
            expect(failure, isA<DataSourceFailure>());
            final dataFailure = failure as DataSourceFailure;
            expect(dataFailure.userMessage, equals('取得 AI 服務狀態失敗'));
            expect(
              dataFailure.internalMessage,
              contains('Exception during service status retrieval'),
            );
            expect(dataFailure.internalMessage, contains(exception.toString()));
          }, (_) => fail('Expected Left but got Right'));
          verify(() => mockRepository.getServiceStatus()).called(1);
        },
      );

      test('should handle service unavailable status', () async {
        // Given
        final unavailableStatus = AIServiceStatus(
          isAvailable: false,
          responseTimeMs: 0.0,
          remainingQuota: 0,
          quotaResetAt: DateTime(2024, 1, 2),
          checkedAt: DateTime(2024, 1, 1),
          error: 'Service temporarily unavailable',
        );
        when(
          () => mockRepository.getServiceStatus(),
        ).thenAnswer((_) async => unavailableStatus);

        // When
        final result = await useCase.getServiceStatus();

        // Then
        expect(result, Right(unavailableStatus));
        result.fold((_) => fail('Expected Right but got Left'), (status) {
          expect(status.isAvailable, isFalse);
          expect(status.error, equals('Service temporarily unavailable'));
          expect(status.remainingQuota, equals(0));
        });
        verify(() => mockRepository.getServiceStatus()).called(1);
      });

      test('should handle high response time scenario', () async {
        // Given
        final slowStatus = AIServiceStatus(
          isAvailable: true,
          responseTimeMs: 5000.0, // 5 seconds
          remainingQuota: 100,
          quotaResetAt: DateTime(2024, 1, 2),
          checkedAt: DateTime(2024, 1, 1),
          error: null,
        );
        when(
          () => mockRepository.getServiceStatus(),
        ).thenAnswer((_) async => slowStatus);

        // When
        final result = await useCase.getServiceStatus();

        // Then
        expect(result, Right(slowStatus));
        result.fold((_) => fail('Expected Right but got Left'), (status) {
          expect(status.isAvailable, isTrue);
          expect(status.responseTimeMs, greaterThan(1000.0));
        });
        verify(() => mockRepository.getServiceStatus()).called(1);
      });
    });

    group('getUsageStatistics', () {
      final testStats = AIUsageStatistics(
        totalRequests: 1000,
        successfulRequests: 950,
        averageConfidence: 0.85,
        averageResponseTimeMs: 300.0,
        modelUsage: {'gpt-3.5-turbo': 800, 'gpt-4': 200},
        lastUpdated: DateTime(2024, 1, 1),
      );

      test(
        'should return usage statistics when repository call succeeds',
        () async {
          // Given
          when(
            () => mockRepository.getUsageStatistics(),
          ).thenAnswer((_) async => testStats);

          // When
          final result = await useCase.getUsageStatistics();

          // Then
          expect(result, Right(testStats));
          verify(() => mockRepository.getUsageStatistics()).called(1);
        },
      );

      test(
        'should return DataSourceFailure when repository throws exception',
        () async {
          // Given
          final exception = Exception('Statistics service unavailable');
          when(() => mockRepository.getUsageStatistics()).thenThrow(exception);

          // When
          final result = await useCase.getUsageStatistics();

          // Then
          expect(result, isA<Left<DomainFailure, AIUsageStatistics>>());
          result.fold((failure) {
            expect(failure, isA<DataSourceFailure>());
            final dataFailure = failure as DataSourceFailure;
            expect(dataFailure.userMessage, equals('取得使用統計失敗'));
            expect(
              dataFailure.internalMessage,
              contains('Exception during usage statistics retrieval'),
            );
            expect(dataFailure.internalMessage, contains(exception.toString()));
          }, (_) => fail('Expected Left but got Right'));
          verify(() => mockRepository.getUsageStatistics()).called(1);
        },
      );

      test('should handle zero usage statistics', () async {
        // Given
        final zeroStats = AIUsageStatistics(
          totalRequests: 0,
          successfulRequests: 0,
          averageConfidence: 0.0,
          averageResponseTimeMs: 0.0,
          modelUsage: {},
          lastUpdated: DateTime(2024, 1, 1),
        );
        when(
          () => mockRepository.getUsageStatistics(),
        ).thenAnswer((_) async => zeroStats);

        // When
        final result = await useCase.getUsageStatistics();

        // Then
        expect(result, Right(zeroStats));
        result.fold((_) => fail('Expected Right but got Left'), (stats) {
          expect(stats.totalRequests, equals(0));
          expect(stats.successfulRequests, equals(0));
          expect(stats.averageConfidence, equals(0.0));
          expect(stats.modelUsage, isEmpty);
        });
        verify(() => mockRepository.getUsageStatistics()).called(1);
      });

      test('should handle mixed model usage statistics', () async {
        // Given
        final mixedStats = AIUsageStatistics(
          totalRequests: 1500,
          successfulRequests: 1350,
          averageConfidence: 0.92,
          averageResponseTimeMs: 280.0,
          modelUsage: {'gpt-3.5-turbo': 1000, 'gpt-4': 400, 'claude-3': 100},
          lastUpdated: DateTime(2024, 1, 1),
        );
        when(
          () => mockRepository.getUsageStatistics(),
        ).thenAnswer((_) async => mixedStats);

        // When
        final result = await useCase.getUsageStatistics();

        // Then
        expect(result, Right(mixedStats));
        result.fold((_) => fail('Expected Right but got Left'), (stats) {
          expect(stats.modelUsage.keys, hasLength(3));
          expect(stats.modelUsage['gpt-3.5-turbo'], equals(1000));
          expect(stats.averageConfidence, greaterThan(0.9));

          // Verify success rate
          final successRate = stats.successfulRequests / stats.totalRequests;
          expect(successRate, greaterThan(0.8));
        });
        verify(() => mockRepository.getUsageStatistics()).called(1);
      });
    });

    group('getAvailableModels', () {
      final testModels = [
        AIModelInfo(
          id: 'gpt-3.5-turbo',
          name: 'GPT-3.5 Turbo',
          version: '1.0',
          supportedLanguages: ['zh-TW', 'en', 'ja'],
          isAvailable: true,
          capabilities: {'max_tokens': 4096, 'supports_functions': true},
        ),
        AIModelInfo(
          id: 'gpt-4',
          name: 'GPT-4',
          version: '1.0',
          supportedLanguages: ['zh-TW', 'en', 'ja', 'ko'],
          isAvailable: true,
          capabilities: {'max_tokens': 8192, 'supports_functions': true},
        ),
      ];

      test(
        'should return available models when repository call succeeds',
        () async {
          // Given
          when(
            () => mockRepository.getAvailableModels(),
          ).thenAnswer((_) async => testModels);

          // When
          final result = await useCase.getAvailableModels();

          // Then
          expect(result, Right(testModels));
          verify(() => mockRepository.getAvailableModels()).called(1);
        },
      );

      test(
        'should return DataSourceFailure when repository throws exception',
        () async {
          // Given
          final exception = Exception('Models API unavailable');
          when(() => mockRepository.getAvailableModels()).thenThrow(exception);

          // When
          final result = await useCase.getAvailableModels();

          // Then
          expect(result, isA<Left<DomainFailure, List<AIModelInfo>>>());
          result.fold((failure) {
            expect(failure, isA<DataSourceFailure>());
            final dataFailure = failure as DataSourceFailure;
            expect(dataFailure.userMessage, equals('取得可用模型列表失敗'));
            expect(
              dataFailure.internalMessage,
              contains('Exception during available models retrieval'),
            );
            expect(dataFailure.internalMessage, contains(exception.toString()));
          }, (_) => fail('Expected Left but got Right'));
          verify(() => mockRepository.getAvailableModels()).called(1);
        },
      );

      test('should handle empty models list', () async {
        // Given
        const emptyModels = <AIModelInfo>[];
        when(
          () => mockRepository.getAvailableModels(),
        ).thenAnswer((_) async => emptyModels);

        // When
        final result = await useCase.getAvailableModels();

        // Then
        expect(result, const Right(emptyModels));
        result.fold((_) => fail('Expected Right but got Left'), (models) {
          expect(models, isEmpty);
        });
        verify(() => mockRepository.getAvailableModels()).called(1);
      });

      test('should handle models with mixed availability', () async {
        // Given
        final mixedModels = [
          AIModelInfo(
            id: 'gpt-3.5-turbo',
            name: 'GPT-3.5 Turbo',
            version: '1.0',
            supportedLanguages: ['en', 'zh-TW'],
            isAvailable: true,
          ),
          AIModelInfo(
            id: 'gpt-4-legacy',
            name: 'GPT-4 Legacy',
            version: '0.9',
            supportedLanguages: ['en'],
            isAvailable: false,
          ),
        ];
        when(
          () => mockRepository.getAvailableModels(),
        ).thenAnswer((_) async => mixedModels);

        // When
        final result = await useCase.getAvailableModels();

        // Then
        expect(result, Right(mixedModels));
        result.fold((_) => fail('Expected Right but got Left'), (models) {
          expect(models, hasLength(2));
          expect(models.where((m) => m.isAvailable), hasLength(1));
          expect(models.where((m) => !m.isAvailable), hasLength(1));

          final availableModel = models.firstWhere((m) => m.isAvailable);
          expect(availableModel.supportedLanguages, contains('zh-TW'));
        });
        verify(() => mockRepository.getAvailableModels()).called(1);
      });

      test('should handle models with different language support', () async {
        // Given
        final languageModels = [
          AIModelInfo(
            id: 'multilingual',
            name: 'Multilingual Model',
            version: '2.0',
            supportedLanguages: ['zh-TW', 'zh-CN', 'en', 'ja', 'ko'],
            isAvailable: true,
          ),
          AIModelInfo(
            id: 'english-only',
            name: 'English Only Model',
            version: '1.5',
            supportedLanguages: ['en'],
            isAvailable: true,
          ),
        ];
        when(
          () => mockRepository.getAvailableModels(),
        ).thenAnswer((_) async => languageModels);

        // When
        final result = await useCase.getAvailableModels();

        // Then
        expect(result, Right(languageModels));
        result.fold((_) => fail('Expected Right but got Left'), (models) {
          final multilingualModel = models.firstWhere(
            (m) => m.id == 'multilingual',
          );
          final englishModel = models.firstWhere((m) => m.id == 'english-only');

          expect(multilingualModel.supportedLanguages.length, greaterThan(3));
          expect(englishModel.supportedLanguages, hasLength(1));
        });
        verify(() => mockRepository.getAvailableModels()).called(1);
      });
    });

    group('getCurrentModel', () {
      final testModel = AIModelInfo(
        id: 'gpt-3.5-turbo',
        name: 'GPT-3.5 Turbo',
        version: '1.0',
        supportedLanguages: ['zh-TW', 'en'],
        isAvailable: true,
        capabilities: {'max_tokens': 4096},
      );

      test(
        'should return current model when repository call succeeds',
        () async {
          // Given
          when(
            () => mockRepository.getCurrentModel(),
          ).thenAnswer((_) async => testModel);

          // When
          final result = await useCase.getCurrentModel();

          // Then
          expect(result, Right(testModel));
          verify(() => mockRepository.getCurrentModel()).called(1);
        },
      );

      test(
        'should return DataSourceFailure when repository throws exception',
        () async {
          // Given
          final exception = Exception('Current model API unavailable');
          when(() => mockRepository.getCurrentModel()).thenThrow(exception);

          // When
          final result = await useCase.getCurrentModel();

          // Then
          expect(result, isA<Left<DomainFailure, AIModelInfo>>());
          result.fold((failure) {
            expect(failure, isA<DataSourceFailure>());
            final dataFailure = failure as DataSourceFailure;
            expect(dataFailure.userMessage, equals('取得當前模型失敗'));
            expect(
              dataFailure.internalMessage,
              contains('Exception during current model retrieval'),
            );
            expect(dataFailure.internalMessage, contains(exception.toString()));
          }, (_) => fail('Expected Left but got Right'));
          verify(() => mockRepository.getCurrentModel()).called(1);
        },
      );

      test('should handle unavailable current model', () async {
        // Given
        final unavailableModel = AIModelInfo(
          id: 'deprecated-model',
          name: 'Deprecated Model',
          version: '0.1',
          supportedLanguages: ['en'],
          isAvailable: false,
          capabilities: {'deprecated': true},
        );
        when(
          () => mockRepository.getCurrentModel(),
        ).thenAnswer((_) async => unavailableModel);

        // When
        final result = await useCase.getCurrentModel();

        // Then
        expect(result, Right(unavailableModel));
        result.fold((_) => fail('Expected Right but got Left'), (model) {
          expect(model.isAvailable, isFalse);
          expect(model.capabilities?['deprecated'], isTrue);
          expect(model.version, equals('0.1'));
        });
        verify(() => mockRepository.getCurrentModel()).called(1);
      });

      test('should handle model with limited capabilities', () async {
        // Given
        final limitedModel = AIModelInfo(
          id: 'lite-model',
          name: 'Lite Model',
          version: '1.0',
          supportedLanguages: ['en'],
          isAvailable: true,
          capabilities: {'max_tokens': 1024, 'supports_functions': false},
        );
        when(
          () => mockRepository.getCurrentModel(),
        ).thenAnswer((_) async => limitedModel);

        // When
        final result = await useCase.getCurrentModel();

        // Then
        expect(result, Right(limitedModel));
        result.fold((_) => fail('Expected Right but got Left'), (model) {
          expect(model.capabilities?['max_tokens'], equals(1024));
          expect(model.capabilities?['supports_functions'], isFalse);
          expect(model.supportedLanguages, hasLength(1));
        });
        verify(() => mockRepository.getCurrentModel()).called(1);
      });
    });

    group('integration scenarios', () {
      test('should handle complete AI service validation workflow', () async {
        // Given
        final serviceStatus = AIServiceStatus(
          isAvailable: true,
          responseTimeMs: 200.0,
          remainingQuota: 500,
          quotaResetAt: DateTime(2024, 1, 2),
          checkedAt: DateTime(2024, 1, 1),
          error: null,
        );

        final usageStats = AIUsageStatistics(
          totalRequests: 500,
          successfulRequests: 495,
          averageConfidence: 0.88,
          averageResponseTimeMs: 250.0,
          modelUsage: {'gpt-3.5-turbo': 400, 'gpt-4': 100},
          lastUpdated: DateTime(2024, 1, 1),
        );

        final availableModels = [
          AIModelInfo(
            id: 'gpt-3.5-turbo',
            name: 'GPT-3.5 Turbo',
            version: '1.0',
            supportedLanguages: ['zh-TW', 'en'],
            isAvailable: true,
          ),
        ];

        final currentModel = availableModels.first;

        when(
          () => mockRepository.getServiceStatus(),
        ).thenAnswer((_) async => serviceStatus);
        when(
          () => mockRepository.getUsageStatistics(),
        ).thenAnswer((_) async => usageStats);
        when(
          () => mockRepository.getAvailableModels(),
        ).thenAnswer((_) async => availableModels);
        when(
          () => mockRepository.getCurrentModel(),
        ).thenAnswer((_) async => currentModel);

        // When
        final statusResult = await useCase.getServiceStatus();
        final statsResult = await useCase.getUsageStatistics();
        final modelsResult = await useCase.getAvailableModels();
        final currentResult = await useCase.getCurrentModel();

        // Then
        expect(statusResult, Right(serviceStatus));
        expect(statsResult, Right(usageStats));
        expect(modelsResult, Right(availableModels));
        expect(currentResult, Right(currentModel));

        // Verify all repository methods were called
        verifyInOrder([
          () => mockRepository.getServiceStatus(),
          () => mockRepository.getUsageStatistics(),
          () => mockRepository.getAvailableModels(),
          () => mockRepository.getCurrentModel(),
        ]);
      });

      test('should handle service degradation scenario', () async {
        // Given - Service is degraded but partially functional
        final degradedStatus = AIServiceStatus(
          isAvailable: true,
          responseTimeMs: 2000.0, // Slow response
          remainingQuota: 50, // Low quota
          quotaResetAt: DateTime(2024, 1, 2),
          checkedAt: DateTime(2024, 1, 1),
          error: 'Service experiencing high latency',
        );

        final limitedStats = AIUsageStatistics(
          totalRequests: 100,
          successfulRequests: 60, // High failure rate
          averageConfidence: 0.65, // Lower confidence
          averageResponseTimeMs: 1500.0,
          modelUsage: {'gpt-3.5-turbo': 100},
          lastUpdated: DateTime(2024, 1, 1),
        );

        when(
          () => mockRepository.getServiceStatus(),
        ).thenAnswer((_) async => degradedStatus);
        when(
          () => mockRepository.getUsageStatistics(),
        ).thenAnswer((_) async => limitedStats);

        // When
        final statusResult = await useCase.getServiceStatus();
        final statsResult = await useCase.getUsageStatistics();

        // Then
        expect(statusResult, Right(degradedStatus));
        expect(statsResult, Right(limitedStats));

        statusResult.fold((_) => fail('Expected Right but got Left'), (status) {
          expect(status.isAvailable, isTrue);
          expect(status.responseTimeMs, greaterThan(1000.0));
          expect(status.remainingQuota, lessThan(100));
          expect(status.error, isNotNull);
        });

        statsResult.fold((_) => fail('Expected Right but got Left'), (stats) {
          final successRate = stats.successfulRequests / stats.totalRequests;
          expect(successRate, lessThan(0.7));
          expect(stats.averageConfidence, lessThan(0.7));
        });

        verify(() => mockRepository.getServiceStatus()).called(1);
        verify(() => mockRepository.getUsageStatistics()).called(1);
      });

      test('should handle complete service outage scenario', () async {
        // Given - All services throw exceptions
        final networkException = Exception('Network connectivity lost');

        when(
          () => mockRepository.getServiceStatus(),
        ).thenThrow(networkException);
        when(
          () => mockRepository.getUsageStatistics(),
        ).thenThrow(networkException);
        when(
          () => mockRepository.getAvailableModels(),
        ).thenThrow(networkException);
        when(
          () => mockRepository.getCurrentModel(),
        ).thenThrow(networkException);

        // When
        final statusResult = await useCase.getServiceStatus();
        final statsResult = await useCase.getUsageStatistics();
        final modelsResult = await useCase.getAvailableModels();
        final currentResult = await useCase.getCurrentModel();

        // Then - All should return DataSourceFailure
        expect(statusResult, isA<Left<DomainFailure, AIServiceStatus>>());
        expect(statsResult, isA<Left<DomainFailure, AIUsageStatistics>>());
        expect(modelsResult, isA<Left<DomainFailure, List<AIModelInfo>>>());
        expect(currentResult, isA<Left<DomainFailure, AIModelInfo>>());

        // Verify all methods were attempted
        verify(() => mockRepository.getServiceStatus()).called(1);
        verify(() => mockRepository.getUsageStatistics()).called(1);
        verify(() => mockRepository.getAvailableModels()).called(1);
        verify(() => mockRepository.getCurrentModel()).called(1);
      });
    });
  });
}
