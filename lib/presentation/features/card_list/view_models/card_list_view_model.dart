import 'package:busines_card_scanner_flutter/core/errors/failures.dart';
import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/delete_card_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/get_cards_usecase.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/domain_providers.dart' as domain;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_list_view_model.freezed.dart';

/// 名片列表排序方式
enum CardListSortBy {
  /// 按姓名排序
  name,
  /// 按公司名稱排序
  company,
  /// 按職稱排序
  jobTitle,
  /// 按建立日期排序
  dateCreated,
  /// 按更新日期排序
  dateUpdated,
}

/// 排序順序
enum SortOrder {
  /// 升序
  ascending,
  /// 降序
  descending,
}

/// 名片列表狀態
@Freezed(toJson: false, fromJson: false)
class CardListState with _$CardListState {
  const factory CardListState({
    /// 所有名片列表
    @Default([]) List<BusinessCard> cards,
    /// 過濾後的名片列表
    @Default([]) List<BusinessCard> filteredCards,
    /// 是否正在載入
    @Default(false) bool isLoading,
    /// 錯誤訊息
    String? error,
    /// 搜尋查詢字串
    @Default('') String searchQuery,
    /// 排序方式
    @Default(CardListSortBy.dateCreated) CardListSortBy sortBy,
    /// 排序順序
    @Default(SortOrder.descending) SortOrder sortOrder,
  }) = _CardListState;
}

/// 名片列表 ViewModel
/// 
/// 負責管理名片列表的狀態和業務邏輯：
/// - 載入名片列表
/// - 搜尋名片
/// - 排序名片
/// - 刪除名片
/// - 錯誤處理
class CardListViewModel extends StateNotifier<CardListState> {
  final GetCardsUseCase _getCardsUseCase;
  final DeleteCardUseCase _deleteCardUseCase;

  CardListViewModel({
    required GetCardsUseCase getCardsUseCase,
    required DeleteCardUseCase deleteCardUseCase,
  })  : _getCardsUseCase = getCardsUseCase,
        _deleteCardUseCase = deleteCardUseCase,
        super(const CardListState());

  /// 載入名片列表
  Future<void> loadCards() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final cards = await _getCardsUseCase.execute(const GetCardsParams());
      state = state.copyWith(
        isLoading: false,
        cards: cards,
        error: null,
      );
      _applyFiltersAndSort();
    } on Exception catch (error) {
      final errorMessage = error is Failure 
          ? error.userMessage 
          : error.toString();
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  /// 搜尋名片
  /// 
  /// 根據姓名、公司、職稱、電子郵件進行搜尋
  void searchCards(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFiltersAndSort();
  }

  /// 刪除名片
  /// 
  /// 返回 true 表示刪除成功，false 表示刪除失敗
  Future<bool> deleteCard(String cardId) async {
    try {
      final result = await _deleteCardUseCase.execute(DeleteCardParams(
        cardId: cardId,
        deleteType: DeleteType.soft,
      ));
      
      if (result.isSuccess) {
        // 刪除成功後重新載入列表
        await loadCards();
        return true;
      } else {
        state = state.copyWith(error: '刪除名片失敗');
        return false;
      }
    } on Exception catch (error) {
      final errorMessage = error is Failure 
          ? error.userMessage 
          : error.toString();
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  /// 排序名片
  void sortCards(CardListSortBy sortBy, SortOrder sortOrder) {
    state = state.copyWith(
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
    _applyFiltersAndSort();
  }

  /// 清除錯誤狀態
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 重新載入名片（保持搜尋和排序狀態）
  Future<void> refresh() async {
    await loadCards();
  }

  /// 應用過濾和排序
  void _applyFiltersAndSort() {
    List<BusinessCard> filtered = List.from(state.cards);

    // 應用搜尋過濾
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filtered = filtered.where((card) {
        return card.name.toLowerCase().contains(query) ||
            (card.company?.toLowerCase().contains(query) ?? false) ||
            (card.jobTitle?.toLowerCase().contains(query) ?? false) ||
            (card.email?.toLowerCase().contains(query) ?? false) ||
            (card.phone?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // 應用排序
    filtered.sort((a, b) {
      int comparison = 0;

      switch (state.sortBy) {
        case CardListSortBy.name:
          comparison = a.name.compareTo(b.name);
          break;
        case CardListSortBy.company:
          final aCompany = a.company ?? '';
          final bCompany = b.company ?? '';
          comparison = aCompany.compareTo(bCompany);
          break;
        case CardListSortBy.jobTitle:
          final aJobTitle = a.jobTitle ?? '';
          final bJobTitle = b.jobTitle ?? '';
          comparison = aJobTitle.compareTo(bJobTitle);
          break;
        case CardListSortBy.dateCreated:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case CardListSortBy.dateUpdated:
          final aUpdated = a.updatedAt ?? a.createdAt;
          final bUpdated = b.updatedAt ?? b.createdAt;
          comparison = aUpdated.compareTo(bUpdated);
          break;
      }

      return state.sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    state = state.copyWith(filteredCards: filtered);
  }
}

/// 名片列表 ViewModel Provider
final cardListViewModelProvider =
    StateNotifierProvider<CardListViewModel, CardListState>((ref) {
  return CardListViewModel(
    getCardsUseCase: ref.read(domain.getCardsUseCaseProvider),
    deleteCardUseCase: ref.read(domain.deleteCardUseCaseProvider),
  );
});