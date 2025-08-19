import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_detail/view_models/card_detail_state.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'card_detail_view_model_basic.g.dart';

/// 基礎版的名片詳情 ViewModel（暫時不使用複雜的 UseCase）
@riverpod
class CardDetailViewModelBasic extends _$CardDetailViewModelBasic {
  @override
  CardDetailState build() {
    return const CardDetailState.initial();
  }

  /// 初始化檢視模式（暫時使用模擬資料）
  Future<void> initializeViewing(String cardId) async {
    state = const CardDetailState.loading();

    // 模擬載入延遲
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // 暫時建立模擬名片資料
      final mockCard = BusinessCard(
        id: cardId,
        name: '張三',
        jobTitle: '軟體工程師',
        company: 'ABC科技公司',
        email: 'zhang.san@abc.com',
        phone: '0912-345-678',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      state = CardDetailState.viewing(card: mockCard);
    } on Exception catch (e) {
      state = CardDetailState.error(message: '載入名片失敗：${e.toString()}');
    }
  }

  /// 初始化新增模式（來自 OCR）
  void initializeCreating(BusinessCard parsedCard) {
    state = CardDetailState.creating(
      parsedCard: parsedCard,
      confidence: 0.8,
      fromAIParsing: true,
    );
  }

  /// 初始化手動建立模式
  void initializeManual() {
    final emptyCard = BusinessCard(
      id: const Uuid().v4(),
      name: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    state = CardDetailState.manual(emptyCard: emptyCard);
  }

  /// 更新名片資料
  void updateCard(BusinessCard updatedCard) {
    state.maybeWhen(
      (
        mode,
        isLoading,
        isSaving,
        error,
        originalCard,
        currentCard,
        validationErrors,
        hasChanges,
        ocrParsedCard,
        confidence,
        fromAIParsing,
      ) {},
      editing: (originalCard, currentCard, hasChanges, validationErrors) {
        final hasChanges = updatedCard != originalCard;
        state = CardDetailState.editing(
          originalCard: originalCard,
          currentCard: updatedCard,
          hasChanges: hasChanges,
        );
      },
      creating: (parsedCard, confidence, fromAIParsing, validationErrors) {
        state = CardDetailState.creating(
          parsedCard: updatedCard,
          confidence: confidence,
          fromAIParsing: fromAIParsing,
        );
      },
      manual: (emptyCard, validationErrors) {
        state = CardDetailState.manual(emptyCard: updatedCard);
      },
      orElse: () {},
    );
  }

  /// 儲存名片（暫時只是印出日誌）
  Future<bool> saveCard() async {
    BusinessCard? cardToSave;

    // 使用 pattern matching 取得要儲存的名片
    state.maybeWhen(
      (
        mode,
        isLoading,
        isSaving,
        error,
        originalCard,
        currentCard,
        validationErrors,
        hasChanges,
        ocrParsedCard,
        confidence,
        fromAIParsing,
      ) {},
      editing: (originalCard, currentCard, hasChanges, validationErrors) {
        cardToSave = currentCard;
      },
      creating: (parsedCard, confidence, fromAIParsing, validationErrors) {
        cardToSave = parsedCard;
      },
      manual: (emptyCard, validationErrors) {
        cardToSave = emptyCard;
      },
      orElse: () {},
    );

    if (cardToSave == null || cardToSave!.name.trim().isEmpty) {
      debugPrint('沒有可儲存的名片資料或姓名為空');
      return false;
    }

    try {
      // 暫時只是模擬儲存
      await Future.delayed(const Duration(milliseconds: 1000));
      debugPrint('名片已儲存：${cardToSave!.name}');
      return true;
    } on Exception catch (e) {
      debugPrint('儲存失敗：${e.toString()}');
      return false;
    }
  }

  /// 切換到編輯模式
  void switchToEditMode() {
    state.maybeWhen(
      (
        mode,
        isLoading,
        isSaving,
        error,
        originalCard,
        currentCard,
        validationErrors,
        hasChanges,
        ocrParsedCard,
        confidence,
        fromAIParsing,
      ) {},
      viewing: (card) {
        state = CardDetailState.editing(originalCard: card, currentCard: card);
      },
      orElse: () {},
    );
  }

  /// 取得當前的名片資料（用於表單顯示）
  BusinessCard? get currentCard {
    BusinessCard? result;

    state.maybeWhen(
      (
        mode,
        isLoading,
        isSaving,
        error,
        originalCard,
        currentCard,
        validationErrors,
        hasChanges,
        ocrParsedCard,
        confidence,
        fromAIParsing,
      ) {},
      viewing: (card) => result = card,
      editing: (originalCard, currentCard, hasChanges, validationErrors) {
        result = currentCard;
      },
      creating: (parsedCard, confidence, fromAIParsing, validationErrors) {
        result = parsedCard;
      },
      manual: (emptyCard, validationErrors) {
        result = emptyCard;
      },
      orElse: () {},
    );

    return result;
  }

  /// 是否可以編輯
  bool get canEdit {
    return state.maybeWhen(
      (
        mode,
        isLoading,
        isSaving,
        error,
        originalCard,
        currentCard,
        validationErrors,
        hasChanges,
        ocrParsedCard,
        confidence,
        fromAIParsing,
      ) => false,
      editing: (_, __, ___, ____) => true,
      creating: (_, __, ___, ____) => true,
      manual: (_, __) => true,
      orElse: () => false,
    );
  }
}
