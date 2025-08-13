import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_reader.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/get_cards_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock Repository 用於測試
class MockCardReader implements CardReader {
  List<BusinessCard>? _mockCards;
  CardPageResult? _mockPageResult;
  DomainFailure? _mockFailure;

  void setMockCards(List<BusinessCard> cards) => _mockCards = cards;
  void setMockPageResult(CardPageResult result) => _mockPageResult = result;
  void setMockFailure(DomainFailure failure) => _mockFailure = failure;

  @override
  Future<List<BusinessCard>> getCards({int limit = 50}) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    final cards = _mockCards ?? [];
    return cards.take(limit).toList();
  }

  @override
  Future<CardPageResult> getCardsPage({int page = 1, int pageSize = 20}) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return _mockPageResult ??
        CardPageResult(
          cards: _mockCards ?? [],
          totalCount: _mockCards?.length ?? 0,
          currentOffset: (page - 1) * pageSize,
          limit: pageSize,
          hasMore: false,
          currentPage: page,
        );
  }

  @override
  Future<CardPageResult> getCardsWithPagination({
    int offset = 0,
    int limit = 20,
    CardSortField sortBy = CardSortField.createdAt,
    SortOrder sortOrder = SortOrder.descending,
  }) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return _mockPageResult ??
        CardPageResult(
          cards: _mockCards ?? [],
          totalCount: _mockCards?.length ?? 0,
          currentOffset: offset,
          limit: limit,
          hasMore: false,
        );
  }

  @override
  Future<BusinessCard> getCardById(String cardId) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    final cards = _mockCards ?? [];
    // 使用更安全的方式避免 StateError
    final foundCard = cards.cast<BusinessCard?>().firstWhere(
      (card) => card?.id == cardId,
      orElse: () => null,
    );
    if (foundCard == null) {
      throw CardNotFoundException(cardId);
    }
    return foundCard;
  }

  @override
  Future<List<BusinessCard>> searchCards(String query, {int limit = 50}) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    final cards = _mockCards ?? [];
    return cards
        .where(
          (card) =>
              card.name.toLowerCase().contains(query.toLowerCase()) ||
              (card.company?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        )
        .take(limit)
        .toList();
  }

  @override
  Future<int> getCardCount() async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    return _mockCards?.length ?? 0;
  }

  @override
  Future<List<BusinessCard>> getRecentCards({int limit = 10}) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    final cards = _mockCards ?? [];
    final sorted = List<BusinessCard>.from(cards)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<List<BusinessCard>> getCardsByCompany(
    String company, {
    int limit = 50,
  }) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    final cards = _mockCards ?? [];
    return cards
        .where((card) => card.company?.toLowerCase() == company.toLowerCase())
        .take(limit)
        .toList();
  }

  @override
  Future<bool> cardExists(String cardId) async {
    if (_mockFailure != null) {
      throw _mockFailure!;
    }
    final cards = _mockCards ?? [];
    return cards.any((card) => card.id == cardId);
  }
}

void main() {
  group('GetCardsUseCase Tests', () {
    late GetCardsUseCase useCase;
    late MockCardReader mockCardReader;
    late DateTime testDateTime;

    setUp(() {
      mockCardReader = MockCardReader();
      useCase = GetCardsUseCase(mockCardReader);
      testDateTime = DateTime.now();
    });

    group('執行基本取得名片功能', () {
      test(
        'should return list of cards when repository returns cards',
        () async {
          // Arrange
          final mockCards = [
            BusinessCard(
              id: 'card-1',
              name: 'John Doe',
              company: 'Tech Corp',
              email: 'john@techcorp.com',
              createdAt: testDateTime,
            ),
            BusinessCard(
              id: 'card-2',
              name: 'Jane Smith',
              company: 'Design Studio',
              email: 'jane@design.com',
              createdAt: testDateTime.subtract(const Duration(days: 1)),
            ),
          ];
          mockCardReader.setMockCards(mockCards);

          // Act
          final result = await useCase.execute(const GetCardsParams());

          // Assert
          expect(result.length, 2);
          expect(result[0].id, 'card-1');
          expect(result[1].id, 'card-2');
        },
      );

      test('should return empty list when no cards exist', () async {
        // Arrange
        mockCardReader.setMockCards([]);

        // Act
        final result = await useCase.execute(const GetCardsParams());

        // Assert
        expect(result, isEmpty);
      });

      test('should respect limit parameter', () async {
        // Arrange
        final mockCards = List.generate(
          15,
          (index) => BusinessCard(
            id: 'card-$index',
            name: 'Person $index',
            createdAt: testDateTime.subtract(Duration(days: index)),
          ),
        );
        mockCardReader.setMockCards(mockCards);

        // Act
        final result = await useCase.execute(const GetCardsParams(limit: 10));

        // Assert
        expect(result.length, 10);
      });

      test('should use default limit when not specified', () async {
        // Arrange
        final mockCards = List.generate(
          60,
          (index) => BusinessCard(
            id: 'card-$index',
            name: 'Person $index',
            createdAt: testDateTime,
          ),
        );
        mockCardReader.setMockCards(mockCards);

        // Act
        final result = await useCase.execute(const GetCardsParams());

        // Assert
        expect(result.length, 50); // 預設限制
      });
    });

    group('執行分頁查詢功能', () {
      test('should return paginated result when using pagination', () async {
        // Arrange
        final mockCards = List.generate(
          25,
          (index) => BusinessCard(
            id: 'card-$index',
            name: 'Person $index',
            createdAt: testDateTime,
          ),
        );
        final mockPageResult = CardPageResult(
          cards: mockCards.take(10).toList(),
          totalCount: 25,
          currentOffset: 0,
          limit: 10,
          hasMore: true,
          totalPages: 3,
          hasNext: true,
        );
        mockCardReader.setMockPageResult(mockPageResult);

        // Act
        final result = await useCase.executeWithPagination(
          const GetCardsPaginationParams(page: 1, pageSize: 10),
        );

        // Assert
        expect(result.cards.length, 10);
        expect(result.currentPage, 1);
        expect(result.totalPages, 3);
        expect(result.totalCount, 25);
        expect(result.hasNext, true);
        expect(result.hasPrevious, false);
      });

      test('should handle last page correctly', () async {
        // Arrange
        final mockCards = List.generate(
          5,
          (index) => BusinessCard(
            id: 'card-$index',
            name: 'Person $index',
            createdAt: testDateTime,
          ),
        );
        final mockPageResult = CardPageResult(
          cards: mockCards,
          totalCount: 25,
          currentOffset: 20,
          limit: 10,
          hasMore: false,
          currentPage: 3,
          totalPages: 3,
          hasPrevious: true,
        );
        mockCardReader.setMockPageResult(mockPageResult);

        // Act
        final result = await useCase.executeWithPagination(
          const GetCardsPaginationParams(page: 3, pageSize: 10),
        );

        // Assert
        expect(result.cards.length, 5);
        expect(result.hasNext, false);
        expect(result.hasPrevious, true);
      });
    });

    group('執行搜尋功能', () {
      test('should return filtered cards when searching by name', () async {
        // Arrange
        final mockCards = [
          BusinessCard(
            id: 'card-1',
            name: 'John Doe',
            company: 'Tech Corp',
            createdAt: testDateTime,
          ),
          BusinessCard(
            id: 'card-2',
            name: 'Jane Smith',
            company: 'Design Studio',
            createdAt: testDateTime,
          ),
          BusinessCard(
            id: 'card-3',
            name: 'Johnny Cash',
            company: 'Music Inc',
            createdAt: testDateTime,
          ),
        ];
        mockCardReader.setMockCards(mockCards);

        // Act
        final result = await useCase.searchCards(
          const SearchCardsParams(query: 'john'),
        );

        // Assert
        expect(result.length, 2);
        expect(result[0].name, 'John Doe');
        expect(result[1].name, 'Johnny Cash');
      });

      test('should return filtered cards when searching by company', () async {
        // Arrange
        final mockCards = [
          BusinessCard(
            id: 'card-1',
            name: 'John Doe',
            company: 'Tech Corp',
            createdAt: testDateTime,
          ),
          BusinessCard(
            id: 'card-2',
            name: 'Jane Smith',
            company: 'Tech Corp',
            createdAt: testDateTime,
          ),
          BusinessCard(
            id: 'card-3',
            name: 'Bob Wilson',
            company: 'Design Studio',
            createdAt: testDateTime,
          ),
        ];
        mockCardReader.setMockCards(mockCards);

        // Act
        final result = await useCase.searchCards(
          const SearchCardsParams(query: 'tech corp'),
        );

        // Assert
        expect(result.length, 2);
        expect(result.every((card) => card.company == 'Tech Corp'), true);
      });

      test('should return empty list when no matches found', () async {
        // Arrange
        final mockCards = [
          BusinessCard(
            id: 'card-1',
            name: 'John Doe',
            company: 'Tech Corp',
            createdAt: testDateTime,
          ),
        ];
        mockCardReader.setMockCards(mockCards);

        // Act
        final result = await useCase.searchCards(
          const SearchCardsParams(query: 'nonexistent'),
        );

        // Assert
        expect(result, isEmpty);
      });

      test('should respect search limit parameter', () async {
        // Arrange
        final mockCards = List.generate(
          15,
          (index) => BusinessCard(
            id: 'card-$index',
            name: 'John $index',
            createdAt: testDateTime,
          ),
        );
        mockCardReader.setMockCards(mockCards);

        // Act
        final result = await useCase.searchCards(
          const SearchCardsParams(query: 'john', limit: 5),
        );

        // Assert
        expect(result.length, 5);
      });
    });

    group('取得特定名片功能', () {
      test('should return card when found by ID', () async {
        // Arrange
        final mockCards = [
          BusinessCard(
            id: 'card-123',
            name: 'John Doe',
            createdAt: testDateTime,
          ),
        ];
        mockCardReader.setMockCards(mockCards);

        // Act
        final result = await useCase.getCardById('card-123');

        // Assert
        expect(result.id, 'card-123');
        expect(result.name, 'John Doe');
      });

      test('should throw CardNotFoundException when card not found', () async {
        // Arrange
        mockCardReader.setMockCards([]);

        // Act & Assert
        expect(
          () => useCase.getCardById('nonexistent-id'),
          throwsA(isA<CardNotFoundException>()),
        );
      });
    });

    group('取得最近名片功能', () {
      test('should return recent cards ordered by creation date', () async {
        // Arrange
        final now = DateTime.now();
        final mockCards = [
          BusinessCard(
            id: 'card-1',
            name: 'Oldest',
            createdAt: now.subtract(const Duration(days: 3)),
          ),
          BusinessCard(id: 'card-2', name: 'Newest', createdAt: now),
          BusinessCard(
            id: 'card-3',
            name: 'Middle',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        ];
        mockCardReader.setMockCards(mockCards);

        // Act
        final result = await useCase.getRecentCards(10);

        // Assert
        expect(result.length, 3);
        expect(result[0].name, 'Newest');
        expect(result[1].name, 'Middle');
        expect(result[2].name, 'Oldest');
      });

      test('should respect limit for recent cards', () async {
        // Arrange
        final mockCards = List.generate(
          15,
          (index) => BusinessCard(
            id: 'card-$index',
            name: 'Person $index',
            createdAt: testDateTime.subtract(Duration(hours: index)),
          ),
        );
        mockCardReader.setMockCards(mockCards);

        // Act
        final result = await useCase.getRecentCards(5);

        // Assert
        expect(result.length, 5);
      });
    });

    group('統計資訊功能', () {
      test('should return correct card count', () async {
        // Arrange
        final mockCards = List.generate(
          42,
          (index) => BusinessCard(
            id: 'card-$index',
            name: 'Person $index',
            createdAt: testDateTime,
          ),
        );
        mockCardReader.setMockCards(mockCards);

        // Act
        final count = await useCase.getCardCount();

        // Assert
        expect(count, 42);
      });

      test('should return zero for empty card collection', () async {
        // Arrange
        mockCardReader.setMockCards([]);

        // Act
        final count = await useCase.getCardCount();

        // Assert
        expect(count, 0);
      });

      test('should check if card exists', () async {
        // Arrange
        final mockCards = [
          BusinessCard(
            id: 'existing-card',
            name: 'John Doe',
            createdAt: testDateTime,
          ),
        ];
        mockCardReader.setMockCards(mockCards);

        // Act
        final exists = await useCase.cardExists('existing-card');
        final notExists = await useCase.cardExists('nonexistent-card');

        // Assert
        expect(exists, true);
        expect(notExists, false);
      });
    });

    group('公司分組功能', () {
      test('should return cards from specific company', () async {
        // Arrange
        final mockCards = [
          BusinessCard(
            id: 'card-1',
            name: 'John Doe',
            company: 'Tech Corp',
            createdAt: testDateTime,
          ),
          BusinessCard(
            id: 'card-2',
            name: 'Jane Smith',
            company: 'Tech Corp',
            createdAt: testDateTime,
          ),
          BusinessCard(
            id: 'card-3',
            name: 'Bob Wilson',
            company: 'Design Inc',
            createdAt: testDateTime,
          ),
        ];
        mockCardReader.setMockCards(mockCards);

        // Act
        final result = await useCase.getCardsByCompany('Tech Corp');

        // Assert
        expect(result.length, 2);
        expect(result.every((card) => card.company == 'Tech Corp'), true);
      });

      test('should handle case insensitive company search', () async {
        // Arrange
        final mockCards = [
          BusinessCard(
            id: 'card-1',
            name: 'John Doe',
            company: 'Tech Corp',
            createdAt: testDateTime,
          ),
        ];
        mockCardReader.setMockCards(mockCards);

        // Act
        final result = await useCase.getCardsByCompany('TECH CORP');

        // Assert
        expect(result.length, 1);
        expect(result[0].company, 'Tech Corp');
      });

      test('should return empty list for nonexistent company', () async {
        // Arrange
        final mockCards = [
          BusinessCard(
            id: 'card-1',
            name: 'John Doe',
            company: 'Tech Corp',
            createdAt: testDateTime,
          ),
        ];
        mockCardReader.setMockCards(mockCards);

        // Act
        final result = await useCase.getCardsByCompany('Nonexistent Corp');

        // Assert
        expect(result, isEmpty);
      });
    });

    group('錯誤處理', () {
      test('should propagate DataSourceFailure from repository', () async {
        // Arrange
        const failure = DataSourceFailure(
          userMessage: '資料存取錯誤',
          internalMessage: 'Database connection failed',
        );
        mockCardReader.setMockFailure(failure);

        // Act & Assert
        expect(
          () => useCase.execute(const GetCardsParams()),
          throwsA(isA<DataSourceFailure>()),
        );
      });

      test(
        'should propagate NetworkConnectionFailure from repository',
        () async {
          // Arrange
          const failure = NetworkConnectionFailure(
            endpoint: 'api.example.com',
            userMessage: '網路連線失敗',
          );
          mockCardReader.setMockFailure(failure);

          // Act & Assert
          expect(
            () => useCase.getRecentCards(10),
            throwsA(isA<NetworkConnectionFailure>()),
          );
        },
      );

      test('should handle unexpected exceptions gracefully', () async {
        // Arrange
        mockCardReader.setMockFailure(
          const DatabaseConnectionFailure(
            userMessage: '資料庫無法連線',
            internalMessage: 'Connection timeout',
          ),
        );

        // Act & Assert
        expect(
          () => useCase.searchCards(const SearchCardsParams(query: 'test')),
          throwsA(isA<DatabaseConnectionFailure>()),
        );
      });
    });

    group('參數驗證', () {
      test('should handle invalid pagination parameters gracefully', () async {
        // Arrange - 即使參數不合理，也應該讓 Repository 決定如何處理
        mockCardReader.setMockPageResult(
          const CardPageResult(
            cards: [],
            totalCount: 0,
            currentOffset: 0,
            limit: 10,
            hasMore: false,
            totalPages: 0,
          ),
        );

        // Act - 使用無效的分頁參數
        final result = await useCase.executeWithPagination(
          const GetCardsPaginationParams(page: -1, pageSize: -10),
        );

        // Assert - 應該回傳有效的結果結構
        expect(result.cards, isEmpty);
        expect(result.totalCount, 0);
      });

      test('should handle empty search query', () async {
        // Arrange
        final mockCards = [
          BusinessCard(id: 'card-1', name: 'John Doe', createdAt: testDateTime),
        ];
        mockCardReader.setMockCards(mockCards);

        // Act
        final result = await useCase.searchCards(
          const SearchCardsParams(query: ''),
        );

        // Assert - 空搜尋應該回傳符合條件的結果（依 Repository 實作而定）
        expect(result, isA<List<BusinessCard>>());
      });
    });

    group('效能測試', () {
      test('should handle large number of cards efficiently', () async {
        // Arrange
        final largeMockCards = List.generate(
          10000,
          (index) => BusinessCard(
            id: 'card-$index',
            name: 'Person $index',
            company: index % 100 == 0 ? 'Special Corp $index' : 'Regular Corp',
            createdAt: testDateTime.subtract(Duration(minutes: index)),
          ),
        );
        mockCardReader.setMockCards(largeMockCards);

        // Act
        final stopwatch = Stopwatch()..start();
        final result = await useCase.execute(const GetCardsParams(limit: 1000));
        stopwatch.stop();

        // Assert
        expect(result.length, 1000);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 應該在 1 秒內完成
      });

      test('should handle search on large dataset efficiently', () async {
        // Arrange
        final largeMockCards = List.generate(
          5000,
          (index) => BusinessCard(
            id: 'card-$index',
            name: index % 10 == 0
                ? 'John Person $index'
                : 'Other Person $index',
            createdAt: testDateTime,
          ),
        );
        mockCardReader.setMockCards(largeMockCards);

        // Act
        final stopwatch = Stopwatch()..start();
        final result = await useCase.searchCards(
          const SearchCardsParams(query: 'john', limit: 100),
        );
        stopwatch.stop();

        // Assert
        expect(result.length, 100);
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // 搜尋應該很快
      });
    });
  });
}
