// test/data/datasources/local/secure/enhanced_secure_storage_simple_test.dart

import 'package:busines_card_scanner_flutter/data/datasources/local/secure/enhanced_secure_storage.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('EnhancedSecureStorage', () {
    late EnhancedSecureStorage secureStorage;
    late MockFlutterSecureStorage mockFlutterSecureStorage;

    setUp(() {
      mockFlutterSecureStorage = MockFlutterSecureStorage();
      secureStorage = EnhancedSecureStorage(mockFlutterSecureStorage);
    });

    group('API Key 儲存和讀取測試', () {
      const testApiKey = 'sk-test1234567890abcdef1234567890abcdef';
      const testService = 'openai';

      test('🔴 RED: should store API key successfully', () async {
        // Arrange
        when(() => mockFlutterSecureStorage.write(
          key: any(named: 'key'), 
          value: any(named: 'value'),
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).thenAnswer((_) async => {});

        // Act
        final result = await secureStorage.storeApiKey(testService, testApiKey);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockFlutterSecureStorage.write(
          key: 'api_key_$testService',
          value: any(named: 'value'), // 加密後的值
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).called(1);
      });

      test('🔴 RED: should retrieve API key successfully', () async {
        // Arrange - 需要先加密一個測試值
        final encryptResult = await secureStorage.encryptData(testApiKey);
        expect(encryptResult.isRight(), isTrue);
        final encryptedValue = encryptResult.getOrElse(() => '');

        when(() => mockFlutterSecureStorage.read(
          key: any(named: 'key'),
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).thenAnswer((_) async => encryptedValue);

        // Act
        final result = await secureStorage.getApiKey(testService);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not return failure'),
          (apiKey) => expect(apiKey, equals(testApiKey)),
        );
      });

      test('🔴 RED: should return failure when API key not found', () async {
        // Arrange
        when(() => mockFlutterSecureStorage.read(
          key: any(named: 'key'),
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).thenAnswer((_) async => null);

        // Act
        final result = await secureStorage.getApiKey('nonexistent');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<DomainFailure>());
            expect(failure.userMessage, contains('not found'));
          },
          (apiKey) => fail('Should return failure'),
        );
      });

      test('🔴 RED: should delete API key successfully', () async {
        // Arrange
        when(() => mockFlutterSecureStorage.delete(
          key: any(named: 'key'),
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).thenAnswer((_) async => {});

        // Act
        final result = await secureStorage.deleteApiKey(testService);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockFlutterSecureStorage.delete(
          key: 'api_key_$testService',
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).called(1);
      });

      test('🔴 RED: should list stored API key services', () async {
        // Arrange
        when(() => mockFlutterSecureStorage.readAll(
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).thenAnswer((_) async => {
          'api_key_openai': 'encrypted_value_1',
          'api_key_anthropic': 'encrypted_value_2',
          'other_key': 'other_value',
        });

        // Act
        final result = await secureStorage.getStoredApiKeyServices();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not return failure'),
          (services) {
            expect(services, hasLength(2));
            expect(services, contains('openai'));
            expect(services, contains('anthropic'));
            expect(services, isNot(contains('other')));
          },
        );
      });
    });

    group('加密和解密功能測試', () {
      test('🔴 RED: should encrypt and decrypt data correctly', () async {
        // Arrange
        const plainText = 'sensitive_data_12345';

        // Act
        final encryptResult = await secureStorage.encryptData(plainText);
        
        expect(encryptResult.isRight(), isTrue);
        
        final encryptedData = encryptResult.getOrElse(() => '');
        final decryptResult = await secureStorage.decryptData(encryptedData);

        // Assert
        expect(decryptResult.isRight(), isTrue);
        decryptResult.fold(
          (failure) => fail('Decryption should succeed'),
          (decryptedText) => expect(decryptedText, equals(plainText)),
        );
      });

      test('🔴 RED: should handle empty string encryption', () async {
        // Act
        final result = await secureStorage.encryptData('');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<DomainFailure>());
            expect(failure.userMessage, contains('empty'));
          },
          (encrypted) => fail('Should return failure for empty string'),
        );
      });

      test('🔴 RED: should handle corrupted encrypted data gracefully', () async {
        // Arrange
        const corruptedData = 'corrupted_encrypted_data';

        // Act
        final result = await secureStorage.decryptData(corruptedData);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<DomainFailure>());
            expect(failure.userMessage, contains('integrity'));
          },
          (decrypted) => fail('Should return failure for corrupted data'),
        );
      });
    });

    group('驗證和安全性測試', () {
      test('🔴 RED: should validate API key format', () async {
        // Arrange
        const invalidApiKeys = [
          '', // 空字串
          'short', // 太短
          'invalid format with spaces', // 無效格式
        ];

        for (final invalidKey in invalidApiKeys) {
          // Act
          final result = await secureStorage.storeApiKey('test', invalidKey);

          // Assert
          expect(result.isLeft(), isTrue, reason: 'Invalid key: $invalidKey');
          result.fold(
            (failure) {
              expect(failure, isA<DomainFailure>());
              expect(failure.userMessage, contains('Invalid'));
            },
            (success) => fail('Should reject invalid API key: $invalidKey'),
          );
        }
      });

      test('🔴 RED: should validate service name format', () async {
        // Arrange
        const invalidServiceNames = [
          '', // 空字串
          '123', // 純數字
          'invalid service', // 包含空格
        ];

        for (final invalidService in invalidServiceNames) {
          // Act
          final result = await secureStorage.storeApiKey(invalidService, 'sk-validkey123');

          // Assert
          expect(result.isLeft(), isTrue, reason: 'Invalid service: $invalidService');
          result.fold(
            (failure) {
              expect(failure, isA<DomainFailure>());
              expect(failure.userMessage.toLowerCase(), contains('service name'));
            },
            (success) => fail('Should reject invalid service name: $invalidService'),
          );
        }
      });

      test('🔴 RED: should not log sensitive data in toString', () async {
        // Act
        final storageString = secureStorage.toString();

        // Assert - toString 不應該包含敏感資料
        expect(storageString, contains('EnhancedSecureStorage'));
        expect(storageString, isNot(contains('sk-')));
        expect(storageString, isNot(contains('secret')));
      });
    });

    group('錯誤處理測試', () {
      test('🔴 RED: should handle storage write failure gracefully', () async {
        // Arrange
        when(() => mockFlutterSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).thenThrow(Exception('Storage write failed'));

        // Act
        final result = await secureStorage.storeApiKey('test', 'sk-validkey123');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<DomainFailure>());
            expect(failure.userMessage, contains('Failed to store'));
          },
          (success) => fail('Should handle storage failure'),
        );
      });

      test('🔴 RED: should handle storage read failure gracefully', () async {
        // Arrange
        when(() => mockFlutterSecureStorage.read(
          key: any(named: 'key'),
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).thenThrow(Exception('Storage read failed'));

        // Act
        final result = await secureStorage.getApiKey('test');

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<DomainFailure>());
            expect(failure.userMessage, contains('Failed to retrieve'));
          },
          (apiKey) => fail('Should handle storage failure'),
        );
      });

      test('🔴 RED: should clear all API keys when requested', () async {
        // Arrange
        when(() => mockFlutterSecureStorage.readAll(
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).thenAnswer((_) async => {
          'api_key_openai': 'value1',
          'api_key_anthropic': 'value2',
          'other_key': 'value3',
        });

        when(() => mockFlutterSecureStorage.delete(
          key: any(named: 'key'),
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).thenAnswer((_) async => {});

        // Act
        final result = await secureStorage.clearAllApiKeys();

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockFlutterSecureStorage.delete(
          key: 'api_key_openai',
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).called(1);
        verify(() => mockFlutterSecureStorage.delete(
          key: 'api_key_anthropic',
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        )).called(1);
        verifyNever(() => mockFlutterSecureStorage.delete(
          key: 'other_key',
          aOptions: any(named: 'aOptions'),
          iOptions: any(named: 'iOptions'),
        ));
      });
    });

    group('加密演算法測試', () {
      test('🔴 RED: should produce different encrypted output for same input', () async {
        // Arrange
        const data = 'same_content';

        // Act
        final encrypted1 = await secureStorage.encryptData(data);
        final encrypted2 = await secureStorage.encryptData(data);

        // Assert - 相同內容應產生不同的加密結果（因為使用了隨機 IV）
        expect(encrypted1.isRight(), isTrue);
        expect(encrypted2.isRight(), isTrue);
        
        final enc1 = encrypted1.getOrElse(() => '');
        final enc2 = encrypted2.getOrElse(() => '');
        expect(enc1, isNot(equals(enc2))); // 應該不同
      });
    });
  });
}