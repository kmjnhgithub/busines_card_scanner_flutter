import 'package:busines_card_scanner_flutter/core/services/validation_service.dart';
import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/create_card_manually_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/delete_card_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/get_cards_usecase.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_detail/view_models/card_detail_state.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_detail/view_models/card_detail_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/toast_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/data_providers.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/domain_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockValidationService extends Mock implements ValidationService {}

class MockGetCardsUseCase extends Mock implements GetCardsUseCase {}

class MockCreateCardManuallyUseCase extends Mock
    implements CreateCardManuallyUseCase {}

class MockDeleteCardUseCase extends Mock implements DeleteCardUseCase {}

class MockToastPresenter extends Mock implements ToastPresenter {}

void main() {
  group('CardDetailViewModel', () {
    late ProviderContainer container;
    late MockValidationService mockValidationService;
    late MockGetCardsUseCase mockGetCardsUseCase;
    late MockCreateCardManuallyUseCase mockCreateCardUseCase;
    late MockDeleteCardUseCase mockDeleteCardUseCase;
    late MockToastPresenter mockToastPresenter;

    setUp(() {
      mockValidationService = MockValidationService();
      mockGetCardsUseCase = MockGetCardsUseCase();
      mockCreateCardUseCase = MockCreateCardManuallyUseCase();
      mockDeleteCardUseCase = MockDeleteCardUseCase();
      mockToastPresenter = MockToastPresenter();

      container = ProviderContainer(
        overrides: [
          // 暫時先不使用 providers，直接測試 ViewModel 本身
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('初始狀態', () {
      test('build 應該返回 initial 狀態', () {
        // Act
        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        final state = container.read(cardDetailViewModelProvider);

        // Assert
        expect(state, isA<_Initial>());
      });
    });

    group('檢視模式', () {
      test('initializeViewing 成功載入名片應該設置 viewing 狀態', () async {
        // Arrange
        const cardId = 'test-id';
        final testCard = BusinessCard(
          id: cardId,
          name: '張三',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final cards = [testCard];

        when(mockGetCardsUseCase.execute()).thenAnswer((_) async => cards);

        // Act
        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        await viewModel.initializeViewing(cardId);

        // Assert
        final state = container.read(cardDetailViewModelProvider);
        expect(state, isA<_Viewing>());

        final viewingState = state as _Viewing;
        expect(viewingState.card.id, equals(cardId));
        expect(viewingState.card.name, equals('張三'));
      });

      test('initializeViewing 找不到名片應該設置錯誤狀態', () async {
        // Arrange
        const cardId = 'non-existent-id';
        final cards = <BusinessCard>[];

        when(mockGetCardsUseCase.execute()).thenAnswer((_) async => cards);

        // Act
        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        await viewModel.initializeViewing(cardId);

        // Assert
        final state = container.read(cardDetailViewModelProvider);
        expect(state, isA<_Error>());

        final errorState = state as _Error;
        expect(errorState.message, contains('找不到指定的名片'));
      });

      test('initializeViewing 發生異常應該設置錯誤狀態', () async {
        // Arrange
        const cardId = 'test-id';
        const errorMessage = '網路連線失敗';

        when(mockGetCardsUseCase.execute()).thenThrow(Exception(errorMessage));

        // Act
        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        await viewModel.initializeViewing(cardId);

        // Assert
        final state = container.read(cardDetailViewModelProvider);
        expect(state, isA<_Error>());

        final errorState = state as _Error;
        expect(errorState.message, contains(errorMessage));
      });
    });

    group('編輯模式', () {
      test('initializeEditing 成功載入名片應該設置 editing 狀態', () async {
        // Arrange
        const cardId = 'test-id';
        final testCard = BusinessCard(
          id: cardId,
          name: '張三',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final cards = [testCard];

        when(mockGetCardsUseCase.execute()).thenAnswer((_) async => cards);

        // Act
        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        await viewModel.initializeEditing(cardId);

        // Assert
        final state = container.read(cardDetailViewModelProvider);
        expect(state, isA<_Editing>());

        final editingState = state as _Editing;
        expect(editingState.originalCard.id, equals(cardId));
        expect(editingState.currentCard.id, equals(cardId));
        expect(editingState.hasChanges, isFalse);
      });

      test('switchToEditMode 從檢視模式應該切換到編輯模式', () {
        // Arrange
        final testCard = BusinessCard(
          id: 'test-id',
          name: '張三',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        container.read(cardDetailViewModelProvider.notifier).state =
            CardDetailState.viewing(card: testCard);

        // Act
        viewModel.switchToEditMode();

        // Assert
        final state = container.read(cardDetailViewModelProvider);
        expect(state, isA<_Editing>());

        final editingState = state as _Editing;
        expect(editingState.originalCard, equals(testCard));
        expect(editingState.currentCard, equals(testCard));
      });

      test('switchToViewMode 無變更應該切換回檢視模式', () {
        // Arrange
        final testCard = BusinessCard(
          id: 'test-id',
          name: '張三',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        container
            .read(cardDetailViewModelProvider.notifier)
            .state = CardDetailState.editing(
          originalCard: testCard,
          currentCard: testCard,
          hasChanges: false,
        );

        // Act
        viewModel.switchToViewMode();

        // Assert
        final state = container.read(cardDetailViewModelProvider);
        expect(state, isA<_Viewing>());

        final viewingState = state as _Viewing;
        expect(viewingState.card, equals(testCard));
      });
    });

    group('新增模式', () {
      test('initializeCreating 應該設置 creating 狀態', () {
        // Arrange
        final parsedCard = BusinessCard(
          id: 'parsed-id',
          name: '李四',
          company: 'ABC公司',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final params = CardDetailParams.creating(
          parsedCard: parsedCard,
          confidence: 0.95,
          fromAIParsing: true,
        );

        // Act
        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        viewModel.initializeCreating(params);

        // Assert
        final state = container.read(cardDetailViewModelProvider);
        expect(state, isA<_Creating>());

        final creatingState = state as _Creating;
        expect(creatingState.parsedCard, equals(parsedCard));
        expect(creatingState.confidence, equals(0.95));
        expect(creatingState.fromAIParsing, isTrue);
      });

      test('initializeCreating 缺少解析資料應該設置錯誤狀態', () {
        // Arrange
        const params = CardDetailParams(
          mode: CardDetailMode.creating,
          ocrParsedCard: null,
        );

        // Act
        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        viewModel.initializeCreating(params);

        // Assert
        final state = container.read(cardDetailViewModelProvider);
        expect(state, isA<_Error>());

        final errorState = state as _Error;
        expect(errorState.message, contains('缺少 OCR 解析資料'));
      });
    });

    group('手動建立模式', () {
      test('initializeManual 應該設置空白名片的 manual 狀態', () {
        // Act
        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        viewModel.initializeManual();

        // Assert
        final state = container.read(cardDetailViewModelProvider);
        expect(state, isA<_Manual>());

        final manualState = state as _Manual;
        expect(manualState.emptyCard.name, isEmpty);
        expect(manualState.emptyCard.id, isNotEmpty); // UUID 產生
      });
    });

    group('更新名片資料', () {
      test('updateCard 在編輯模式應該更新當前名片和變更狀態', () {
        // Arrange
        final originalCard = BusinessCard(
          id: 'test-id',
          name: '張三',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final updatedCard = originalCard.copyWith(name: '張四');

        when(mockValidationService.validateEmail(any)).thenReturn(true);
        when(mockValidationService.validatePhone(any)).thenReturn(true);

        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        container
            .read(cardDetailViewModelProvider.notifier)
            .state = CardDetailState.editing(
          originalCard: originalCard,
          currentCard: originalCard,
        );

        // Act
        viewModel.updateCard(updatedCard);

        // Assert
        final state = container.read(cardDetailViewModelProvider);
        expect(state, isA<_Editing>());

        final editingState = state as _Editing;
        expect(editingState.currentCard.name, equals('張四'));
        expect(editingState.hasChanges, isTrue);
      });
    });

    group('驗證', () {
      test('_validateCard 姓名為空應該返回錯誤', () {
        // Arrange
        final card = BusinessCard(
          id: 'test-id',
          name: '', // 空姓名
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final viewModel = container.read(cardDetailViewModelProvider.notifier);

        // Act - 透過 updateCard 間接測試驗證邏輯
        container.read(cardDetailViewModelProvider.notifier).state =
            CardDetailState.editing(originalCard: card, currentCard: card);

        viewModel.updateCard(card);

        // Assert
        final state = container.read(cardDetailViewModelProvider);
        expect(state, isA<_Editing>());

        final editingState = state as _Editing;
        expect(editingState.validationErrors, containsPair('name', '姓名不能為空'));
      });

      test('_validateCard 無效 email 格式應該返回錯誤', () {
        // Arrange
        final card = BusinessCard(
          id: 'test-id',
          name: '張三',
          email: 'invalid-email',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(
          mockValidationService.validateEmail('invalid-email'),
        ).thenReturn(false);

        final viewModel = container.read(cardDetailViewModelProvider.notifier);

        // Act
        container.read(cardDetailViewModelProvider.notifier).state =
            CardDetailState.editing(originalCard: card, currentCard: card);

        viewModel.updateCard(card);

        // Assert
        final state = container.read(cardDetailViewModelProvider);
        final editingState = state as _Editing;
        expect(
          editingState.validationErrors,
          containsPair('email', 'Email 格式不正確'),
        );
      });
    });

    group('儲存名片', () {
      test('saveCard 有效資料應該成功儲存', () async {
        // Arrange
        final card = BusinessCard(
          id: 'test-id',
          name: '張三',
          email: 'zhang@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockValidationService.validateEmail(any)).thenReturn(true);
        when(mockValidationService.validatePhone(any)).thenReturn(true);
        when(mockCreateCardUseCase.execute(any)).thenAnswer((_) async => card);

        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        container.read(cardDetailViewModelProvider.notifier).state =
            CardDetailState.editing(originalCard: card, currentCard: card);

        // Act
        final result = await viewModel.saveCard();

        // Assert
        expect(result, isTrue);
        verify(mockCreateCardUseCase.execute(card)).called(1);
        verify(mockToastPresenter.showSuccess('名片已儲存')).called(1);
      });

      test('saveCard 無效資料應該失敗', () async {
        // Arrange
        final invalidCard = BusinessCard(
          id: 'test-id',
          name: '', // 無效：空姓名
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        container
            .read(cardDetailViewModelProvider.notifier)
            .state = CardDetailState.editing(
          originalCard: invalidCard,
          currentCard: invalidCard,
        );

        // Act
        final result = await viewModel.saveCard();

        // Assert
        expect(result, isFalse);
        verifyNever(mockCreateCardUseCase.execute(any));
        verify(mockToastPresenter.showError('請修正表單錯誤後再儲存')).called(1);
      });

      test('saveCard 儲存失敗應該顯示錯誤', () async {
        // Arrange
        final card = BusinessCard(
          id: 'test-id',
          name: '張三',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        const errorMessage = '網路錯誤';

        when(mockValidationService.validateEmail(any)).thenReturn(true);
        when(mockValidationService.validatePhone(any)).thenReturn(true);
        when(
          mockCreateCardUseCase.execute(any),
        ).thenThrow(Exception(errorMessage));

        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        container.read(cardDetailViewModelProvider.notifier).state =
            CardDetailState.editing(originalCard: card, currentCard: card);

        // Act
        final result = await viewModel.saveCard();

        // Assert
        expect(result, isFalse);
        verify(mockToastPresenter.showError(contains(errorMessage))).called(1);
      });
    });

    group('刪除名片', () {
      test('deleteCard 在檢視模式應該成功刪除', () async {
        // Arrange
        const cardId = 'test-id';
        final card = BusinessCard(
          id: cardId,
          name: '張三',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(
          mockDeleteCardUseCase.execute(cardId),
        ).thenAnswer((_) async => true);

        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        container.read(cardDetailViewModelProvider.notifier).state =
            CardDetailState.viewing(card: card);

        // Act
        final result = await viewModel.deleteCard();

        // Assert
        expect(result, isTrue);
        verify(mockDeleteCardUseCase.execute(cardId)).called(1);
        verify(mockToastPresenter.showSuccess('名片已刪除')).called(1);
      });

      test('deleteCard 刪除失敗應該顯示錯誤', () async {
        // Arrange
        const cardId = 'test-id';
        final card = BusinessCard(
          id: cardId,
          name: '張三',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        const errorMessage = '刪除失敗';

        when(
          mockDeleteCardUseCase.execute(cardId),
        ).thenThrow(Exception(errorMessage));

        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        container.read(cardDetailViewModelProvider.notifier).state =
            CardDetailState.viewing(card: card);

        // Act
        final result = await viewModel.deleteCard();

        // Assert
        expect(result, isFalse);
        verify(mockToastPresenter.showError(contains(errorMessage))).called(1);
      });
    });

    group('輔助方法', () {
      test('currentCard 應該根據狀態返回正確的名片', () {
        // Arrange & Act & Assert for Viewing
        final viewingCard = BusinessCard(
          id: 'viewing-id',
          name: '檢視名片',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final viewModel = container.read(cardDetailViewModelProvider.notifier);
        container.read(cardDetailViewModelProvider.notifier).state =
            CardDetailState.viewing(card: viewingCard);

        expect(viewModel.currentCard, equals(viewingCard));

        // Assert for Editing
        final editingCard = BusinessCard(
          id: 'editing-id',
          name: '編輯名片',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        container
            .read(cardDetailViewModelProvider.notifier)
            .state = CardDetailState.editing(
          originalCard: viewingCard,
          currentCard: editingCard,
        );

        expect(viewModel.currentCard, equals(editingCard));
      });

      test('canEdit 應該根據狀態返回正確的編輯權限', () {
        final card = BusinessCard(
          id: 'test-id',
          name: '測試名片',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final viewModel = container.read(cardDetailViewModelProvider.notifier);

        // 檢視模式不可編輯
        container.read(cardDetailViewModelProvider.notifier).state =
            CardDetailState.viewing(card: card);
        expect(viewModel.canEdit, isFalse);

        // 編輯模式可編輯
        container.read(cardDetailViewModelProvider.notifier).state =
            CardDetailState.editing(originalCard: card, currentCard: card);
        expect(viewModel.canEdit, isTrue);

        // 新增模式可編輯
        container.read(cardDetailViewModelProvider.notifier).state =
            CardDetailState.creating(parsedCard: card);
        expect(viewModel.canEdit, isTrue);

        // 手動模式可編輯
        container.read(cardDetailViewModelProvider.notifier).state =
            CardDetailState.manual(emptyCard: card);
        expect(viewModel.canEdit, isTrue);
      });
    });
  });
}
