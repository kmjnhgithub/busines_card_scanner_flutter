import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_reader.dart';

/// GetCardsUseCase - 取得名片的業務用例
///
/// 遵循單一職責原則（SRP），專注於名片的查詢和檢索操作。
/// 透過 CardReader 介面與資料層解耦，支援：
/// - 基本名片列表查詢
/// - 分頁查詢
/// - 關鍵字搜尋
/// - 特定名片查詢
/// - 統計資訊查詢
/// - 公司分組查詢
class GetCardsUseCase {
  final CardReader _cardReader;

  const GetCardsUseCase(this._cardReader);

  /// 執行基本的名片查詢
  ///
  /// [params] 查詢參數，包含限制數量
  ///
  /// 回傳名片列表，按建立時間降序排列
  Future<List<BusinessCard>> execute(GetCardsParams params) async {
    return _cardReader.getCards(limit: params.limit);
  }

  /// 執行分頁查詢
  ///
  /// [params] 分頁參數，包含頁數和每頁大小
  ///
  /// 回傳分頁結果，包含當前頁資料和分頁資訊
  Future<CardPageResult> executeWithPagination(
    GetCardsPaginationParams params,
  ) async {
    return _cardReader.getCardsPage(
      page: params.page,
      pageSize: params.pageSize,
    );
  }

  /// 搜尋名片
  ///
  /// [params] 搜尋參數，包含查詢字串和限制數量
  ///
  /// 回傳符合條件的名片列表
  Future<List<BusinessCard>> searchCards(SearchCardsParams params) async {
    return _cardReader.searchCards(params.query, limit: params.limit);
  }

  /// 根據 ID 取得特定名片
  ///
  /// [cardId] 名片的唯一識別碼
  ///
  /// 回傳找到的名片，如果不存在則拋出 CardNotFoundException
  Future<BusinessCard> getCardById(String cardId) async {
    return _cardReader.getCardById(cardId);
  }

  /// 取得最近建立的名片
  ///
  /// [limit] 限制回傳的數量，預設為 10
  ///
  /// 回傳按建立時間降序排列的最近名片列表
  Future<List<BusinessCard>> getRecentCards(int limit) async {
    return _cardReader.getRecentCards(limit: limit);
  }

  /// 取得名片總數
  ///
  /// 回傳目前儲存的名片總數量
  Future<int> getCardCount() async {
    return _cardReader.getCardCount();
  }

  /// 檢查名片是否存在
  ///
  /// [cardId] 要檢查的名片 ID
  ///
  /// 回傳 true 如果名片存在，否則回傳 false
  Future<bool> cardExists(String cardId) async {
    return _cardReader.cardExists(cardId);
  }

  /// 根據公司名稱取得名片
  ///
  /// [company] 公司名稱
  /// [limit] 限制回傳的數量，預設為 50
  ///
  /// 回傳該公司的所有名片列表
  Future<List<BusinessCard>> getCardsByCompany(
    String company, {
    int limit = 50,
  }) async {
    return _cardReader.getCardsByCompany(company, limit: limit);
  }
}

/// 基本查詢參數
class GetCardsParams {
  final int limit;

  const GetCardsParams({this.limit = 50});
}

/// 分頁查詢參數
class GetCardsPaginationParams {
  final int page;
  final int pageSize;

  const GetCardsPaginationParams({required this.page, required this.pageSize});
}

/// 搜尋參數
class SearchCardsParams {
  final String query;
  final int limit;

  const SearchCardsParams({required this.query, this.limit = 50});
}
