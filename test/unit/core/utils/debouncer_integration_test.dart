import 'package:busines_card_scanner_flutter/core/utils/debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debouncer Integration Tests', () {
    test('搜尋防抖功能整合測試', () async {
      // Arrange
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
      var searchResults = <String>[];

      void simulateSearch(String query) {
        searchResults.add(query);
      }

      // Act - 模擬用戶快速輸入
      debouncer.run(() => simulateSearch('張'));
      debouncer.run(() => simulateSearch('張三'));
      debouncer.run(() => simulateSearch('張三豐'));

      // 等待防抖延遲
      await Future.delayed(const Duration(milliseconds: 150));

      // Assert - 只執行最後一次搜尋
      expect(searchResults, ['張三豐']);

      // Cleanup
      debouncer.dispose();
    });

    test('搜尋功能應該支援立即執行', () async {
      // Arrange
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
      var searchResults = <String>[];

      void simulateSearch(String query) {
        searchResults.add(query);
      }

      // Act - 設定防抖，然後立即執行
      debouncer.run(() => simulateSearch('延遲搜尋'));
      debouncer.runNow(() => simulateSearch('立即搜尋'));

      // 立即檢查結果
      expect(searchResults, ['立即搜尋']);

      // 等待防抖延遲，確認延遲搜尋被取消
      await Future.delayed(const Duration(milliseconds: 150));
      expect(searchResults, ['立即搜尋']); // 沒有新增項目

      // Cleanup
      debouncer.dispose();
    });

    test('多個 debouncer 實例應該獨立工作', () async {
      // Arrange
      final debouncer1 = Debouncer(delay: const Duration(milliseconds: 50));
      final debouncer2 = Debouncer(delay: const Duration(milliseconds: 100));
      var results1 = <String>[];
      var results2 = <String>[];

      // Act
      debouncer1.run(() => results1.add('搜尋1'));
      debouncer2.run(() => results2.add('搜尋2'));

      // 等待第一個 debouncer 完成
      await Future.delayed(const Duration(milliseconds: 75));
      expect(results1, ['搜尋1']);
      expect(results2, isEmpty);

      // 等待第二個 debouncer 完成
      await Future.delayed(const Duration(milliseconds: 50));
      expect(results2, ['搜尋2']);

      // Cleanup
      debouncer1.dispose();
      debouncer2.dispose();
    });
  });
}
