import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_repository.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_detail/view_models/card_detail_state.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/data_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'card_detail_view_model_basic.g.dart';

/// 基礎版的名片詳情 ViewModel（使用真正的資料庫儲存）
@riverpod
class CardDetailViewModelBasic extends _$CardDetailViewModelBasic {
  CardRepository get _cardRepository => ref.read(cardRepositoryProvider);

  @override
  CardDetailState build() {
    return const CardDetailState.initial();
  }

  /// 初始化檢視模式（從真實資料庫載入）
  Future<void> initializeViewing(String cardId) async {
    state = const CardDetailState.loading();

    try {
      final card = await _cardRepository.getCardById(cardId);
      state = CardDetailState.viewing(card: card);
    } on Exception catch (e) {
      debugPrint('載入名片失敗: $e');
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
        final newHasChanges = updatedCard != originalCard;
        state = CardDetailState.editing(
          originalCard: originalCard,
          currentCard: updatedCard,
          hasChanges: newHasChanges,
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

  /// 更新名片欄位（專為表單使用）
  void updateField({
    String? name,
    String? jobTitle,
    String? company,
    String? email,
    String? phone,
    String? address,
    String? website,
    String? notes,
  }) {
    final current = currentCard;
    if (current == null) {
      return;
    }

    final updated = current.copyWith(
      name: name ?? current.name,
      jobTitle: jobTitle ?? current.jobTitle,
      company: company ?? current.company,
      email: email ?? current.email,
      phone: phone ?? current.phone,
      address: address ?? current.address,
      website: website ?? current.website,
      notes: notes ?? current.notes,
      updatedAt: DateTime.now(),
    );

    updateCard(updated);
  }

  /// 儲存名片（真正儲存到資料庫）
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
      // 為新名片生成 UUID（如果是空的或數字ID）
      String finalCardId = cardToSave!.id;
      if (finalCardId.isEmpty || int.tryParse(finalCardId) != null) {
        finalCardId = const Uuid().v4();
      }

      final cardToSaveWithId = cardToSave!.copyWith(
        id: finalCardId,
        updatedAt: DateTime.now(),
      );

      // 真正儲存到資料庫
      final savedCard = await _cardRepository.saveCard(cardToSaveWithId);

      debugPrint('名片已成功儲存到資料庫：${savedCard.name} (ID: ${savedCard.id})');

      return true;
    } on Exception catch (e) {
      debugPrint('儲存名片到資料庫失敗：${e.toString()}');
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
      viewing: (card) {
        result = card;
      },
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
