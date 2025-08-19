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
      // 從模擬資料庫中尋找名片
      final mockCard = _findMockCardById(cardId);
      
      if (mockCard != null) {
        state = CardDetailState.viewing(card: mockCard);
      } else {
        state = const CardDetailState.error(message: '找不到指定的名片');
      }
    } on Exception catch (e) {
      state = CardDetailState.error(message: '載入名片失敗：${e.toString()}');
    }
  }

  /// 根據 ID 查找模擬名片資料
  BusinessCard? _findMockCardById(String cardId) {
    final mockCards = _generateMockCards();
    for (final card in mockCards) {
      if (card.id == cardId) {
        return card;
      }
    }
    return null;
  }

  /// 產生模擬名片資料（與列表頁相同）
  List<BusinessCard> _generateMockCards() {
    final now = DateTime.now();
    return [
      BusinessCard(
        id: 'card_001',
        name: '王小明',
        jobTitle: 'iOS 開發工程師',
        company: 'Apple Taiwan',
        email: 'xiaoming.wang@apple.com',
        phone: '0912-345-678',
        address: '台北市信義區松仁路100號',
        website: 'https://www.apple.com.tw',
        notes: '技術專精 Swift、SwiftUI，曾參與多個大型專案開發',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      BusinessCard(
        id: 'card_002',
        name: '李美華',
        jobTitle: 'UI/UX 設計師',
        company: 'Google Taiwan',
        email: 'meihua.li@google.com',
        phone: '0987-654-321',
        address: '台北市南港區經貿二路66號',
        website: 'https://design.google',
        notes: '專精於使用者體驗設計，擅長 Figma、Sketch 等設計工具',
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      BusinessCard(
        id: 'card_003',
        name: '張志強',
        jobTitle: '產品經理',
        company: 'Microsoft Taiwan',
        email: 'zhiqiang.zhang@microsoft.com',
        phone: '0923-456-789',
        address: '台北市中山區民生東路三段156號',
        notes: '負責 Azure 雲端服務產品線，具備豐富的跨國團隊管理經驗',
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      BusinessCard(
        id: 'card_004',
        name: '陳雅婷',
        jobTitle: 'Flutter 開發工程師',
        company: '91APP',
        email: 'yating.chen@91app.com',
        phone: '0956-789-123',
        address: '台北市松山區復興北路99號',
        website: 'https://www.91app.com',
        notes: '專精 Flutter 跨平台開發，熟悉 Clean Architecture 與 MVVM 模式',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 12)),
      ),
      BusinessCard(
        id: 'card_005',
        name: '林大為',
        jobTitle: '資深軟體架構師',
        company: 'Synology Inc.',
        email: 'dawei.lin@synology.com',
        phone: '0934-567-890',
        address: '新北市汐止區中興路26號',
        website: 'https://www.synology.com',
        notes: '負責 DSM 系統架構設計，專精於分散式系統與雲端儲存技術',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
    ];
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
