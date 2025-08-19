/// GetCards UseCase 參數
class GetCardsParams {
  final int limit;

  const GetCardsParams({this.limit = 100});
}

/// GetCards 分頁參數
class GetCardsPaginationParams {
  final int page;
  final int pageSize;

  const GetCardsPaginationParams({required this.page, this.pageSize = 20});
}

/// 分頁結果
class CardPageResult {
  final List cards;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  const CardPageResult({
    required this.cards,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });
}
