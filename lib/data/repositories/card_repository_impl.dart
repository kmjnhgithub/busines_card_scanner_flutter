// lib/data/repositories/card_repository_impl.dart

import 'package:busines_card_scanner_flutter/data/datasources/local/clean_app_database.dart';
import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_reader.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_repository.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_writer.dart';
import 'package:drift/drift.dart' show Value;

/// CardRepository 的 Drift 資料庫實作
/// 
/// 遵循 Clean Architecture 原則，實作 Domain 層定義的 CardRepository 介面。
/// 使用 Drift 作為本地資料儲存方案，提供完整的 CRUD 操作支援。
/// 
/// 特點：
/// - **依賴反轉**: 依賴 Domain 層的抽象介面，不依賴具體實作
/// - **錯誤處理**: 將資料層錯誤轉換為 Domain 層的 Failure 類型
/// - **資料轉換**: 在 Data Model 和 Domain Entity 之間進行轉換
/// - **輸入驗證**: 在儲存前驗證業務規則
class CardRepositoryImpl implements CardRepository {
  final CleanAppDatabase _database;

  const CardRepositoryImpl(this._database);

  @override
  String get implementationName => 'CardRepositoryImpl_Drift';

  @override
  Future<bool> isHealthy() async {
    try {
      // 嘗試執行簡單查詢來檢查資料庫健康狀態
      await _database.cardDao.getAllBusinessCards();
      return true;
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    await _database.close();
  }

  // ==================== CardReader 實作 ====================

  @override
  Future<List<BusinessCard>> getCards({int limit = 50}) async {
    try {
      final models = await _database.cardDao.getAllBusinessCards();
      // 應用 limit
      final limitedModels = models.take(limit).toList();
      return limitedModels.map((model) => model).toList();
    } catch (e) {
      throw DataSourceFailure(
        userMessage: 'Failed to get cards',
        internalMessage: 'CardRepositoryImpl.getCards error: $e',
      );
    }
  }

  @override
  Future<BusinessCard> getCardById(String cardId) async {
    try {
      final cardIdInt = int.tryParse(cardId);
      if (cardIdInt == null) {
        throw ArgumentError('Invalid card ID format: $cardId');
      }
      final model = await _database.cardDao.getBusinessCardById(cardIdInt);
      if (model == null) {
        throw DataSourceFailure(
          userMessage: 'Card not found',
          internalMessage: 'Card with ID $cardId not found',
        );
      }
      return model;
    } catch (e) {
      if (e is DataSourceFailure) {
        rethrow;
      }
      throw DataSourceFailure(
        userMessage: 'Failed to get card',
        internalMessage: 'CardRepositoryImpl.getCardById error: $e',
      );
    }
  }

  @override
  Future<List<BusinessCard>> searchCards(String query, {int limit = 50}) async {
    try {
      final models = await _database.cardDao.searchBusinessCards(query);
      // 應用 limit
      final limitedModels = models.take(limit).toList();
      return limitedModels.map((model) => model).toList();
    } catch (e) {
      throw DataSourceFailure(
        userMessage: 'Failed to search cards',
        internalMessage: 'CardRepositoryImpl.searchCards error: $e',
      );
    }
  }

  @override
  Future<List<BusinessCard>> getCardsByCompany(String company, {int limit = 50}) async {
    try {
      // Note: getCardsByCompany not implemented in CardDao, using search instead
      final models = await _database.cardDao.searchBusinessCards(company);
      // 應用 limit
      final limitedModels = models.take(limit).toList();
      return limitedModels.map((model) => model).toList();
    } catch (e) {
      throw DataSourceFailure(
        userMessage: 'Failed to get cards by company',
        internalMessage: 'CardRepositoryImpl.getCardsByCompany error: $e',
      );
    }
  }

  @override
  Future<CardPageResult> getCardsWithPagination({
    int offset = 0,
    int limit = 20,
    CardSortField sortBy = CardSortField.createdAt,
    SortOrder sortOrder = SortOrder.descending,
  }) async {
    try {
      // 暫時實作 - 未來需要在 CardDao 中加入分頁支援
      final allModels = await _database.cardDao.getAllBusinessCards();
      final totalCount = allModels.length;
      
      final paginatedModels = allModels
          .skip(offset)
          .take(limit)
          .toList();
          
      final cards = paginatedModels.map((model) => model).toList();
      
      return CardPageResult(
        cards: cards,
        totalCount: totalCount,
        currentOffset: offset,
        limit: limit,
        hasMore: offset + limit < totalCount,
      );
    } catch (e) {
      throw DataSourceFailure(
        userMessage: 'Failed to get cards with pagination',
        internalMessage: 'CardRepositoryImpl.getCardsWithPagination error: $e',
      );
    }
  }

  @override
  Future<int> getCardCount() async {
    try {
      final models = await _database.cardDao.getAllBusinessCards();
      return models.length;
    } catch (e) {
      throw DataSourceFailure(
        userMessage: 'Failed to get card count',
        internalMessage: 'CardRepositoryImpl.getCardCount error: $e',
      );
    }
  }

  @override
  Future<bool> cardExists(String cardId) async {
    try {
      final cardIdInt = int.tryParse(cardId);
      if (cardIdInt == null) {
        return false;
      }
      final model = await _database.cardDao.getBusinessCardById(cardIdInt);
      return model != null;
    } catch (e) {
      throw DataSourceFailure(
        userMessage: 'Failed to check if card exists',
        internalMessage: 'CardRepositoryImpl.cardExists error: $e',
      );
    }
  }

  @override
  Future<List<BusinessCard>> getRecentCards({int limit = 10}) async {
    try {
      final models = await _database.cardDao.getAllBusinessCards();
      // 取前 limit 個（已按時間排序）
      final recentModels = models.take(limit).toList();
      return recentModels.map((model) => model).toList();
    } catch (e) {
      throw DataSourceFailure(
        userMessage: 'Failed to get recent cards',
        internalMessage: 'CardRepositoryImpl.getRecentCards error: $e',
      );
    }
  }

  @override
  Future<CardPageResult> getCardsPage({int page = 1, int pageSize = 20}) async {
    final offset = (page - 1) * pageSize;
    final result = await getCardsWithPagination(
      offset: offset,
      limit: pageSize,
    );
    
    final totalPages = (result.totalCount / pageSize).ceil();
    
    return CardPageResult(
      cards: result.cards,
      totalCount: result.totalCount,
      currentOffset: offset,
      limit: pageSize,
      hasMore: result.hasMore,
      currentPage: page,
      totalPages: totalPages,
      hasNext: page < totalPages,
      hasPrevious: page > 1,
    );
  }

  // ==================== CardWriter 實作 ====================

  @override
  Future<BusinessCard> saveCard(BusinessCard card) async {
    try {
      // 驗證卡片資料
      _validateCard(card);
      
      // 如果 ID 為空或卡片不存在，則插入新卡片
      if (card.id.isEmpty || !await cardExists(card.id)) {
        // 為新卡片生成 ID
        final newId = card.id.isEmpty ? _generateId() : card.id;
        final newCard = card.copyWith(id: newId);
        
        // 建立 BusinessCardsCompanion 以插入資料庫
        final companion = BusinessCardsCompanion.insert(
          name: newCard.name,
          jobTitle: Value(newCard.jobTitle),
          company: Value(newCard.company),
          email: Value(newCard.email),
          phone: Value(newCard.phone),
          address: Value(newCard.address),
          website: Value(newCard.website),
          notes: Value(newCard.notes),
        );
        
        final insertedId = await _database.cardDao.insertBusinessCard(companion);
        // 插入後重新取得卡片
        final savedCard = await _database.cardDao.getBusinessCardById(insertedId);
        return savedCard!;
      } else {
        // 否則更新現有卡片
        await _database.cardDao.updateBusinessCard(card);
        // 更新後重新取得卡片
        final cardIdInt = int.tryParse(card.id);
        if (cardIdInt == null) {
          throw ArgumentError('Invalid card ID format: ${card.id}');
        }
        final updatedCard = await _database.cardDao.getBusinessCardById(cardIdInt);
        return updatedCard!;
      }
    } catch (e) {
      if (e is DomainFailure) {
        rethrow;
      }
      throw DataSourceFailure(
        userMessage: 'Failed to save card',
        internalMessage: 'CardRepositoryImpl.saveCard error: $e',
      );
    }
  }

  @override
  Future<bool> deleteCard(String cardId) async {
    try {
      final cardIdInt = int.tryParse(cardId);
      if (cardIdInt == null) {
        throw ArgumentError('Invalid card ID format: $cardId');
      }
      return await _database.cardDao.deleteBusinessCard(cardIdInt);
    } catch (e) {
      throw DataSourceFailure(
        userMessage: 'Failed to delete card',
        internalMessage: 'CardRepositoryImpl.deleteCard error: $e',
      );
    }
  }

  @override
  Future<BusinessCard> updateCard(BusinessCard card) async {
    try {
      // 確認卡片存在
      if (!await cardExists(card.id)) {
        throw DataSourceFailure(
          userMessage: 'Card not found',
          internalMessage: 'Cannot update card that does not exist: ${card.id}',
        );
      }
      
      // 驗證卡片資料
      _validateCard(card);
      
      await _database.cardDao.updateBusinessCard(card);
      
      // 更新後重新取得卡片
      final cardIdInt = int.tryParse(card.id);
      if (cardIdInt == null) {
        throw ArgumentError('Invalid card ID format: ${card.id}');
      }
      final updatedCard = await _database.cardDao.getBusinessCardById(cardIdInt);
      return updatedCard!;
    } catch (e) {
      if (e is DomainFailure) {
        rethrow;
      }
      throw DataSourceFailure(
        userMessage: 'Failed to update card',
        internalMessage: 'CardRepositoryImpl.updateCard error: $e',
      );
    }
  }

  // ==================== 暫未實作的批次操作和軟刪除功能 ====================
  
  @override
  Future<BatchSaveResult> saveCards(List<BusinessCard> cards) async {
    // 簡化實作：逐一儲存（未來可優化為真正的批次操作）
    final successful = <BusinessCard>[];
    final failed = <BatchOperationError>[];
    
    for (final card in cards) {
      try {
        final savedCard = await saveCard(card);
        successful.add(savedCard);
      } on Exception catch (e) {
        failed.add(BatchOperationError(
          itemId: card.id,
          error: e.toString(),
          originalData: card,
        ));
      }
    }
    
    return BatchSaveResult(
      successful: successful,
      failed: failed,
    );
  }

  @override
  Future<BatchDeleteResult> deleteCards(List<String> cardIds) async {
    // 簡化實作：逐一刪除（未來可優化為真正的批次操作）
    final successful = <String>[];
    final failed = <BatchOperationError>[];
    
    for (final cardId in cardIds) {
      try {
        final deleted = await deleteCard(cardId);
        if (deleted) {
          successful.add(cardId);
        } else {
          failed.add(BatchOperationError(
            itemId: cardId,
            error: 'Card not found',
          ));
        }
      } on Exception catch (e) {
        failed.add(BatchOperationError(
          itemId: cardId,
          error: e.toString(),
        ));
      }
    }
    
    return BatchDeleteResult(
      successful: successful,
      failed: failed,
    );
  }

  @override
  Future<bool> softDeleteCard(String cardId) async {
    // 暫未實作軟刪除功能 - 需要在資料庫 schema 中加入 deleted_at 欄位
    throw UnimplementedError('Soft delete feature not implemented yet');
  }

  @override
  Future<bool> restoreCard(String cardId) async {
    // 暫未實作軟刪除恢復功能
    throw UnimplementedError('Restore card feature not implemented yet');
  }

  @override
  Future<int> purgeDeletedCards({int daysOld = 30}) async {
    // 暫未實作軟刪除清理功能
    throw UnimplementedError('Purge deleted cards feature not implemented yet');
  }

  // ==================== 私有方法 ====================

  /// 生成唯一 ID
  String _generateId() {
    // 簡單的 ID 生成策略：時間戳 + 隨機數
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'card_${timestamp}_$random';
  }

  /// 驗證名片資料
  void _validateCard(BusinessCard card) {
    if (card.name.trim().isEmpty) {
      throw const DomainValidationFailure(
        userMessage: 'Name is required',
        internalMessage: 'BusinessCard name cannot be empty',
        field: 'name',
      );
    }
    
    if (card.name.length > 100) {
      throw const DomainValidationFailure(
        userMessage: 'Name is too long',
        internalMessage: 'BusinessCard name length exceeds 100 characters',
        field: 'name',
      );
    }
    
    // 可以加入更多驗證規則
  }
}