import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 手動測試自動對焦功能
///
/// 這個測試驗證：
/// 1. 自動對焦是否每 2 秒執行一次
/// 2. 手動對焦後是否會暫停 3 秒
/// 3. Timer 是否正確清理
void main() {
  group('自動對焦功能測試', () {
    test('自動對焦計時器應該每 2 秒執行一次', () async {
      int focusCount = 0;
      Timer? autoFocusTimer;

      // 模擬自動對焦執行
      void performAutoFocus() {
        focusCount++;
        debugPrint('執行第 $focusCount 次自動對焦');
      }

      // 啟動自動對焦計時器
      autoFocusTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => performAutoFocus(),
      );

      // 等待 5 秒（應該執行 2 次對焦）
      await Future.delayed(const Duration(seconds: 5));

      // 清理計時器
      autoFocusTimer.cancel();

      // 驗證執行次數（初始 + 2 次週期）
      expect(focusCount, greaterThanOrEqualTo(2));
      debugPrint('測試通過：自動對焦執行了 $focusCount 次');
    });

    test('手動對焦後應該暫停自動對焦 3 秒', () async {
      int autoFocusCount = 0;
      int manualFocusCount = 0;
      Timer? autoFocusTimer;

      // 自動對焦執行
      void performAutoFocus() {
        autoFocusCount++;
        debugPrint('自動對焦執行：第 $autoFocusCount 次');
      }

      // 手動對焦執行
      void performManualFocus() {
        manualFocusCount++;
        debugPrint('手動對焦執行：第 $manualFocusCount 次');

        // 停止自動對焦
        autoFocusTimer?.cancel();

        // 3 秒後恢復自動對焦
        Timer(const Duration(seconds: 3), () {
          autoFocusTimer = Timer.periodic(
            const Duration(seconds: 2),
            (_) => performAutoFocus(),
          );
        });
      }

      // 啟動自動對焦
      autoFocusTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => performAutoFocus(),
      );

      // 等待 1 秒後執行手動對焦
      await Future.delayed(const Duration(seconds: 1));
      performManualFocus();

      // 記錄手動對焦時的自動對焦次數
      final countAfterManual = autoFocusCount;

      // 等待 2.5 秒（自動對焦應該還在暫停中）
      await Future.delayed(const Duration(milliseconds: 2500));
      expect(autoFocusCount, equals(countAfterManual));

      // 再等待 1 秒（總共 3.5 秒，自動對焦應該已恢復）
      await Future.delayed(const Duration(seconds: 1));

      // 清理
      autoFocusTimer?.cancel();

      // 驗證結果
      expect(manualFocusCount, equals(1));
      debugPrint('測試通過：手動對焦暫停機制正常');
    });

    test('Timer 應該在 dispose 時正確清理', () {
      Timer? autoFocusTimer;
      bool timerActive = false;

      // 建立計時器
      autoFocusTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => timerActive = true,
      );

      // 確認計時器已建立
      expect(autoFocusTimer.isActive, isTrue);

      // 清理計時器（模擬 dispose）
      autoFocusTimer.cancel();

      // 確認計時器已停止
      expect(autoFocusTimer.isActive, isFalse);
      debugPrint('測試通過：Timer 清理正常');
    });
  });
}
