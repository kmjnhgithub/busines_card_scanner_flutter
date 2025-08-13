// test/data/datasources/local/app_database_test.dart

import 'dart:io';

import 'package:busines_card_scanner_flutter/data/datasources/local/clean_app_database.dart';
import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart' as matcher;

void main() {
  group('CleanAppDatabase', () {
    late CleanAppDatabase database;
    late Directory tempDir;

    setUp(() async {
      // 建立臨時測試資料庫
      tempDir = await Directory.systemTemp.createTemp('test_db');
      final testDbFile = File('${tempDir.path}/test.db');
      
      database = CleanAppDatabase(
        NativeDatabase(testDbFile),
      );
    });

    tearDown(() async {
      // 清理測試資源
      await database.close();
      await tempDir.delete(recursive: true);
    });

    group('資料庫初始化測試', () {
      test('🔴 RED: should create database tables successfully', () async {
        // Act - 確保資料庫已初始化
        await database.doWhenOpened((executor) async {});
        
        // Assert - 檢查資料表是否存在
        final tables = await database.customSelect(
          "SELECT name FROM sqlite_master WHERE type='table'",
        ).get();
        
        final tableNames = tables.map((row) => row.data['name'] as String).toList();
        expect(tableNames, contains('business_cards'));
      });

      test('🔴 RED: should have correct table schema for business_cards', () async {
        // Act
        final columns = await database.customSelect(
          'PRAGMA table_info(business_cards)',
        ).get();
        
        // Assert - 驗證資料表結構
        final columnNames = columns.map((row) => row.data['name'] as String).toList();
        
        // 必要欄位
        expect(columnNames, contains('id'));
        expect(columnNames, contains('name'));
        expect(columnNames, contains('created_at'));
        expect(columnNames, contains('updated_at'));
        
        // 選擇性欄位 (根據實際資料庫結構)
        expect(columnNames, contains('job_title'));
        expect(columnNames, contains('company'));
        expect(columnNames, contains('email'));
        expect(columnNames, contains('phone'));
        expect(columnNames, contains('address'));
        expect(columnNames, contains('website'));
        expect(columnNames, contains('notes'));
      });
    });

    group('CardDao 基本 CRUD 操作測試', () {
      test('🔴 RED: should insert business card successfully', () async {
        // Arrange
        final cardCompanion = BusinessCardsCompanion.insert(
          name: '張三',
          jobTitle: const Value('軟體工程師'),
          company: const Value('ABC公司'),
          email: const Value('zhang@abc.com'),
          phone: const Value('02-1234-5678'),
          createdAt: Value(DateTime(2024, 1, 15)),
          updatedAt: Value(DateTime(2024, 1, 15)),
        );

        // Act
        final insertedId = await database.cardDao.insertBusinessCard(cardCompanion);

        // Assert
        final retrievedCards = await database.cardDao.getAllBusinessCards();
        expect(retrievedCards, hasLength(1));
        expect(retrievedCards.first.id, equals(insertedId.toString()));
        expect(retrievedCards.first.name, equals('張三'));
        expect(retrievedCards.first.jobTitle, equals('軟體工程師'));
        expect(retrievedCards.first.company, equals('ABC公司'));
        expect(retrievedCards.first.email, equals('zhang@abc.com'));
      });

      test('🔴 RED: should get card by ID successfully', () async {
        // Arrange
        final cardCompanion = BusinessCardsCompanion.insert(
          name: '李四',
          company: const Value('XYZ公司'),
        );
        final insertedId = await database.cardDao.insertBusinessCard(cardCompanion);

        // Act
        final retrievedCard = await database.cardDao.getBusinessCardById(insertedId);

        // Assert
        expect(retrievedCard, matcher.isNotNull);
        expect(retrievedCard!.id, equals(insertedId.toString()));
        expect(retrievedCard.name, equals('李四'));
        expect(retrievedCard.company, equals('XYZ公司'));
      });

      test('🔴 RED: should return null when card not found', () async {
        // Act
        final retrievedCard = await database.cardDao.getBusinessCardById(99999); // 不存在的 ID

        // Assert
        expect(retrievedCard, matcher.isNull);
      });

      test('🔴 RED: should update existing card successfully', () async {
        // Arrange
        final originalCardCompanion = BusinessCardsCompanion.insert(
          name: '王五',
          company: const Value('原公司'),
          email: const Value('wang@original.com'),
          createdAt: Value(DateTime(2024, 1, 15)),
          updatedAt: Value(DateTime(2024, 1, 15)),
        );
        final insertedId = await database.cardDao.insertBusinessCard(originalCardCompanion);
        final originalCard = await database.cardDao.getBusinessCardById(insertedId);

        final updatedCard = BusinessCard(
          id: insertedId.toString(),
          name: '王五',
          company: '新公司',
          email: 'wang@new.com',
          createdAt: originalCard!.createdAt,
          updatedAt: DateTime(2024, 2),
        );

        // Act
        final success = await database.cardDao.updateBusinessCard(updatedCard);

        // Assert
        expect(success, isTrue);
        final retrievedCard = await database.cardDao.getBusinessCardById(insertedId);
        expect(retrievedCard!.company, equals('新公司'));
        expect(retrievedCard.email, equals('wang@new.com'));
        expect(retrievedCard.updatedAt?.isAfter(originalCard.updatedAt!), isTrue);
        expect(retrievedCard.createdAt, equals(originalCard.createdAt)); // 建立時間不變
      });

      test('🔴 RED: should delete card successfully', () async {
        // Arrange
        final cardCompanion = BusinessCardsCompanion.insert(
          name: '趙六',
        );
        final insertedId = await database.cardDao.insertBusinessCard(cardCompanion);
        
        // 確認卡片已插入
        final beforeDelete = await database.cardDao.getAllBusinessCards();
        expect(beforeDelete, hasLength(1));

        // Act
        final deleteResult = await database.cardDao.deleteBusinessCard(insertedId);

        // Assert
        expect(deleteResult, isTrue);
        final afterDelete = await database.cardDao.getAllBusinessCards();
        expect(afterDelete, isEmpty);
      });

      test('🔴 RED: should return false when deleting non-existent card', () async {
        // Act
        final deleteResult = await database.cardDao.deleteBusinessCard(99999); // 不存在的 ID

        // Assert
        expect(deleteResult, isFalse);
      });

      test('🔴 RED: should get all cards ordered by updated date', () async {
        // Arrange
        final card1 = BusinessCardsCompanion.insert(
          name: '最早的卡片',
          createdAt: Value(DateTime(2024)),
          updatedAt: Value(DateTime(2024)),
        );
        final card2 = BusinessCardsCompanion.insert(
          name: '中間的卡片',
          createdAt: Value(DateTime(2024, 1, 15)),
          updatedAt: Value(DateTime(2024, 1, 15)),
        );
        final card3 = BusinessCardsCompanion.insert(
          name: '最新的卡片',
          createdAt: Value(DateTime(2024, 2)),
          updatedAt: Value(DateTime(2024, 2)),
        );

        await database.cardDao.insertBusinessCard(card2);
        await database.cardDao.insertBusinessCard(card1);
        await database.cardDao.insertBusinessCard(card3);

        // Act
        final cards = await database.cardDao.getAllBusinessCards();

        // Assert
        expect(cards, hasLength(3));
        expect(cards[0].name, equals('最新的卡片')); // 最新的在前 (依 updatedAt 排序)
        expect(cards[1].name, equals('中間的卡片'));
        expect(cards[2].name, equals('最早的卡片'));
      });
    });

    group('CardDao 搜尋和過濾測試', () {
      setUp(() async {
        // 插入測試資料
        final testCards = [
          BusinessCardsCompanion.insert(
            name: '張三',
            company: const Value('ABC科技公司'),
            jobTitle: const Value('軟體工程師'),
            email: const Value('zhang.san@abc.com'),
            phone: const Value('02-1234-5678'),
            createdAt: Value(DateTime(2024)),
            updatedAt: Value(DateTime(2024)),
          ),
          BusinessCardsCompanion.insert(
            name: '李四',
            company: const Value('XYZ有限公司'),
            jobTitle: const Value('產品經理'),
            email: const Value('li.si@xyz.com'),
            phone: const Value('0912-345-678'),
            createdAt: Value(DateTime(2024, 1, 2)),
            updatedAt: Value(DateTime(2024, 1, 2)),
          ),
          BusinessCardsCompanion.insert(
            name: '王五',
            company: const Value('ABC科技公司'), // 同公司
            jobTitle: const Value('設計師'),
            email: const Value('wang.wu@abc.com'),
            createdAt: Value(DateTime(2024, 1, 3)),
            updatedAt: Value(DateTime(2024, 1, 3)),
          ),
        ];

        for (final card in testCards) {
          await database.cardDao.insertBusinessCard(card);
        }
      });

      test('🔴 RED: should search cards by name', () async {
        // Act
        final results = await database.cardDao.searchBusinessCards('張三');

        // Assert
        expect(results, hasLength(1));
        expect(results.first.name, equals('張三'));
      });

      test('🔴 RED: should search cards by company', () async {
        // Act
        final results = await database.cardDao.searchBusinessCards('ABC');

        // Assert
        expect(results, hasLength(2));
        expect(results.every((card) => card.company!.contains('ABC')), isTrue);
      });

      test('🔴 RED: should search cards case insensitive', () async {
        // Act
        final results1 = await database.cardDao.searchBusinessCards('abc');
        final results2 = await database.cardDao.searchBusinessCards('ABC');
        final results3 = await database.cardDao.searchBusinessCards('Abc');

        // Assert
        expect(results1, hasLength(2));
        expect(results2, hasLength(2));
        expect(results3, hasLength(2));
      });

      test('🔴 RED: should return empty list for non-matching search', () async {
        // Act
        final results = await database.cardDao.searchBusinessCards('不存在的關鍵字');

        // Assert
        expect(results, isEmpty);
      });
    });

    group('CardDao 錯誤處理和邊界條件測試', () {
      test('🔴 RED: should handle invalid operations gracefully', () async {
        // 測試更新不存在的記錄
        final nonExistentCard = BusinessCard(
          id: '99999',
          name: '不存在的卡片',
          createdAt: DateTime.now(),
        );

        // Act
        final updateResult = await database.cardDao.updateBusinessCard(nonExistentCard);

        // Assert
        expect(updateResult, isFalse);
      });

      test('🔴 RED: should handle very long text fields', () async {
        // Arrange
        final longNotesText = 'A' * 1000; // 1000個字符 - notes 限制1000
        final longAddressText = 'B' * 400; // 400個字符 - address 限制500
        final cardWithLongText = BusinessCardsCompanion.insert(
          name: '名字',
          notes: Value(longNotesText),
          address: Value(longAddressText),
        );

        // Act
        final insertedId = await database.cardDao.insertBusinessCard(cardWithLongText);
        final retrievedCard = await database.cardDao.getBusinessCardById(insertedId);

        // Assert
        expect(retrievedCard, matcher.isNotNull);
        expect(retrievedCard!.notes, equals(longNotesText));
        expect(retrievedCard.address, equals(longAddressText));
      });

      test('🔴 RED: should handle special characters in text fields', () async {
        // Arrange
        final cardWithSpecialChars = BusinessCardsCompanion.insert(
          name: '張三-Smith & Co. 🏢',
          company: const Value('ABC科技 (台灣) 有限公司 & Associates'),
          email: const Value('zhang.smith+test@abc-corp.com.tw'),
          notes: const Value('包含 "引號"、\'單引號\'、\\反斜線、\n換行符'),
        );

        // Act
        final insertedId = await database.cardDao.insertBusinessCard(cardWithSpecialChars);
        final retrievedCard = await database.cardDao.getBusinessCardById(insertedId);

        // Assert
        expect(retrievedCard, matcher.isNotNull);
        expect(retrievedCard!.name, equals('張三-Smith & Co. 🏢'));
        expect(retrievedCard.company, equals('ABC科技 (台灣) 有限公司 & Associates'));
        expect(retrievedCard.email, equals('zhang.smith+test@abc-corp.com.tw'));
        expect(retrievedCard.notes, contains('引號'));
        expect(retrievedCard.notes, contains('單引號'));
        expect(retrievedCard.notes, contains('反斜線'));
      });

      test('🔴 RED: should handle null values correctly', () async {
        // Arrange
        final minimalCard = BusinessCardsCompanion.insert(
          name: '最小資料卡片',
          // 其他欄位都是 null（使用預設值）
        );

        // Act
        final insertedId = await database.cardDao.insertBusinessCard(minimalCard);
        final retrievedCard = await database.cardDao.getBusinessCardById(insertedId);

        // Assert
        expect(retrievedCard, matcher.isNotNull);
        expect(retrievedCard!.name, equals('最小資料卡片'));
        expect(retrievedCard.jobTitle, matcher.isNull);
        expect(retrievedCard.company, matcher.isNull);
        expect(retrievedCard.email, matcher.isNull);
        expect(retrievedCard.phone, matcher.isNull);
      });
    });

    group('資料庫事務處理測試', () {
      test('🔴 RED: should support database transactions', () async {
        // Arrange
        final card1 = BusinessCardsCompanion.insert(
          name: '交易測試卡片1',
        );
        final card2 = BusinessCardsCompanion.insert(
          name: '交易測試卡片2',
        );

        // Act - 在事務中插入兩張卡片
        await database.transaction(() async {
          await database.cardDao.insertBusinessCard(card1);
          await database.cardDao.insertBusinessCard(card2);
        });

        // Assert
        final allCards = await database.cardDao.getAllBusinessCards();
        expect(allCards.where((card) => card.name.contains('交易測試卡片')), hasLength(2));
      });

      test('🔴 RED: should rollback transaction on error', () async {
        // Arrange
        final validCard = BusinessCardsCompanion.insert(
          name: '有效卡片',
        );

        // Act & Assert - 模擬事務中的錯誤
        expect(
          () => database.transaction(() async {
            await database.cardDao.insertBusinessCard(validCard);
            // 模擬一個會失敗的操作，例如插入無效資料
            throw Exception('模擬事務失敗');
          }),
          throwsA(isA<Exception>()),
        );

        // 驗證 rollback - 第一張卡片也不應該存在
        final allCards = await database.cardDao.getAllBusinessCards();
        expect(allCards.any((card) => card.name == '有效卡片'), isFalse);
      });
    });

    group('效能測試', () {
      test('🔴 RED: should handle bulk insert efficiently', () async {
        // Arrange
        final cards = List.generate(100, (index) => BusinessCardsCompanion.insert(
          name: '批量測試卡片$index',
          company: Value('Company${index % 10}'), // 10個不同公司
        ));

        final stopwatch = Stopwatch()..start();

        // Act
        await database.transaction(() async {
          for (final card in cards) {
            await database.cardDao.insertBusinessCard(card);
          }
        });

        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 100筆資料插入應在5秒內完成
        
        final retrievedCards = await database.cardDao.getAllBusinessCards(limit: 100);
        expect(retrievedCards.where((card) => card.name.contains('批量測試卡片')), hasLength(100));
      });

      test('🔴 RED: should handle large result set efficiently', () async {
        // Arrange - 先插入100筆測試資料
        final cards = List.generate(100, (index) => BusinessCardsCompanion.insert(
          name: '大資料集測試卡片$index',
          company: Value('Company${index % 10}'),
        ));

        await database.transaction(() async {
          for (final card in cards) {
            await database.cardDao.insertBusinessCard(card);
          }
        });

        final stopwatch = Stopwatch()..start();

        // Act
        final allCards = await database.cardDao.getAllBusinessCards(limit: 150);
        final searchResults = await database.cardDao.searchBusinessCards('大資料集測試');

        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 查詢應在1秒內完成
        expect(allCards.length, greaterThanOrEqualTo(100));
        expect(searchResults.length, greaterThanOrEqualTo(100));
      });
    });
  });
}