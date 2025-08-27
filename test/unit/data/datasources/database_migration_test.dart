import 'package:flutter_test/flutter_test.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/clean_app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:matcher/matcher.dart' as matcher;

void main() {
  group('Database Migration Tests - photoPath Field', () {
    late CleanAppDatabase database;

    setUp(() {
      // 使用記憶體資料庫進行測試
      database = CleanAppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('should have photoPath field in BusinessCards table', () async {
      // Arrange - 使用自動遞增的 ID (不指定 ID)
      final testCard = BusinessCardsCompanion.insert(
        name: 'Test User',
        photoPath: const Value('/path/to/photo.jpg'),
      );

      // Act
      await database.cardDao.insertBusinessCard(testCard);
      final cards = await database.cardDao.getAllBusinessCards();

      // Assert
      expect(cards.length, 1);
      expect(cards.first.imagePath, '/path/to/photo.jpg');
    });

    test('should handle null photoPath correctly', () async {
      // Arrange
      final testCard = BusinessCardsCompanion.insert(
        name: 'User Without Photo',
        // photoPath 預設為 null
      );

      // Act
      await database.cardDao.insertBusinessCard(testCard);
      final cards = await database.cardDao.getAllBusinessCards();

      // Assert
      expect(cards.length, 1);
      expect(cards.first.imagePath, matcher.isNull);
    });

    test('should update photoPath correctly', () async {
      // Arrange - 先插入一筆沒有圖片的記錄
      final testCard = BusinessCardsCompanion.insert(name: 'Update Test User');

      final insertedId = await database.cardDao.insertBusinessCard(testCard);

      // Act - 使用實際的 ID 更新 photoPath
      final updateCompanion = BusinessCardsCompanion(
        id: Value(insertedId),
        photoPath: const Value('/new/photo/path.jpg'),
        updatedAt: Value(DateTime.now()),
      );

      // 需要透過實際的更新方法（檢查 CardDao 的 API）
      // 這裡假設使用 into().update() 方法
      await (database.businessCards.update()
            ..where((tbl) => tbl.id.equals(insertedId)))
          .write(updateCompanion);

      final cards = await database.cardDao.getAllBusinessCards();

      // Assert
      expect(cards.length, 1);
      expect(cards.first.imagePath, '/new/photo/path.jpg');
    });

    test('should have schema version 2', () {
      // Assert - 確認資料庫升級到版本 2 以支援 photoPath
      expect(database.schemaVersion, 2);
    });
  });
}
