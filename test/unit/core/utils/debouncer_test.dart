import 'dart:async';
import 'package:busines_card_scanner_flutter/core/utils/debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debouncer Tests', () {
    late Debouncer debouncer;

    setUp(() {
      debouncer = Debouncer(delay: const Duration(milliseconds: 100));
    });

    tearDown(() {
      debouncer.dispose();
    });

    group('基本功能測試', () {
      test('應該在指定延遲後執行動作', () async {
        // Arrange
        var executionCount = 0;
        void testAction() {
          executionCount++;
        }

        // Act
        debouncer.run(testAction);

        // Assert - 立即檢查不應該執行
        expect(executionCount, 0);

        // Wait for debounce delay + buffer
        await Future.delayed(const Duration(milliseconds: 150));

        // Assert - 延遲後應該執行
        expect(executionCount, 1);
      });

      test('應該取消前一次操作並重新計時', () async {
        // Arrange
        var executionCount = 0;
        void testAction() {
          executionCount++;
        }

        // Act - 快速連續呼叫
        debouncer.run(testAction);
        await Future.delayed(const Duration(milliseconds: 50)); // 小於延遲時間
        debouncer.run(testAction);
        await Future.delayed(const Duration(milliseconds: 50)); // 小於延遲時間
        debouncer.run(testAction);

        // Assert - 等待完整延遲時間
        await Future.delayed(const Duration(milliseconds: 150));

        // 應該只執行最後一次
        expect(executionCount, 1);
      });

      test('應該能夠立即執行並取消計時器', () async {
        // Arrange
        var executionCount = 0;
        void testAction() {
          executionCount++;
        }

        // Act
        debouncer.run(testAction);
        debouncer.runNow(testAction);

        // Assert - 立即執行一次
        expect(executionCount, 1);

        // 等待延遲時間，不應該再次執行
        await Future.delayed(const Duration(milliseconds: 150));
        expect(executionCount, 1);
      });

      test('應該能夠取消當前的防抖操作', () async {
        // Arrange
        var executionCount = 0;
        void testAction() {
          executionCount++;
        }

        // Act
        debouncer.run(testAction);
        debouncer.cancel();

        // Assert
        await Future.delayed(const Duration(milliseconds: 150));
        expect(executionCount, 0);
      });
    });

    group('狀態檢查測試', () {
      test('isActive 應該正確反映計時器狀態', () async {
        // Arrange
        void testAction() {}

        // Act & Assert - 初始狀態
        expect(debouncer.isActive, false);

        // 啟動計時器
        debouncer.run(testAction);
        expect(debouncer.isActive, true);

        // 等待計時器完成
        await Future.delayed(const Duration(milliseconds: 150));
        expect(debouncer.isActive, false);
      });

      test('cancel 後 isActive 應該為 false', () {
        // Arrange
        void testAction() {}

        // Act
        debouncer.run(testAction);
        expect(debouncer.isActive, true);

        debouncer.cancel();
        expect(debouncer.isActive, false);
      });
    });

    group('資源管理測試', () {
      test('dispose 應該取消計時器', () {
        // Arrange
        void testAction() {}

        // Act
        debouncer.run(testAction);
        expect(debouncer.isActive, true);

        debouncer.dispose();

        // Assert
        expect(debouncer.isActive, false);
      });
    });

    group('預設值測試', () {
      test('應該使用預設延遲時間 300ms', () {
        // Arrange
        final defaultDebouncer = Debouncer();

        // Act & Assert
        expect(defaultDebouncer.delay, const Duration(milliseconds: 300));

        // Cleanup
        defaultDebouncer.dispose();
      });
    });
  });
}
