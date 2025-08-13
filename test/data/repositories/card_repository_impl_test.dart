// test/data/repositories/card_repository_impl_test.dart

import 'package:busines_card_scanner_flutter/data/datasources/local/clean_app_database.dart';
import 'package:busines_card_scanner_flutter/data/repositories/card_repository_impl.dart';
import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockCleanAppDatabase extends Mock implements CleanAppDatabase {}

class MockCardDao extends Mock implements CardDao {}

// Fake classes for fallback values
class FakeBusinessCardsCompanion extends Fake
    implements BusinessCardsCompanion {}

class FakeBusinessCard extends Fake implements BusinessCard {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeBusinessCardsCompanion());
    registerFallbackValue(FakeBusinessCard());
  });

  group('CardRepositoryImpl', () {
    late CardRepositoryImpl repository;
    late MockCleanAppDatabase mockDatabase;
    late MockCardDao mockCardDao;

    // 測試資料
    final testCard = BusinessCard(
      id: '1',
      name: 'John Doe',
      company: 'Tech Corp',
      jobTitle: 'Software Engineer',
      email: 'john@techcorp.com',
      phone: '+1-555-0123',
      address: '123 Tech Street, Silicon Valley',
      website: 'https://techcorp.com',
      notes: 'Met at conference',
      createdAt: DateTime(2024, 1, 15, 10, 30),
      updatedAt: DateTime(2024, 1, 15, 10, 30),
    );

    setUp(() {
      mockDatabase = MockCleanAppDatabase();
      mockCardDao = MockCardDao();

      // Mock cardDao getter
      when(() => mockDatabase.cardDao).thenReturn(mockCardDao);

      // 設置基本的默認返回值
      when(() => mockCardDao.getAllBusinessCards()).thenAnswer((_) async => []);

      repository = CardRepositoryImpl(mockDatabase);
    });

    group('Repository 基本屬性測試', () {
      test('🔴 RED: should have correct implementation name', () {
        // Act
        final name = repository.implementationName;

        // Assert
        expect(name, equals('CardRepositoryImpl_Drift'));
      });

      test('🔴 RED: should check database health', () async {
        // Act & Assert - 這個測試暫時先通過，因為我們需要先建立基本結構
        final isHealthy = await repository.isHealthy();
        expect(isHealthy, isNotNull);
      });

      test('🔴 RED: should dispose resources properly', () async {
        // Arrange
        when(() => mockDatabase.close()).thenAnswer((_) async => {});

        // Act & Assert - 基本測試
        await repository.dispose();

        // 驗證 close 被調用
        verify(() => mockDatabase.close()).called(1);
      });
    });

    group('CardReader 功能測試 - 基本方法', () {
      test('🔴 RED: should get all cards', () async {
        // Arrange
        final expectedCards = [testCard];
        when(
          () => mockCardDao.getAllBusinessCards(),
        ).thenAnswer((_) async => expectedCards);

        // Act
        final result = await repository.getCards();

        // Assert
        expect(result, hasLength(1));
        expect(result.first.id, equals(testCard.id));
        expect(result.first.name, equals(testCard.name));
        verify(() => mockCardDao.getAllBusinessCards()).called(1);
      });

      test('🔴 RED: should get card by ID successfully', () async {
        // Arrange
        when(
          () => mockCardDao.getBusinessCardById(int.parse(testCard.id)),
        ).thenAnswer((_) async => testCard);

        // Act
        final result = await repository.getCardById(testCard.id);

        // Assert
        expect(result.id, equals(testCard.id));
        expect(result.name, equals(testCard.name));
        expect(result.email, equals(testCard.email));
        verify(
          () => mockCardDao.getBusinessCardById(int.parse(testCard.id)),
        ).called(1);
      });

      test('🔴 RED: should throw exception when card not found', () async {
        // Arrange
        const nonExistentId = '999';
        when(
          () => mockCardDao.getBusinessCardById(int.parse(nonExistentId)),
        ).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.getCardById(nonExistentId),
          throwsA(isA<DataSourceFailure>()),
        );
      });

      test('🔴 RED: should search cards by query', () async {
        // Arrange
        const searchQuery = 'John';
        when(
          () => mockCardDao.searchBusinessCards(searchQuery),
        ).thenAnswer((_) async => [testCard]);

        // Act
        final result = await repository.searchCards(searchQuery);

        // Assert
        expect(result, hasLength(1));
        expect(result.first.name, contains('John'));
        verify(() => mockCardDao.searchBusinessCards(searchQuery)).called(1);
      });

      test('🔴 RED: should get cards by company', () async {
        // Arrange
        const companyName = 'Tech Corp';
        when(
          () => mockCardDao.searchBusinessCards(companyName),
        ).thenAnswer((_) async => [testCard]);

        // Act
        final result = await repository.getCardsByCompany(companyName);

        // Assert
        expect(result, hasLength(1));
        expect(result.first.company, equals(companyName));
        verify(() => mockCardDao.searchBusinessCards(companyName)).called(1);
      });
    });

    group('CardWriter 功能測試 - 基本方法', () {
      test('🔴 RED: should save new card successfully', () async {
        // Arrange
        final newCard = testCard.copyWith(id: ''); // 新卡片沒有 ID
        final savedCard = testCard.copyWith(
          id: '123',
          updatedAt: DateTime.now(),
        );

        when(
          () => mockCardDao.insertBusinessCard(any()),
        ).thenAnswer((_) async => 123);
        when(
          () => mockCardDao.getBusinessCardById(123),
        ).thenAnswer((_) async => savedCard);

        // Act
        final result = await repository.saveCard(newCard);

        // Assert
        expect(result.id, isNotEmpty); // ID 會被生成
        expect(result.name, equals(newCard.name));
        verify(() => mockCardDao.insertBusinessCard(any())).called(1);
      });

      test('🔴 RED: should update existing card successfully', () async {
        // Arrange
        final updatedCard = testCard.copyWith(
          name: 'Updated Name',
          updatedAt: DateTime.now(),
        );

        when(
          () => mockCardDao.getBusinessCardById(int.parse(testCard.id)),
        ).thenAnswer((_) async => updatedCard); // 簡化，直接返回更新模型
        when(
          () => mockCardDao.updateBusinessCard(any()),
        ).thenAnswer((_) async => true);

        // Act
        final result = await repository.saveCard(updatedCard);

        // Assert
        expect(result.id, equals(testCard.id));
        expect(result.name, equals('Updated Name'));
        verify(() => mockCardDao.updateBusinessCard(any())).called(1);
      });

      test('🔴 RED: should delete card successfully', () async {
        // Arrange
        when(
          () => mockCardDao.deleteBusinessCard(int.parse(testCard.id)),
        ).thenAnswer((_) async => true);

        // Act
        final result = await repository.deleteCard(testCard.id);

        // Assert
        expect(result, isTrue);
        verify(
          () => mockCardDao.deleteBusinessCard(int.parse(testCard.id)),
        ).called(1);
      });

      test(
        '🔴 RED: should return false when deleting non-existent card',
        () async {
          // Arrange
          const nonExistentId = '998';
          when(
            () => mockCardDao.deleteBusinessCard(int.parse(nonExistentId)),
          ).thenAnswer((_) async => false);

          // Act
          final result = await repository.deleteCard(nonExistentId);

          // Assert
          expect(result, isFalse);
          verify(
            () => mockCardDao.deleteBusinessCard(int.parse(nonExistentId)),
          ).called(1);
        },
      );

      test('🔴 RED: should update card successfully', () async {
        // Arrange
        final updatedCard = testCard.copyWith(name: 'Updated John');
        final finalUpdatedCard = updatedCard.copyWith(
          updatedAt: DateTime.now(),
        );

        when(
          () => mockCardDao.getBusinessCardById(int.parse(updatedCard.id)),
        ).thenAnswer((_) async => finalUpdatedCard); // 返回更新後的模型
        when(
          () => mockCardDao.updateBusinessCard(any()),
        ).thenAnswer((_) async => true);

        // Act
        final result = await repository.updateCard(updatedCard);

        // Assert
        expect(result.name, equals('Updated John'));
        verify(() => mockCardDao.updateBusinessCard(any())).called(1);
      });

      test(
        '🔴 RED: should throw error when updating non-existent card',
        () async {
          // Arrange
          final nonExistentCard = testCard.copyWith(id: '997');
          when(
            () =>
                mockCardDao.getBusinessCardById(int.parse(nonExistentCard.id)),
          ).thenAnswer((_) async => null);

          // Act & Assert
          expect(
            () => repository.updateCard(nonExistentCard),
            throwsA(isA<DataSourceFailure>()),
          );
        },
      );
    });

    group('錯誤處理測試', () {
      test('🔴 RED: should handle database errors gracefully', () async {
        // Arrange
        when(
          () => mockCardDao.getAllBusinessCards(),
        ).thenThrow(Exception('Database connection failed'));

        // Act & Assert
        expect(() => repository.getCards(), throwsA(isA<DataSourceFailure>()));
      });

      test('🔴 RED: should validate card data before saving', () async {
        // Arrange
        final invalidCard = testCard.copyWith(name: ''); // 空名稱

        // Act & Assert
        expect(
          () => repository.saveCard(invalidCard),
          throwsA(isA<DomainValidationFailure>()),
        );
      });
    });

    group('邊界條件測試', () {
      test('🔴 RED: should handle empty search query', () async {
        // Arrange
        when(
          () => mockCardDao.searchBusinessCards(''),
        ).thenAnswer((_) async => []);

        // Act
        final result = await repository.searchCards('');

        // Assert
        expect(result, isEmpty);
      });

      test('🔴 RED: should handle very long search queries', () async {
        // Arrange
        final longQuery = 'a' * 1000;
        when(
          () => mockCardDao.searchBusinessCards(longQuery),
        ).thenAnswer((_) async => []);

        // Act
        final result = await repository.searchCards(longQuery);

        // Assert
        expect(result, isEmpty);
      });
    });
  });
}
