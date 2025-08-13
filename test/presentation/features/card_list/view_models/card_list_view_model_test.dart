import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/delete_card_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/get_cards_usecase.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_list/view_models/card_list_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockGetCardsUseCase extends Mock implements GetCardsUseCase {}
class MockDeleteCardUseCase extends Mock implements DeleteCardUseCase {}

void main() {
  setUpAll(() {
    // Register fallback values for Mocktail
    registerFallbackValue(const GetCardsParams());
    registerFallbackValue(const DeleteCardParams(
      cardId: 'test',
      deleteType: DeleteType.soft,
    ));
  });

  group('CardListViewModel', () {
    late MockGetCardsUseCase mockGetCardsUseCase;
    late MockDeleteCardUseCase mockDeleteCardUseCase;
    late ProviderContainer container;

    setUp(() {
      mockGetCardsUseCase = MockGetCardsUseCase();
      mockDeleteCardUseCase = MockDeleteCardUseCase();
      
      container = ProviderContainer(
        overrides: [
          cardListViewModelProvider.overrideWith((ref) => CardListViewModel(
            getCardsUseCase: mockGetCardsUseCase,
            deleteCardUseCase: mockDeleteCardUseCase,
          )),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('初始狀態', () {
      test('應該有正確的初始狀態', () {
        // Act
        final viewModel = container.read(cardListViewModelProvider.notifier);
        final state = container.read(cardListViewModelProvider);

        // Assert
        expect(state.cards, isEmpty);
        expect(state.filteredCards, isEmpty);
        expect(state.isLoading, false);
        expect(state.error, null);
        expect(state.searchQuery, '');
        expect(state.sortBy, CardListSortBy.dateCreated);
        expect(state.sortOrder, SortOrder.descending);
      });
    });

    group('loadCards', () {
      final testCards = [
        BusinessCard(
          id: '1',
          name: '張三',
          company: '公司A',
          jobTitle: '經理',
          email: 'zhang@example.com',
          phone: '0912345678',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        BusinessCard(
          id: '2',
          name: '李四',
          company: '公司B',
          jobTitle: '總監',
          email: 'li@example.com',
          phone: '0987654321',
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        ),
      ];

      test('成功載入名片時應該更新狀態', () async {
        // Arrange
        when(() => mockGetCardsUseCase.execute(any())).thenAnswer(
          (_) async => testCards,
        );

        // Act
        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();

        // Assert
        final state = container.read(cardListViewModelProvider);
        expect(state.cards, equals(testCards));
        // 預設按 dateCreated descending 排序，所以順序會是 [李四, 張三]
        expect(state.filteredCards.length, equals(testCards.length));
        expect(state.filteredCards.first.id, equals('2')); // 李四 (2024-01-02, 較新的日期)
        expect(state.filteredCards.last.id, equals('1')); // 張三 (2024-01-01, 較舊的日期)
        expect(state.isLoading, false);
        expect(state.error, null);

        verify(() => mockGetCardsUseCase.execute(any())).called(1);
      });

      test('載入失敗時應該設置錯誤狀態', () async {
        // Arrange
        const failure = DataSourceFailure(userMessage: 'Database error');
        when(() => mockGetCardsUseCase.execute(any())).thenThrow(failure);

        // Act
        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();

        // Assert
        final state = container.read(cardListViewModelProvider);
        expect(state.cards, isEmpty);
        expect(state.filteredCards, isEmpty);
        expect(state.isLoading, false);
        expect(state.error, equals('Database error'));

        verify(() => mockGetCardsUseCase.execute(any())).called(1);
      });

      test('載入過程中應該顯示載入狀態', () async {
        // Arrange
        when(() => mockGetCardsUseCase.execute(any())).thenAnswer(
          (_) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return testCards;
          },
        );

        // Act
        final viewModel = container.read(cardListViewModelProvider.notifier);
        final loadingFuture = viewModel.loadCards();

        // Assert loading state
        await Future.delayed(const Duration(milliseconds: 50));
        expect(container.read(cardListViewModelProvider).isLoading, true);

        // Wait for completion
        await loadingFuture;
        expect(container.read(cardListViewModelProvider).isLoading, false);
      });
    });

    group('searchCards', () {
      final testCards = [
        BusinessCard(
          id: '1',
          name: '張三',
          company: '台積電',
          jobTitle: '工程師',
          email: 'zhang@tsmc.com',
          phone: '0912345678',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        BusinessCard(
          id: '2',
          name: '李四',
          company: '聯發科',
          jobTitle: '經理',
          email: 'li@mediatek.com',
          phone: '0987654321',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        BusinessCard(
          id: '3',
          name: '王五',
          company: '台積電',
          jobTitle: '總監',
          email: 'wang@tsmc.com',
          phone: '0955555555',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      setUp(() {
        when(() => mockGetCardsUseCase.execute(any())).thenAnswer(
          (_) async => testCards,
        );
      });

      test('應該根據姓名搜尋名片', () async {
        // Arrange
        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();

        // Act
        viewModel.searchCards('張三');

        // Assert
        final state = container.read(cardListViewModelProvider);
        expect(state.searchQuery, equals('張三'));
        expect(state.filteredCards.length, equals(1));
        expect(state.filteredCards.first.name, equals('張三'));
      });

      test('應該根據公司名稱搜尋名片', () async {
        // Arrange
        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();

        // Act
        viewModel.searchCards('台積電');

        // Assert
        final state = container.read(cardListViewModelProvider);
        expect(state.filteredCards.length, equals(2));
        expect(state.filteredCards.every((card) => card.company?.contains('台積電') ?? false), true);
      });

      test('應該根據職稱搜尋名片', () async {
        // Arrange
        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();

        // Act
        viewModel.searchCards('經理');

        // Assert
        final state = container.read(cardListViewModelProvider);
        expect(state.filteredCards.length, equals(1));
        expect(state.filteredCards.first.jobTitle!.contains('經理'), true);
      });

      test('應該忽略大小寫進行搜尋', () async {
        // Arrange
        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();

        // Act
        viewModel.searchCards('zhang');

        // Assert
        final state = container.read(cardListViewModelProvider);
        expect(state.filteredCards.length, equals(1));
        expect(state.filteredCards.first.email?.toLowerCase().contains('zhang') ?? false, true);
      });

      test('空搜尋查詢應該顯示所有名片', () async {
        // Arrange
        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();
        viewModel.searchCards('台積電');

        // Act
        viewModel.searchCards('');

        // Assert
        final state = container.read(cardListViewModelProvider);
        expect(state.searchQuery, equals(''));
        expect(state.filteredCards.length, equals(testCards.length));
      });

      test('沒有匹配結果時應該返回空列表', () async {
        // Arrange
        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();

        // Act
        viewModel.searchCards('不存在的公司');

        // Assert
        final state = container.read(cardListViewModelProvider);
        expect(state.filteredCards, isEmpty);
      });
    });

    group('deleteCard', () {
      final testCards = [
        BusinessCard(
          id: '1',
          name: '張三',
          company: '公司A',
          jobTitle: '經理',
          email: 'zhang@example.com',
          phone: '0912345678',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        BusinessCard(
          id: '2',
          name: '李四',
          company: '公司B',
          jobTitle: '總監',
          email: 'li@example.com',
          phone: '0987654321',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      test('成功刪除名片後應該重新載入列表', () async {
        // Arrange
        when(() => mockGetCardsUseCase.execute(any())).thenAnswer(
          (_) async => testCards,
        );
        when(() => mockDeleteCardUseCase.execute(any())).thenAnswer(
          (_) async => const DeleteCardResult(
            isSuccess: true, 
            deletedCardId: '1',
            deleteType: DeleteType.soft,
            isReversible: true,
            processingSteps: ['參數驗證', '刪除執行'],
            warnings: [],
          ),
        );

        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();

        // Mock the updated list after deletion
        when(() => mockGetCardsUseCase.execute(any())).thenAnswer(
          (_) async => [testCards[1]],
        );

        // Act
        final result = await viewModel.deleteCard('1');

        // Assert
        expect(result, true);
        final state = container.read(cardListViewModelProvider);
        expect(state.cards.length, equals(1));
        expect(state.cards.first.id, equals('2'));

        verify(() => mockDeleteCardUseCase.execute(any())).called(1);
        verify(() => mockGetCardsUseCase.execute(any())).called(2); // Initial load + reload after delete
      });

      test('刪除失敗時應該返回 false 並設置錯誤狀態', () async {
        // Arrange
        when(() => mockGetCardsUseCase.execute(any())).thenAnswer(
          (_) async => testCards,
        );
        const failure = DataSourceFailure(userMessage: 'Delete failed');
        when(() => mockDeleteCardUseCase.execute(any())).thenThrow(failure);

        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();

        // Act
        final result = await viewModel.deleteCard('1');

        // Assert
        expect(result, false);
        final state = container.read(cardListViewModelProvider);
        expect(state.error, equals('Delete failed'));
        expect(state.cards.length, equals(2)); // Cards should remain unchanged

        verify(() => mockDeleteCardUseCase.execute(any())).called(1);
        verify(() => mockGetCardsUseCase.execute(any())).called(1); // Only initial load
      });
    });

    group('sortCards', () {
      final testCards = [
        BusinessCard(
          id: '1',
          name: '張三',
          company: 'B公司',
          jobTitle: '經理',
          email: 'zhang@example.com',
          phone: '0912345678',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        BusinessCard(
          id: '2',
          name: '李四',
          company: 'A公司',
          jobTitle: '總監',
          email: 'li@example.com',
          phone: '0987654321',
          createdAt: DateTime(2024, 1, 2),
          updatedAt: DateTime(2024, 1, 2),
        ),
      ];

      setUp(() {
        when(() => mockGetCardsUseCase.execute(any())).thenAnswer(
          (_) async => testCards,
        );
      });

      test('應該根據姓名排序', () async {
        // Arrange
        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();

        // Act
        viewModel.sortCards(CardListSortBy.name, SortOrder.ascending);

        // Assert
        final state = container.read(cardListViewModelProvider);
        expect(state.sortBy, equals(CardListSortBy.name));
        expect(state.sortOrder, equals(SortOrder.ascending));
        // 在 Unicode 排序中，'張' (U+5F35) < '李' (U+674E)，所以張三在前
        expect(state.filteredCards.first.name, equals('張三'));
        expect(state.filteredCards.last.name, equals('李四'));
      });

      test('應該根據公司名稱排序', () async {
        // Arrange
        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();

        // Act
        viewModel.sortCards(CardListSortBy.company, SortOrder.ascending);

        // Assert
        final state = container.read(cardListViewModelProvider);
        expect(state.filteredCards.first.company, equals('A公司'));
        expect(state.filteredCards.last.company, equals('B公司'));
      });

      test('應該根據建立日期排序', () async {
        // Arrange
        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();

        // Act
        viewModel.sortCards(CardListSortBy.dateCreated, SortOrder.ascending);

        // Assert
        final state = container.read(cardListViewModelProvider);
        expect(state.filteredCards.first.createdAt, equals(DateTime(2024, 1, 1)));
        expect(state.filteredCards.last.createdAt, equals(DateTime(2024, 1, 2)));
      });

      test('降序排序應該正確工作', () async {
        // Arrange
        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();

        // Act
        viewModel.sortCards(CardListSortBy.name, SortOrder.descending);

        // Assert
        final state = container.read(cardListViewModelProvider);
        // 降序：'李' > '張'，所以李四在前
        expect(state.filteredCards.first.name, equals('李四'));
        expect(state.filteredCards.last.name, equals('張三'));
      });

      test('排序後搜尋應該保持排序順序', () async {
        // Arrange
        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();
        viewModel.sortCards(CardListSortBy.name, SortOrder.ascending);

        // Act
        viewModel.searchCards('公司');

        // Assert
        final state = container.read(cardListViewModelProvider);
        expect(state.filteredCards.length, equals(2));
        expect(state.filteredCards.first.name, equals('張三')); // Should maintain sort order (ascending by name)
      });
    });

    group('clearError', () {
      test('應該清除錯誤狀態', () async {
        // Arrange
        const failure = DataSourceFailure(userMessage: 'Test error');
        when(() => mockGetCardsUseCase.execute(any())).thenThrow(failure);

        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();

        // Verify error is set
        expect(container.read(cardListViewModelProvider).error, equals('Test error'));

        // Act
        viewModel.clearError();

        // Assert
        final state = container.read(cardListViewModelProvider);
        expect(state.error, null);
      });
    });

    group('refresh', () {
      test('應該重新載入名片並保持搜尋狀態', () async {
        // Arrange
        final initialCards = [
          BusinessCard(
            id: '1',
            name: '張三',
            company: '公司A',
            jobTitle: '經理',
            email: 'zhang@example.com',
            phone: '0912345678',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final updatedCards = [
          BusinessCard(
            id: '1',
            name: '張三',
            company: '公司A',
            jobTitle: '經理',
            email: 'zhang@example.com',
            phone: '0912345678',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          BusinessCard(
            id: '2',
            name: '李四',
            company: '公司B',
            jobTitle: '總監',
            email: 'li@example.com',
            phone: '0987654321',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(() => mockGetCardsUseCase.execute(any())).thenAnswer(
          (_) async => initialCards,
        );

        final viewModel = container.read(cardListViewModelProvider.notifier);
        await viewModel.loadCards();
        viewModel.searchCards('張三');

        // Mock updated data
        when(() => mockGetCardsUseCase.execute(any())).thenAnswer(
          (_) async => updatedCards,
        );

        // Act
        await viewModel.refresh();

        // Assert
        final state = container.read(cardListViewModelProvider);
        expect(state.cards.length, equals(2));
        expect(state.searchQuery, equals('張三')); // Search should be preserved
        expect(state.filteredCards.length, equals(1)); // Filtered results should be updated
        expect(state.filteredCards.first.name, equals('張三'));

        verify(() => mockGetCardsUseCase.execute(any())).called(2);
      });
    });
  });
}