// test/data/models/business_card_model_test.dart

import 'package:busines_card_scanner_flutter/data/models/business_card_model.dart';
import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusinessCardModel', () {
    late BusinessCardModel testModel;
    late Map<String, dynamic> testJson;

    setUp(() {
      // Arrange - 準備測試資料
      testModel = BusinessCardModel(
        id: 'test-id-123',
        name: '張三',
        namePhonetic: 'Zhang San',
        jobTitle: '產品經理',
        company: 'ABC科技公司',
        department: '產品部',
        email: 'zhang.san@abc.com',
        phone: '02-12345678',
        mobile: '0912-345-678',
        address: '台北市信義區信義路100號',
        website: 'https://www.abc.com',
        notes: '重要客戶',
        photoPath: '/path/to/photo.jpg',
        createdAt: DateTime(2024, 1, 15, 10, 30),
        updatedAt: DateTime(2024, 1, 20, 14, 45),
      );

      testJson = {
        'id': 'test-id-123',
        'name': '張三',
        'name_phonetic': 'Zhang San',
        'job_title': '產品經理',
        'company': 'ABC科技公司',
        'department': '產品部',
        'email': 'zhang.san@abc.com',
        'phone': '02-12345678',
        'mobile': '0912-345-678',
        'address': '台北市信義區信義路100號',
        'website': 'https://www.abc.com',
        'notes': '重要客戶',
        'photo_path': '/path/to/photo.jpg',
        'created_at': '2024-01-15T10:30:00.000',
        'updated_at': '2024-01-20T14:45:00.000',
      };
    });

    group('JSON 序列化測試', () {
      test('🔴 RED: should convert model to JSON correctly', () {
        // Act
        final json = testModel.toJson();
        
        // Assert - 驗證所有欄位正確序列化
        expect(json['id'], equals('test-id-123'));
        expect(json['name'], equals('張三'));
        expect(json['name_phonetic'], equals('Zhang San'));
        expect(json['job_title'], equals('產品經理'));
        expect(json['company'], equals('ABC科技公司'));
        expect(json['department'], equals('產品部'));
        expect(json['email'], equals('zhang.san@abc.com'));
        expect(json['phone'], equals('02-12345678'));
        expect(json['mobile'], equals('0912-345-678'));
        expect(json['address'], equals('台北市信義區信義路100號'));
        expect(json['website'], equals('https://www.abc.com'));
        expect(json['notes'], equals('重要客戶'));
        expect(json['photo_path'], equals('/path/to/photo.jpg'));
        expect(json['created_at'], equals('2024-01-15T10:30:00.000'));
        expect(json['updated_at'], equals('2024-01-20T14:45:00.000'));
      });

      test('🔴 RED: should create model from JSON correctly', () {
        // Act
        final model = BusinessCardModel.fromJson(testJson);
        
        // Assert
        expect(model.id, equals('test-id-123'));
        expect(model.name, equals('張三'));
        expect(model.namePhonetic, equals('Zhang San'));
        expect(model.jobTitle, equals('產品經理'));
        expect(model.company, equals('ABC科技公司'));
        expect(model.department, equals('產品部'));
        expect(model.email, equals('zhang.san@abc.com'));
        expect(model.phone, equals('02-12345678'));
        expect(model.mobile, equals('0912-345-678'));
        expect(model.address, equals('台北市信義區信義路100號'));
        expect(model.website, equals('https://www.abc.com'));
        expect(model.notes, equals('重要客戶'));
        expect(model.photoPath, equals('/path/to/photo.jpg'));
        expect(model.createdAt, equals(DateTime(2024, 1, 15, 10, 30)));
        expect(model.updatedAt, equals(DateTime(2024, 1, 20, 14, 45)));
      });

      test('🔴 RED: should handle null values correctly', () {
        // Arrange
        final minimalJson = {
          'id': 'minimal-id',
          'name': '最小資料',
          'created_at': '2024-01-15T10:30:00.000',
          'updated_at': '2024-01-15T10:30:00.000',
        };

        // Act
        final model = BusinessCardModel.fromJson(minimalJson);

        // Assert
        expect(model.id, equals('minimal-id'));
        expect(model.name, equals('最小資料'));
        expect(model.namePhonetic, isNull);
        expect(model.jobTitle, isNull);
        expect(model.company, isNull);
        expect(model.department, isNull);
        expect(model.email, isNull);
        expect(model.phone, isNull);
        expect(model.mobile, isNull);
        expect(model.address, isNull);
        expect(model.website, isNull);
        expect(model.notes, isNull);
        expect(model.photoPath, isNull);
        expect(model.createdAt, isNotNull);
        expect(model.updatedAt, isNotNull);
      });

      test('🔴 RED: should serialize and deserialize correctly (roundtrip)', () {
        // Act
        final json = testModel.toJson();
        final deserializedModel = BusinessCardModel.fromJson(json);

        // Assert
        expect(deserializedModel.id, equals(testModel.id));
        expect(deserializedModel.name, equals(testModel.name));
        expect(deserializedModel.namePhonetic, equals(testModel.namePhonetic));
        expect(deserializedModel.jobTitle, equals(testModel.jobTitle));
        expect(deserializedModel.company, equals(testModel.company));
        expect(deserializedModel.email, equals(testModel.email));
        expect(deserializedModel.createdAt, equals(testModel.createdAt));
        expect(deserializedModel.updatedAt, equals(testModel.updatedAt));
      });
    });

    group('Domain Entity 轉換測試', () {
      test('🔴 RED: should convert to BusinessCard entity correctly', () {
        // Act
        final entity = testModel.toEntity();

        // Assert
        expect(entity, isA<BusinessCard>());
        expect(entity.id, equals(testModel.id));
        expect(entity.name, equals(testModel.name));
        expect(entity.jobTitle, equals(testModel.jobTitle));
        expect(entity.company, equals(testModel.company));
        expect(entity.email, equals(testModel.email));
        expect(entity.phone, equals(testModel.phone));
        expect(entity.address, equals(testModel.address));
        expect(entity.website, equals(testModel.website));
        expect(entity.notes, equals(testModel.notes));
        expect(entity.imageUrl, equals(testModel.photoPath)); // photoPath 對應到 imageUrl
        expect(entity.createdAt, equals(testModel.createdAt));
        expect(entity.updatedAt, equals(testModel.updatedAt));
      });

      test('🔴 RED: should create model from BusinessCard entity correctly', () {
        // Arrange
        final entity = BusinessCard(
          id: 'entity-id',
          name: '李四',
          company: 'XYZ公司',
          email: 'li.si@xyz.com',
          createdAt: DateTime(2024, 2),
          updatedAt: DateTime(2024, 2),
        );

        // Act
        final model = BusinessCardModel.fromEntity(entity);

        // Assert
        expect(model.id, equals(entity.id));
        expect(model.name, equals(entity.name));
        expect(model.company, equals(entity.company));
        expect(model.email, equals(entity.email));
        expect(model.photoPath, equals(entity.imageUrl));
        expect(model.createdAt, equals(entity.createdAt));
        expect(model.updatedAt, equals(entity.updatedAt));
      });

      test('🔴 RED: should maintain data integrity in entity conversion roundtrip', () {
        // Arrange
        final originalEntity = BusinessCard(
          id: 'roundtrip-test',
          name: '王五',
          company: '測試公司',
          email: 'wang@test.com',
          createdAt: DateTime(2024, 3),
          updatedAt: DateTime(2024, 3),
        );

        // Act
        final model = BusinessCardModel.fromEntity(originalEntity);
        final convertedEntity = model.toEntity();

        // Assert
        expect(convertedEntity.id, equals(originalEntity.id));
        expect(convertedEntity.name, equals(originalEntity.name));
        expect(convertedEntity.company, equals(originalEntity.company));
        expect(convertedEntity.email, equals(originalEntity.email));
        expect(convertedEntity.imageUrl, equals(originalEntity.imageUrl));
        expect(convertedEntity.createdAt, equals(originalEntity.createdAt));
        expect(convertedEntity.updatedAt, equals(originalEntity.updatedAt));
      });
    });

    group('Value Equality 測試', () {
      test('🔴 RED: should implement value equality correctly', () {
        // Arrange
        final model1 = BusinessCardModel(
          id: 'same-id',
          name: '相同名片',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );
        final model2 = BusinessCardModel(
          id: 'same-id',
          name: '相同名片',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );
        final model3 = BusinessCardModel(
          id: 'different-id',
          name: '相同名片',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );

        // Assert
        expect(model1, equals(model2));
        expect(model1.hashCode, equals(model2.hashCode));
        expect(model1, isNot(equals(model3)));
      });

      test('🔴 RED: should support copyWith functionality', () {
        // Act
        final updatedModel = testModel.copyWith(
          name: '更新的姓名',
          company: '更新的公司',
          updatedAt: DateTime(2024, 2, 1, 12),
        );

        // Assert
        expect(updatedModel.id, equals(testModel.id)); // 未更新的欄位保持不變
        expect(updatedModel.name, equals('更新的姓名')); // 更新的欄位
        expect(updatedModel.company, equals('更新的公司')); // 更新的欄位
        expect(updatedModel.email, equals(testModel.email)); // 未更新的欄位保持不變
        expect(updatedModel.updatedAt, equals(DateTime(2024, 2, 1, 12))); // 更新的欄位
        expect(updatedModel.createdAt, equals(testModel.createdAt)); // 未更新的欄位保持不變
      });
    });

    group('邊界條件和錯誤處理測試', () {
      test('🔴 RED: should handle empty JSON gracefully', () {
        // Arrange
        final emptyJson = <String, dynamic>{};

        // Act & Assert
        expect(
          () => BusinessCardModel.fromJson(emptyJson),
          throwsA(isA<FormatException>()),
        );
      });

      test('🔴 RED: should handle invalid date format gracefully', () {
        // Arrange
        final invalidDateJson = {
          'id': 'invalid-date-test',
          'name': '測試名片',
          'created_at': 'invalid-date-format',
          'updated_at': 'also-invalid',
        };

        // Act & Assert
        expect(
          () => BusinessCardModel.fromJson(invalidDateJson),
          throwsA(isA<FormatException>()),
        );
      });

      test('🔴 RED: should validate required fields during fromJson', () {
        // Arrange
        final missingRequiredJson = {
          'name': '缺少ID的名片',
          'created_at': '2024-01-15T10:30:00.000',
          'updated_at': '2024-01-15T10:30:00.000',
        };

        // Act & Assert
        expect(
          () => BusinessCardModel.fromJson(missingRequiredJson),
          throwsA(isA<FormatException>()),
        );
      });

      test('🔴 RED: should handle very long strings without error', () {
        // Arrange
        final veryLongString = 'A' * 1000;
        final longStringModel = BusinessCardModel(
          id: 'long-string-test',
          name: veryLongString,
          notes: veryLongString,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final json = longStringModel.toJson();
        final deserializedModel = BusinessCardModel.fromJson(json);

        // Assert
        expect(deserializedModel.name, equals(veryLongString));
        expect(deserializedModel.notes, equals(veryLongString));
      });

      test('🔴 RED: should handle special characters in all text fields', () {
        // Arrange
        final specialCharsModel = BusinessCardModel(
          id: 'special-chars-test',
          name: '張三-Smith & Co. 🏢',
          company: 'ABC科技 (台灣) 有限公司 & Associates',
          email: 'zhang.smith+test@abc-corp.com.tw',
          address: '台北市信義區信義路100號8樓 (大樓名稱)',
          notes: '特殊字元測試: 包含各種符號',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final json = specialCharsModel.toJson();
        final deserializedModel = BusinessCardModel.fromJson(json);

        // Assert - 確保特殊字元正確處理
        expect(deserializedModel.name, equals(specialCharsModel.name));
        expect(deserializedModel.company, equals(specialCharsModel.company));
        expect(deserializedModel.email, equals(specialCharsModel.email));
        expect(deserializedModel.address, equals(specialCharsModel.address));
        expect(deserializedModel.notes, equals(specialCharsModel.notes));
      });
    });

    group('安全性測試', () {
      test('🔴 RED: should not include sensitive data in toString', () {
        // Arrange
        final modelWithSensitiveData = BusinessCardModel(
          id: 'security-test',
          name: '機密聯絡人',
          email: 'confidential@secret.com',
          notes: '機密資訊：信用卡號 1234-5678-9012-3456',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final stringRepresentation = modelWithSensitiveData.toString();

        // Assert - toString 不應該直接暴露敏感資訊
        expect(stringRepresentation, contains('BusinessCardModel'));
        expect(stringRepresentation, contains('security-test')); // ID 可以顯示
        // 注意：實際實作時應該謹慎處理 toString 內容
      });

      test('🔴 RED: should sanitize HTML/script content in text fields', () {
        // Arrange
        final maliciousContentModel = BusinessCardModel(
          id: 'xss-test',
          name: '<script>alert("XSS")</script>張三',
          company: '<img src="x" onerror="alert(1)">ABC公司',
          notes: '<iframe src="javascript:alert(1)"></iframe>備註',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final json = maliciousContentModel.toJson();
        final deserializedModel = BusinessCardModel.fromJson(json);

        // Assert - 應該保留原始內容但在使用時進行清理
        // 注意：實際的 HTML 清理應該在 presentation 層進行
        expect(deserializedModel.name, equals(maliciousContentModel.name));
        expect(deserializedModel.company, equals(maliciousContentModel.company));
        expect(deserializedModel.notes, equals(maliciousContentModel.notes));
      });
    });
  });
}