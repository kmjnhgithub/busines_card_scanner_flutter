import 'package:flutter_test/flutter_test.dart';
import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_writer.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/create_card_manually_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/core/errors/failures.dart';

/// Mock CardWriter 用於測試
class MockCardWriter implements CardWriter {
  BusinessCard? _mockSavedCard;
  BatchSaveResult? _mockBatchResult;
  BatchDeleteResult? _mockDeleteResult;
  Failure? _mockFailure;
  
  void setMockSavedCard(BusinessCard card) => _mockSavedCard = card;
  void setMockBatchResult(BatchSaveResult result) => _mockBatchResult = result;
  void setMockDeleteResult(BatchDeleteResult result) => _mockDeleteResult = result;
  void setMockFailure(Failure failure) => _mockFailure = failure;

  @override
  Future<BusinessCard> saveCard(BusinessCard card) async {
    if (_mockFailure != null) throw _mockFailure!;
    if (_mockSavedCard != null) {
      return _mockSavedCard!;
    }
    
    if (card.id.startsWith('temp-')) {
      return card.copyWith(
        id: 'saved-id-${DateTime.now().millisecondsSinceEpoch}',
      );
    }
    
    return card;
  }

  @override
  Future<BatchSaveResult> saveCards(List<BusinessCard> cards) async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockBatchResult ?? BatchSaveResult(
      successful: cards.map((card) => card.id.startsWith('temp-') 
        ? card.copyWith(id: 'saved-${DateTime.now().millisecondsSinceEpoch}') 
        : card).toList(),
      failed: [],
    );
  }

  @override
  Future<bool> deleteCard(String cardId) async {
    if (_mockFailure != null) throw _mockFailure!;
    return true;
  }

  @override
  Future<BatchDeleteResult> deleteCards(List<String> cardIds) async {
    if (_mockFailure != null) throw _mockFailure!;
    return _mockDeleteResult ?? BatchDeleteResult(
      successful: cardIds,
      failed: [],
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
    return true;
  }

  @override
  Future<bool> restoreCard(String cardId) async {
    if (_mockFailure != null) throw _mockFailure!;
    return true;
  }

  @override
  Future<int> purgeDeletedCards({int daysOld = 30}) async {
    if (_mockFailure != null) throw _mockFailure!;
    return 0;
  }
}

void main() {
  group('CreateCardManuallyUseCase Tests', () {
    late CreateCardManuallyUseCase useCase;
    late MockCardWriter mockCardWriter;

    setUp(() {
      mockCardWriter = MockCardWriter();
      useCase = CreateCardManuallyUseCase(mockCardWriter);
    });

    group('成功建立名片流程', () {
      test('should create card from manual input successfully', () async {
        // Arrange
        final manualData = ManualCardData(
          name: '王大明',
          company: '科技股份有限公司',
          jobTitle: '軟體工程師',
          email: 'wang@tech.com',
          phone: '02-1234-5678',
          address: '台北市信義區信義路五段7號',
          website: 'https://tech.com',
          notes: '重要客戶',
        );

        final expectedCard = BusinessCard(
          id: 'saved-card-123',
          name: '王大明',
          company: '科技股份有限公司',
          jobTitle: '軟體工程師',
          email: 'wang@tech.com',
          phone: '02-1234-5678',
          address: '台北市信義區信義路五段7號',
          website: 'https://tech.com',
          notes: '重要客戶',
          createdAt: DateTime.now(),
        );
        mockCardWriter.setMockSavedCard(expectedCard);

        // Act
        final result = await useCase.execute(CreateCardManuallyParams(
          manualData: manualData,
        ));

        // Assert
        expect(result.card.name, '王大明');
        expect(result.card.company, '科技股份有限公司');
        expect(result.card.jobTitle, '軟體工程師');
        expect(result.card.email, 'wang@tech.com');
        expect(result.card.phone, '02-1234-5678');
        expect(result.card.address, '台北市信義區信義路五段7號');
        expect(result.card.website, 'https://tech.com');
        expect(result.card.notes, '重要客戶');
        expect(result.card.id, 'saved-card-123');
        expect(result.processingSteps, contains('手動輸入驗證'));
        expect(result.processingSteps, contains('名片資料儲存'));
      });

      test('should create minimal card with only required fields', () async {
        // Arrange - 只有必填欄位
        final minimalData = ManualCardData(
          name: '李小華',
        );

        // Act
        final result = await useCase.execute(CreateCardManuallyParams(
          manualData: minimalData,
        ));

        // Assert
        expect(result.card.name, '李小華');
        expect(result.card.company, isNull);
        expect(result.card.jobTitle, isNull);
        expect(result.card.email, isNull);
        expect(result.card.phone, isNull);
        expect(result.card.address, isNull);
        expect(result.card.website, isNull);
        expect(result.card.notes, isNull);
      });

      test('should auto-format phone number when enabled', () async {
        // Arrange
        final dataWithPhone = ManualCardData(
          name: '張三',
          phone: '0912345678', // 未格式化的手機號碼
        );

        // Act
        final result = await useCase.execute(CreateCardManuallyParams(
          manualData: dataWithPhone,
          autoFormatPhone: true,
        ));

        // Assert
        expect(result.card.name, '張三');
        expect(result.processingSteps, contains('電話號碼格式化'));
      });

      test('should validate email format when provided', () async {
        // Arrange
        final dataWithEmail = ManualCardData(
          name: '陳小明',
          email: 'chen@example.com',
        );

        // Act
        final result = await useCase.execute(CreateCardManuallyParams(
          manualData: dataWithEmail,
        ));

        // Assert
        expect(result.card.email, 'chen@example.com');
        expect(result.hasWarnings, false);
      });

      test('should generate suggestions for incomplete data', () async {
        // Arrange
        final incompleteData = ManualCardData(
          name: '王工程師',
          company: '科技公司',
        );

        // Act
        final result = await useCase.execute(CreateCardManuallyParams(
          manualData: incompleteData,
          generateSuggestions: true,
        ));

        // Assert
        expect(result.card.name, '王工程師');
        expect(result.suggestions, isNotNull);
        expect(result.processingSteps, contains('資料補完建議'));
      });
    });

    group('輸入驗證', () {
      test('should reject empty name', () async {
        // Arrange
        final invalidData = ManualCardData(
          name: '',
          company: '公司名稱',
        );

        // Act & Assert
        expect(
          () => useCase.execute(CreateCardManuallyParams(
            manualData: invalidData,
          )),
          throwsA(isA<DataValidationFailure>()),
        );
      });

      test('should reject whitespace-only name', () async {
        // Arrange
        final invalidData = ManualCardData(
          name: '   \n\t   ',
        );

        // Act & Assert
        expect(
          () => useCase.execute(CreateCardManuallyParams(
            manualData: invalidData,
          )),
          throwsA(isA<DataValidationFailure>()),
        );
      });

      test('should validate email format', () async {
        // Arrange
        final invalidEmailData = ManualCardData(
          name: '王大明',
          email: 'invalid-email-format',
        );

        // Act
        final result = await useCase.execute(CreateCardManuallyParams(
          manualData: invalidEmailData,
        ));

        // Assert - 應該有警告而不是錯誤
        expect(result.hasWarnings, true);
        expect(result.warnings.first, startsWith('電子信箱格式'));
      });

      test('should validate phone format', () async {
        // Arrange
        final invalidPhoneData = ManualCardData(
          name: '王大明',
          phone: 'invalid-phone',
        );

        // Act
        final result = await useCase.execute(CreateCardManuallyParams(
          manualData: invalidPhoneData,
        ));

        // Assert - 應該有警告而不是錯誤
        expect(result.hasWarnings, true);
        expect(result.warnings.first, startsWith('電話號碼格式'));
      });

      test('should validate website URL format', () async {
        // Arrange
        final invalidWebsiteData = ManualCardData(
          name: '王大明',
          website: 'not-a-valid-url',
        );

        // Act
        final result = await useCase.execute(CreateCardManuallyParams(
          manualData: invalidWebsiteData,
        ));

        // Assert - 應該有警告而不是錯誤
        expect(result.hasWarnings, true);
        expect(result.warnings.first, startsWith('網站網址格式'));
      });

      test('should sanitize potentially malicious input', () async {
        // Arrange
        final maliciousData = ManualCardData(
          name: '王大明<script>alert("XSS")</script>',
          company: 'Company<img src=x onerror=alert("XSS")>',
        );

        // Act
        final result = await useCase.execute(CreateCardManuallyParams(
          manualData: maliciousData,
          enableSanitization: true,
        ));

        // Assert
        expect(result.card.name, isNot(contains('<script>')));
        expect(result.card.company, isNot(contains('<img')));
        expect(result.processingSteps, contains('資料清理'));
      });

      test('should limit field lengths', () async {
        // Arrange
        final longData = ManualCardData(
          name: 'A' * 500, // 超長名稱
          notes: 'B' * 2000, // 超長備註
        );

        // Act
        final result = await useCase.execute(CreateCardManuallyParams(
          manualData: longData,
        ));

        // Assert - 應該截斷過長的內容
        expect(result.card.name!.length, lessThanOrEqualTo(100));
        expect(result.card.notes!.length, lessThanOrEqualTo(1000));
        expect(result.hasWarnings, true);
      });
    });

    group('錯誤處理', () {
      test('should handle storage failure when saving card', () async {
        // Arrange
        final validData = ManualCardData(
          name: '王大明',
        );
        
        mockCardWriter.setMockFailure(
          const StorageSpaceFailure(
            availableSpaceBytes: 1024,
            requiredSpaceBytes: 2048,
            userMessage: '儲存空間不足',
          ),
        );

        // Act & Assert
        expect(
          () => useCase.execute(CreateCardManuallyParams(
            manualData: validData,
          )),
          throwsA(isA<StorageSpaceFailure>()),
        );
      });

      test('should handle database connection failure', () async {
        // Arrange
        final validData = ManualCardData(
          name: '王大明',
        );
        
        mockCardWriter.setMockFailure(
          const DatabaseConnectionFailure(
            userMessage: '資料庫連線失敗',
          ),
        );

        // Act & Assert
        expect(
          () => useCase.execute(CreateCardManuallyParams(
            manualData: validData,
          )),
          throwsA(isA<DatabaseConnectionFailure>()),
        );
      });

      test('should handle duplicate detection', () async {
        // Arrange
        final duplicateData = ManualCardData(
          name: '王大明',
          email: 'wang@tech.com',
        );

        // Act
        final result = await useCase.execute(CreateCardManuallyParams(
          manualData: duplicateData,
          checkDuplicates: true,
        ));

        // Assert - 應該檢查重複但不阻止建立
        expect(result.card.name, '王大明');
        expect(result.processingSteps, contains('重複檢查'));
      });
    });

    group('進階功能', () {
      test('should support dry run mode without saving', () async {
        // Arrange
        final testData = ManualCardData(
          name: '測試用戶',
          company: '測試公司',
        );

        // Act
        final dryRunResult = await useCase.execute(CreateCardManuallyParams(
          manualData: testData,
          dryRun: true,
        ));

        // Assert
        expect(dryRunResult.card.id, startsWith('temp-'));
        expect(dryRunResult.processingSteps, contains('乾執行模式'));
        expect(dryRunResult.processingSteps, isNot(contains('名片資料儲存')));
      });

      test('should track processing metrics when enabled', () async {
        // Arrange
        final testData = ManualCardData(
          name: '效能測試',
        );

        // Act
        final result = await useCase.execute(CreateCardManuallyParams(
          manualData: testData,
          trackMetrics: true,
        ));

        // Assert
        expect(result.metrics, isNotNull);
        expect(result.metrics!.totalProcessingTimeMs, greaterThanOrEqualTo(0));
        expect(result.metrics!.validationTimeMs, greaterThanOrEqualTo(0));
        expect(result.metrics!.startTime.isBefore(result.metrics!.endTime), true);
      });

      test('should batch create multiple cards', () async {
        // Arrange
        final cardsData = [
          ManualCardData(name: '王大明', company: '公司A'),
          ManualCardData(name: '李小華', company: '公司B'),
          ManualCardData(name: '張三', company: '公司C'),
        ];

        // Act
        final results = await useCase.executeBatch(CreateCardManuallyBatchParams(
          cardsData: cardsData,
        ));

        // Assert
        expect(results.successful.length, 3);
        expect(results.failed.length, 0);
        expect(results.successCount, 3);
        expect(results.hasFailures, false);
      });

      test('should handle partial batch creation failures', () async {
        // Arrange
        final cardsData = [
          ManualCardData(name: '王大明'), // 成功
          ManualCardData(name: ''), // 失敗 - 空名稱
          ManualCardData(name: '張三'), // 成功
        ];

        // Act
        final results = await useCase.executeBatch(CreateCardManuallyBatchParams(
          cardsData: cardsData,
        ));

        // Assert
        expect(results.successful.length, 2);
        expect(results.failed.length, 1);
        expect(results.failed.first.error, contains('DataValidationFailure'));
      });

      test('should import from various formats', () async {
        // Arrange
        final csvData = '''
名字,公司,職稱,電子信箱
王大明,科技公司,工程師,wang@tech.com
李小華,設計公司,設計師,li@design.com
''';

        // Act
        final results = await useCase.executeImport(CreateCardManuallyImportParams(
          importData: csvData,
          format: ImportFormat.csv,
        ));

        // Assert
        expect(results.successful.length, 2);
        expect(results.failed.length, 0);
        expect(results.successful.first.card.name, '王大明');
      });
    });

    group('效能與資源管理', () {
      test('should handle concurrent manual creations efficiently', () async {
        // Arrange
        final futures = List.generate(5, (index) {
          return useCase.execute(CreateCardManuallyParams(
            manualData: ManualCardData(
              name: '測試用戶 $index',
              company: '測試公司 $index',
            ),
            trackMetrics: true,
          ));
        });

        // Act
        final results = await Future.wait(futures);

        // Assert
        expect(results.length, 5);
        for (int i = 0; i < results.length; i++) {
          expect(results[i].card.name, contains('測試用戶'));
          expect(results[i].metrics, isNotNull);
        }
      });

      test('should cleanup resources properly', () async {
        // Arrange
        final testData = ManualCardData(
          name: '資源測試',
        );

        // Act
        final result = await useCase.execute(CreateCardManuallyParams(
          manualData: testData,
          autoCleanup: true,
        ));

        // Assert
        expect(result.processingSteps, contains('資源清理'));
      });

      test('should validate input within reasonable time', () async {
        // Arrange
        final complexData = ManualCardData(
          name: '複雜資料測試',
          company: '包含各種特殊字符的公司名稱 !@#\$%^&*()',
          email: 'complex.test.email+tag@sub.domain.example.com',
          phone: '+886-2-1234-5678 ext.123',
          address: '台北市信義區信義路五段7號35樓3501室',
          website: 'https://www.complex-domain-name.example.com/path?param=value',
          notes: '包含多行\n資料的\n備註內容',
        );

        // Act
        final startTime = DateTime.now();
        final result = await useCase.execute(CreateCardManuallyParams(
          manualData: complexData,
          trackMetrics: true,
        ));
        final duration = DateTime.now().difference(startTime);

        // Assert - 驗證應該在合理時間內完成
        expect(duration.inMilliseconds, lessThan(1000)); // < 1 秒
        expect(result.metrics!.totalProcessingTimeMs, lessThan(1000));
      });
    });
  });
}