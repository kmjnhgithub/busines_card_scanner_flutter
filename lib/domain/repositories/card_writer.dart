import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';

/// 名片寫入操作介面
///
/// 遵循介面隔離原則（ISP），將寫入操作從完整的 Repository 中分離出來。
/// 這樣的設計使得：
/// - 只需要寫入功能的類別不會依賴讀取方法
/// - 可以實作唯讀的名片檢視器
/// - 更容易控制權限和安全性
abstract class CardWriter {
  /// 儲存名片
  ///
  /// [card] 要儲存的名片實體
  ///
  /// 如果 [card.id] 為空或不存在，則建立新名片並分配新的 ID
  /// 如果 [card.id] 已存在，則更新該名片
  ///
  /// 回傳儲存後的名片（包含分配的 ID 和更新的時間戳）
  ///
  /// Throws:
  /// - [ValidationFailure] 當名片資料驗證失敗
  /// - [DataSourceFailure] 當資料來源發生錯誤
  /// - [StorageSpaceFailure] 當儲存空間不足
  Future<BusinessCard> saveCard(BusinessCard card);

  /// 批次儲存名片
  ///
  /// [cards] 要儲存的名片列表
  ///
  /// 回傳儲存結果，包含成功和失敗的項目
  Future<BatchSaveResult> saveCards(List<BusinessCard> cards);

  /// 刪除名片
  ///
  /// [cardId] 要刪除的名片 ID
  ///
  /// 回傳 true 如果刪除成功，false 如果名片不存在
  ///
  /// Throws:
  /// - [DataSourceFailure] 當資料來源發生錯誤
  /// - [CardInUseFailure] 當名片正在被其他操作使用
  Future<bool> deleteCard(String cardId);

  /// 批次刪除名片
  ///
  /// [cardIds] 要刪除的名片 ID 列表
  ///
  /// 回傳刪除結果，包含成功和失敗的項目
  Future<BatchDeleteResult> deleteCards(List<String> cardIds);

  /// 更新名片
  ///
  /// [card] 包含更新資料的名片實體
  ///
  /// 名片必須已存在（card.id 不能為空且必須存在於資料庫中）
  ///
  /// 回傳更新後的名片
  ///
  /// Throws:
  /// - [CardNotFoundException] 當指定的名片不存在
  /// - [ValidationFailure] 當更新資料驗證失敗
  /// - [DataSourceFailure] 當資料來源發生錯誤
  Future<BusinessCard> updateCard(BusinessCard card);

  /// 軟刪除名片（標記為已刪除但不實際刪除）
  ///
  /// [cardId] 要軟刪除的名片 ID
  ///
  /// 回傳 true 如果標記成功
  Future<bool> softDeleteCard(String cardId);

  /// 恢復軟刪除的名片
  ///
  /// [cardId] 要恢復的名片 ID
  ///
  /// 回傳 true 如果恢復成功
  Future<bool> restoreCard(String cardId);

  /// 永久清理軟刪除的名片
  ///
  /// 刪除所有標記為軟刪除且超過指定天數的名片
  ///
  /// [daysOld] 軟刪除後經過的天數，預設為 30 天
  ///
  /// 回傳被永久刪除的名片數量
  Future<int> purgeDeletedCards({int daysOld = 30});
}

/// 批次儲存結果
class BatchSaveResult {
  final List<BusinessCard> successful;
  final List<BatchOperationError> failed;

  const BatchSaveResult({required this.successful, required this.failed});

  bool get hasFailures => failed.isNotEmpty;
  int get successCount => successful.length;
  int get failureCount => failed.length;
}

/// 批次刪除結果
class BatchDeleteResult {
  final List<String> successful;
  final List<BatchOperationError> failed;

  const BatchDeleteResult({required this.successful, required this.failed});

  bool get hasFailures => failed.isNotEmpty;
  int get successCount => successful.length;
  int get failureCount => failed.length;
}

/// 批次操作錯誤
class BatchOperationError {
  final String itemId;
  final String error;
  final dynamic originalData;

  const BatchOperationError({
    required this.itemId,
    required this.error,
    this.originalData,
  });
}
