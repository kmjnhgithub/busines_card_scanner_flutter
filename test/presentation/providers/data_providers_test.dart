import 'package:busines_card_scanner_flutter/data/datasources/local/clean_app_database.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/secure/enhanced_secure_storage.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/openai_service.dart';
import 'package:busines_card_scanner_flutter/data/repositories/card_repository_impl.dart';
import 'package:busines_card_scanner_flutter/data/repositories/ocr_repository_impl.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockCleanAppDatabase extends Mock implements CleanAppDatabase {}
class MockEnhancedSecureStorage extends Mock implements EnhancedSecureStorage {}
class MockOpenAIService extends Mock implements OpenAIService {}
void main() {
  group('Data Providers', () {
    late ProviderContainer container;
    late MockCleanAppDatabase mockDatabase;
    late MockEnhancedSecureStorage mockSecureStorage;
    late MockOpenAIService mockOpenAIService;

    setUp(() {
      mockDatabase = MockCleanAppDatabase();
      mockSecureStorage = MockEnhancedSecureStorage();
      mockOpenAIService = MockOpenAIService();

      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(mockDatabase),
          enhancedSecureStorageProvider.overrideWithValue(mockSecureStorage),
          openAIServiceProvider.overrideWithValue(mockOpenAIService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Database Provider', () {
      test('should provide CleanAppDatabase instance', () {
        // Act
        final database = container.read(appDatabaseProvider);

        // Assert
        expect(database, isA<CleanAppDatabase>());
        expect(database, same(mockDatabase));
      });

      test('should be a singleton', () {
        // Act
        final database1 = container.read(appDatabaseProvider);
        final database2 = container.read(appDatabaseProvider);

        // Assert
        expect(database1, same(database2));
      });
    });

    group('Secure Storage Provider', () {
      test('should provide EnhancedSecureStorage instance', () {
        // Act
        final storage = container.read(enhancedSecureStorageProvider);

        // Assert
        expect(storage, isA<EnhancedSecureStorage>());
        expect(storage, same(mockSecureStorage));
      });

      test('should be a singleton', () {
        // Act
        final storage1 = container.read(enhancedSecureStorageProvider);
        final storage2 = container.read(enhancedSecureStorageProvider);

        // Assert
        expect(storage1, same(storage2));
      });
    });

    group('OpenAI Service Provider', () {
      test('should provide OpenAIService instance', () {
        // Act
        final service = container.read(openAIServiceProvider);

        // Assert
        expect(service, isA<OpenAIService>());
        expect(service, same(mockOpenAIService));
      });
    });

    group('Repository Providers', () {
      test('cardRepositoryProvider should create CardRepositoryImpl with correct dependencies', () {
        // Act
        final repository = container.read(cardRepositoryProvider);

        // Assert
        expect(repository, isA<CardRepositoryImpl>());
      });

      test('ocrRepositoryProvider should create OCRRepositoryImpl with correct dependencies', () {
        // Act
        final repository = container.read(ocrRepositoryProvider);

        // Assert
        expect(repository, isA<OCRRepositoryImpl>());
      });

      test('repository providers should be singletons', () {
        // Act
        final cardRepo1 = container.read(cardRepositoryProvider);
        final cardRepo2 = container.read(cardRepositoryProvider);
        final ocrRepo1 = container.read(ocrRepositoryProvider);
        final ocrRepo2 = container.read(ocrRepositoryProvider);

        // Assert
        expect(cardRepo1, same(cardRepo2));
        expect(ocrRepo1, same(ocrRepo2));
      });
    });

    group('Provider Dependency Chain', () {
      test('should create correct dependency chain for card repository', () {
        // Act
        final repository = container.read(cardRepositoryProvider);

        // Assert - 驗證 repository 有正確的依賴
        expect(repository, isA<CardRepositoryImpl>());
        
        // 透過執行基本操作驗證依賴注入正確
        expect(repository.toString, returnsNormally);
      });

      test('should handle provider disposal correctly', () {
        // Act
        final database = container.read(appDatabaseProvider);
        final storage = container.read(enhancedSecureStorageProvider);
        
        // Assert - 驗證 dispose 不會拋出異常
        expect(() => container.dispose(), returnsNormally);
      });
    });

    group('Provider Override', () {
      test('should allow provider overrides for testing', () {
        // Arrange
        final customDatabase = MockCleanAppDatabase();
        final customContainer = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(customDatabase),
          ],
        );

        // Act
        final database = customContainer.read(appDatabaseProvider);

        // Assert
        expect(database, same(customDatabase));
        expect(database, isNot(same(mockDatabase)));

        customContainer.dispose();
      });
    });
  });
}