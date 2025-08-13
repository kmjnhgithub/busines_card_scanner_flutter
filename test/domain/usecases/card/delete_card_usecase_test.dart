import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_writer.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/delete_card_usecase.dart';
import 'package:flutter_test/flutter_test.dart';


/// Mock CardWriter 用於測試
class MockCardWriter implements CardWriter {
  BusinessCard? _mockSavedCard;
  BatchSaveResult? _mockBatchResult;
  BatchDeleteResult? _mockDeleteResult;
  bool _mockDeleteSuccess = true;
  bool _mockSoftDeleteSuccess = true;
  bool _mockRestoreSuccess = true;
  int _mockPurgeCount = 0;
  DomainFailure? _mockFailure;
  
  void setMockSavedCard(BusinessCard card) => _mockSavedCard = card;
  void setMockBatchResult(BatchSaveResult result) => _mockBatchResult = result;
  void setMockDeleteResult(BatchDeleteResult result) => _mockDeleteResult = result;
  void setMockDeleteSuccess(bool success) => _mockDeleteSuccess = success;
  void setMockSoftDeleteSuccess(bool success) => _mockSoftDeleteSuccess = success;
  void setMockRestoreSuccess(bool success) => _mockRestoreSuccess = success;
  void setMockPurgeCount(int count) => _mockPurgeCount = count;
  void setMockFailure(DomainFailure failure) => _mockFailure = failure;

  @override
  Future<BusinessCard> saveCard(BusinessCard card) async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockSavedCard ?? card;
  }

  @override
  Future<BatchSaveResult> saveCards(List<BusinessCard> cards) async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockBatchResult ?? BatchSaveResult(successful: cards, failed: []);
  }

  @override
  Future<bool> deleteCard(String cardId) async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockDeleteSuccess;
  }

  @override
  Future<BatchDeleteResult> deleteCards(List<String> cardIds) async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockDeleteResult ?? BatchDeleteResult(
      successful: _mockDeleteSuccess ? cardIds : [],
      failed: _mockDeleteSuccess ? [] : cardIds.map((id) => BatchOperationError(
        itemId: id,
        error: 'Mock delete failure',
      )).toList(),
    );
  }

  @override
  Future<BusinessCard> updateCard(BusinessCard card) async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockSavedCard ?? card;
  }

  @override
  Future<bool> softDeleteCard(String cardId) async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockSoftDeleteSuccess;
  }

  @override
  Future<bool> restoreCard(String cardId) async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockRestoreSuccess;
  }

  @override
  Future<int> purgeDeletedCards({int daysOld = 30}) async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockPurgeCount;
  }
}

void main() {
  group('DeleteCardUseCase Tests', () {
    late DeleteCardUseCase useCase;
    late MockCardWriter mockCardWriter;

    setUp(() {
      mockCardWriter = MockCardWriter();
      useCase = DeleteCardUseCase(mockCardWriter);
    });

    group('硬刪除功能', () {
      test('should delete single card successfully', () async {
        // Arrange
        const cardId = 'card-123';
        mockCardWriter.setMockDeleteSuccess(true);

        // Act
        final result = await useCase.execute(const DeleteCardParams(
          cardId: cardId,
          deleteType: DeleteType.hard,
        ));

        // Assert
        expect(result.isSuccess, true);
        expect(result.deletedCardId, cardId);
        expect(result.deleteType, DeleteType.hard);
        expect(result.processingSteps, contains('硬刪除執行'));
        expect(result.isReversible, false);
      });

      test('should handle delete failure gracefully', () async {
        // Arrange
        const cardId = 'card-456';
        mockCardWriter.setMockDeleteSuccess(false);

        // Act
        final result = await useCase.execute(const DeleteCardParams(
          cardId: cardId,
          deleteType: DeleteType.hard,
        ));

        // Assert
        expect(result.isSuccess, false);
        expect(result.deletedCardId, cardId);
        expect(result.hasWarnings, true);
        expect(result.warnings.first, contains('刪除失敗'));
      });

      test('should validate card ID before deletion', () async {
        // Arrange - 空的 card ID
        const emptyCardId = '';

        // Act & Assert
        expect(
          () => useCase.execute(const DeleteCardParams(
            cardId: emptyCardId,
            deleteType: DeleteType.hard,
          )),
          throwsA(isA<InvalidInputFailure>()),
        );
      });

      test('should validate card ID format', () async {
        // Arrange - 無效格式的 card ID
        const invalidCardId = r'invalid@#$%';

        // Act & Assert
        expect(
          () => useCase.execute(const DeleteCardParams(
            cardId: invalidCardId,
            deleteType: DeleteType.hard,
          )),
          throwsA(isA<InvalidInputFailure>()),
        );
      });

      test('should track deletion metrics when enabled', () async {
        // Arrange
        const cardId = 'card-metrics';

        // Act
        final result = await useCase.execute(const DeleteCardParams(
          cardId: cardId,
          deleteType: DeleteType.hard,
          trackMetrics: true,
        ));

        // Assert
        expect(result.metrics, isNotNull);
        expect(result.metrics!.totalProcessingTimeMs, greaterThanOrEqualTo(0));
        expect(result.metrics!.startTime.isBefore(result.metrics!.endTime), true);
      });
    });

    group('軟刪除功能', () {
      test('should soft delete card successfully', () async {
        // Arrange
        const cardId = 'card-soft-123';
        mockCardWriter.setMockSoftDeleteSuccess(true);

        // Act
        final result = await useCase.execute(const DeleteCardParams(
          cardId: cardId,
          deleteType: DeleteType.soft,
        ));

        // Assert
        expect(result.isSuccess, true);
        expect(result.deletedCardId, cardId);
        expect(result.deleteType, DeleteType.soft);
        expect(result.processingSteps, contains('軟刪除執行'));
        expect(result.isReversible, true);
      });

      test('should handle soft delete failure', () async {
        // Arrange
        const cardId = 'card-soft-fail';
        mockCardWriter.setMockSoftDeleteSuccess(false);

        // Act
        final result = await useCase.execute(const DeleteCardParams(
          cardId: cardId,
          deleteType: DeleteType.soft,
        ));

        // Assert
        expect(result.isSuccess, false);
        expect(result.hasWarnings, true);
      });

      test('should support restore functionality after soft delete', () async {
        // Arrange
        const cardId = 'card-restore';
        mockCardWriter.setMockRestoreSuccess(true);

        // Act
        final result = await useCase.executeRestore(const RestoreCardParams(
          cardId: cardId,
        ));

        // Assert
        expect(result.isSuccess, true);
        expect(result.restoredCardId, cardId);
        expect(result.processingSteps, contains('名片復原'));
      });

      test('should handle restore failure', () async {
        // Arrange
        const cardId = 'card-restore-fail';
        mockCardWriter.setMockRestoreSuccess(false);

        // Act
        final result = await useCase.executeRestore(const RestoreCardParams(
          cardId: cardId,
        ));

        // Assert
        expect(result.isSuccess, false);
        expect(result.hasWarnings, true);
        expect(result.warnings.first, contains('復原失敗'));
      });
    });

    group('批次刪除功能', () {
      test('should batch delete multiple cards successfully', () async {
        // Arrange
        final cardIds = ['card-1', 'card-2', 'card-3'];
        mockCardWriter.setMockDeleteResult(BatchDeleteResult(
          successful: cardIds,
          failed: [],
        ));

        // Act
        final results = await useCase.executeBatch(DeleteCardBatchParams(
          cardIds: cardIds,
          deleteType: DeleteType.hard,
        ));

        // Assert
        expect(results.successful.length, 3);
        expect(results.failed.length, 0);
        expect(results.successCount, 3);
        expect(results.hasFailures, false);
      });

      test('should handle partial batch deletion failures', () async {
        // Arrange
        final allCardIds = ['card-1', 'card-2', 'card-3'];
        final successfulIds = ['card-1', 'card-3'];
        final failedIds = ['card-2'];
        
        mockCardWriter.setMockDeleteResult(BatchDeleteResult(
          successful: successfulIds,
          failed: failedIds.map((id) => BatchOperationError(
            itemId: id,
            error: 'Delete failed for $id',
          )).toList(),
        ));

        // Act
        final results = await useCase.executeBatch(DeleteCardBatchParams(
          cardIds: allCardIds,
          deleteType: DeleteType.hard,
        ));

        // Assert
        expect(results.successful.length, 2);
        expect(results.failed.length, 1);
        expect(results.hasFailures, true);
        expect(results.failed.first.cardId, 'card-2');
      });

      test('should support concurrent batch processing', () async {
        // Arrange
        final cardIds = List.generate(10, (index) => 'card-$index');
        
        // Act
        final results = await useCase.executeBatch(DeleteCardBatchParams(
          cardIds: cardIds,
          deleteType: DeleteType.soft,
        ));

        // Assert
        expect(results.successful.length + results.failed.length, 10);
      });
    });

    group('清理功能', () {
      test('should purge old deleted cards successfully', () async {
        // Arrange
        const expectedPurgeCount = 5;
        mockCardWriter.setMockPurgeCount(expectedPurgeCount);

        // Act
        final result = await useCase.executePurge(const PurgeDeletedCardsParams(
          daysOld: 30,
        ));

        // Assert
        expect(result.purgedCount, expectedPurgeCount);
        expect(result.isSuccess, true);
        expect(result.processingSteps, contains('清理已刪除名片'));
      });

      test('should handle purge with custom retention period', () async {
        // Arrange
        const customDays = 90;
        const expectedPurgeCount = 10;
        mockCardWriter.setMockPurgeCount(expectedPurgeCount);

        // Act
        final result = await useCase.executePurge(const PurgeDeletedCardsParams(
          daysOld: customDays,
        ));

        // Assert
        expect(result.purgedCount, expectedPurgeCount);
        expect(result.daysOld, customDays);
      });

      test('should validate purge parameters', () async {
        // Arrange - 無效的保留天數
        const invalidDays = -1;

        // Act & Assert
        expect(
          () => useCase.executePurge(const PurgeDeletedCardsParams(
            daysOld: invalidDays,
          )),
          throwsA(isA<InvalidInputFailure>()),
        );
      });

      test('should track purge metrics when enabled', () async {
        // Arrange
        mockCardWriter.setMockPurgeCount(3);

        // Act
        final result = await useCase.executePurge(const PurgeDeletedCardsParams(
          daysOld: 30,
          trackMetrics: true,
        ));

        // Assert
        expect(result.metrics, isNotNull);
        expect(result.metrics!.totalProcessingTimeMs, greaterThanOrEqualTo(0));
      });
    });

    group('錯誤處理', () {
      test('should handle storage failure during deletion', () async {
        // Arrange
        mockCardWriter.setMockFailure(
          const StorageSpaceFailure(
            availableSpaceBytes: 0,
            requiredSpaceBytes: 1024,
            userMessage: '儲存空間不足',
          ),
        );

        // Act & Assert
        expect(
          () => useCase.execute(const DeleteCardParams(
            cardId: 'card-123',
            deleteType: DeleteType.hard,
          )),
          throwsA(isA<StorageSpaceFailure>()),
        );
      });

      test('should handle database connection failure', () async {
        // Arrange
        mockCardWriter.setMockFailure(
          const DatabaseConnectionFailure(
            userMessage: '資料庫連線失敗',
          ),
        );

        // Act & Assert
        expect(
          () => useCase.execute(const DeleteCardParams(
            cardId: 'card-123',
            deleteType: DeleteType.hard,
          )),
          throwsA(isA<DatabaseConnectionFailure>()),
        );
      });

      test('should handle card not found scenario', () async {
        // Arrange
        mockCardWriter.setMockFailure(
          const DataSourceFailure(
            userMessage: '找不到指定的名片',
            internalMessage: 'Card not found in database',
          ),
        );

        // Act & Assert
        expect(
          () => useCase.execute(const DeleteCardParams(
            cardId: 'non-existent-card',
            deleteType: DeleteType.hard,
          )),
          throwsA(isA<DataSourceFailure>()),
        );
      });

      test('should handle permission denied', () async {
        // Arrange
        mockCardWriter.setMockFailure(
          const DataSourceFailure(
            userMessage: '沒有刪除權限',
            internalMessage: 'Permission denied for delete operation',
          ),
        );

        // Act & Assert
        expect(
          () => useCase.execute(const DeleteCardParams(
            cardId: 'card-123',
            deleteType: DeleteType.hard,
          )),
          throwsA(isA<DataSourceFailure>()),
        );
      });
    });

    group('進階功能', () {
      test('should support dry run mode without actual deletion', () async {
        // Arrange
        const cardId = 'card-dryrun';

        // Act
        final result = await useCase.execute(const DeleteCardParams(
          cardId: cardId,
          deleteType: DeleteType.hard,
          dryRun: true,
        ));

        // Assert
        expect(result.processingSteps, contains('乾執行模式'));
        expect(result.processingSteps, isNot(contains('硬刪除執行')));
        // 在乾執行模式下，應該模擬成功但不實際執行
      });

      test('should validate deletion prerequisites', () async {
        // Arrange
        const cardId = 'card-with-dependencies';

        // Act
        final result = await useCase.execute(const DeleteCardParams(
          cardId: cardId,
          deleteType: DeleteType.hard,
          validateDependencies: true,
        ));

        // Assert
        expect(result.processingSteps, contains('依賴關係檢查'));
      });

      test('should provide deletion confirmation details', () async {
        // Arrange
        const cardId = 'card-details';

        // Act
        final result = await useCase.execute(const DeleteCardParams(
          cardId: cardId,
          deleteType: DeleteType.soft,
          includeDetails: true,
        ));

        // Assert
        expect(result.details, isNotNull);
        expect(result.details!.containsKey('deleteType'), true);
        expect(result.details!.containsKey('isReversible'), true);
      });

      test('should support custom retention policies', () async {
        // Arrange
        const cardId = 'card-custom-policy';

        // Act
        final result = await useCase.execute(const DeleteCardParams(
          cardId: cardId,
          deleteType: DeleteType.soft,
          customRetentionDays: 60,
        ));

        // Assert
        expect(result.processingSteps, contains('自訂保留政策'));
      });
    });

    group('效能與資源管理', () {
      test('should handle concurrent deletions efficiently', () async {
        // Arrange
        final futures = List.generate(5, (index) {
          return useCase.execute(DeleteCardParams(
            cardId: 'concurrent-card-$index',
            deleteType: DeleteType.soft,
            trackMetrics: true,
          ));
        });

        // Act
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, 5);
        for (final result in results) {
          expect(result.metrics, isNotNull);
        }
      });

      test('should cleanup resources properly', () async {
        // Arrange & Act
        final result = await useCase.execute(const DeleteCardParams(
          cardId: 'cleanup-test',
          deleteType: DeleteType.hard,
          autoCleanup: true,
        ));

        // Assert
        expect(result.processingSteps, contains('資源清理'));
      });

      test('should respect processing timeout', () async {
        // Arrange - 設定很短的超時時間
        mockCardWriter.setMockFailure(
          const DataSourceFailure(
            userMessage: '刪除操作超時',
            internalMessage: 'Processing timeout exceeded',
          ),
        );

        // Act & Assert
        expect(
          () => useCase.execute(const DeleteCardParams(
            cardId: 'timeout-test',
            deleteType: DeleteType.hard,
            timeout: Duration(milliseconds: 100),
          )),
          throwsA(isA<DataSourceFailure>()),
        );
      });

      test('should validate deletion within reasonable time', () async {
        // Arrange
        const cardId = 'performance-test';

        // Act
        final startTime = DateTime.now();
        final result = await useCase.execute(const DeleteCardParams(
          cardId: cardId,
          deleteType: DeleteType.soft,
          trackMetrics: true,
        ));
        final duration = DateTime.now().difference(startTime);

        // Assert
        expect(duration.inMilliseconds, lessThan(1000)); // < 1 秒
        expect(result.metrics!.totalProcessingTimeMs, lessThan(1000));
      });
    });
  });
}