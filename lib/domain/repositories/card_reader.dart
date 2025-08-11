import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';

/// 名片讀取操作介面
/// 
/// 遵循介面隔離原則（ISP），將讀取操作從完整的 Repository 中分離出來。
/// 這樣的設計使得：
/// - 只需要讀取功能的類別不會依賴寫入方法
/// - 更容易進行單元測試和 Mock
/// - 符合單一職責原則
abstract class CardReader {
  /// 取得所有名片
  /// 
  /// [limit] 限制回傳的結果數量，預設為 50
  /// 
  /// 回傳按建立時間降序排列的名片列表
  Future<List<BusinessCard>> getCards({int limit = 50});

  /// 根據 ID 取得特定名片
  /// 
  /// [cardId] 名片的唯一識別碼
  /// 
  /// 回傳對應的名片，如果不存在則拋出 [CardNotFoundException]
  /// 
  /// Throws:
  /// - [CardNotFoundException] 當指定的名片不存在
  /// - [DataSourceFailure] 當資料來源發生錯誤
  Future<BusinessCard> getCardById(String cardId);

  /// 搜尋名片
  /// 
  /// [query] 搜尋關鍵字，會在姓名、公司、職稱中搜尋
  /// [limit] 限制回傳的結果數量，預設為 50
  /// 
  /// 回傳符合搜尋條件的名片列表
  Future<List<BusinessCard>> searchCards(
    String query, {
    int limit = 50,
  });

  /// 分頁取得名片
  /// 
  /// [offset] 跳過的記錄數
  /// [limit] 限制回傳的記錄數，預設為 20
  /// [sortBy] 排序欄位，預設為建立時間
  /// [sortOrder] 排序方向，預設為降序
  /// 
  /// 回傳分頁結果
  Future<CardPageResult> getCardsWithPagination({
    int offset = 0,
    int limit = 20,
    CardSortField sortBy = CardSortField.createdAt,
    SortOrder sortOrder = SortOrder.descending,
  });

  /// 取得名片總數
  Future<int> getCardCount();

  /// 檢查名片是否存在
  /// 
  /// [cardId] 名片的唯一識別碼
  /// 
  /// 回傳 true 如果名片存在，否則回傳 false
  Future<bool> cardExists(String cardId);

  /// 取得最近建立的名片
  /// 
  /// [limit] 限制回傳的數量，預設為 10
  /// 
  /// 回傳按建立時間降序排列的最近名片列表
  Future<List<BusinessCard>> getRecentCards({int limit = 10});

  /// 根據公司名稱取得名片
  /// 
  /// [company] 公司名稱
  /// [limit] 限制回傳的數量，預設為 50
  /// 
  /// 回傳該公司的所有名片列表
  Future<List<BusinessCard>> getCardsByCompany(
    String company, {
    int limit = 50,
  });

  /// 分頁取得名片（新版本 - 支援頁數概念）
  /// 
  /// [page] 頁數（從 1 開始）
  /// [pageSize] 每頁大小，預設為 20
  /// 
  /// 回傳分頁結果，包含頁數資訊
  Future<CardPageResult> getCardsPage({
    int page = 1,
    int pageSize = 20,
  });
}

/// 名片分頁結果
class CardPageResult {
  final List<BusinessCard> cards;
  final int totalCount;
  final int currentOffset;
  final int limit;
  final bool hasMore;
  // 新版本支援頁數概念的欄位
  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const CardPageResult({
    required this.cards,
    required this.totalCount,
    required this.currentOffset,
    required this.limit,
    required this.hasMore,
    // 新增頁數相關參數
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasNext = false,
    this.hasPrevious = false,
  });
}

/// 名片排序欄位
enum CardSortField {
  createdAt,
  updatedAt,
  name,
  company,
}

/// 排序方向
enum SortOrder {
  ascending,
  descending,
}