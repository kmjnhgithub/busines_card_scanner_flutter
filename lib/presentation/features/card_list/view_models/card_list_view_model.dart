import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/delete_card_usecase.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/domain_providers.dart'
    as domain;
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
  final DeleteCardUseCase _deleteCardUseCase;

  CardListViewModel({required DeleteCardUseCase deleteCardUseCase})
    : _deleteCardUseCase = deleteCardUseCase,
      super(const CardListState());

  /// 載入名片列表
  Future<void> loadCards() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 暫時使用假資料進行測試
      await Future.delayed(const Duration(milliseconds: 800));
      final cards = _generateMockCards();
      state = state.copyWith(isLoading: false, cards: cards, error: null);
      _applyFiltersAndSort();
    } on Exception catch (error) {
      final errorMessage = error is DomainFailure
          ? error.userMessage
          : error.toString();
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// 產生模擬名片資料（用於測試）
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
        imagePath: 'assets/images/sample_card_1.png',
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
        imagePath: 'assets/images/sample_card_2.png',
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
        imagePath: 'assets/images/sample_card_3.png',
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
        imagePath: 'assets/images/sample_card_4.png',
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
        imagePath: 'assets/images/sample_card_5.png',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
    ];
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
      final result = await _deleteCardUseCase.execute(
        DeleteCardParams(cardId: cardId, deleteType: DeleteType.soft),
      );

      if (result.isSuccess) {
        // 刪除成功後重新載入列表
        await loadCards();
        return true;
      } else {
        state = state.copyWith(error: '刪除名片失敗');
        return false;
      }
    } on Exception catch (error) {
      final errorMessage = error is DomainFailure
          ? error.userMessage
          : error.toString();
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  /// 排序名片
  void sortCards(CardListSortBy sortBy, SortOrder sortOrder) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder);
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
        deleteCardUseCase: ref.read(domain.deleteCardUseCaseProvider),
      );
    });
