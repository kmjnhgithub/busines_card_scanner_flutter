import 'package:flutter/material.dart';

/// 掃描框計算工具類
/// 確保UI和裁剪功能使用完全相同的掃描框位置計算
class ScanFrameUtils {
  ScanFrameUtils._(); // 私有構造函數，防止實例化

  /// 計算掃描框在指定尺寸中的位置和大小
  ///
  /// [screenSize] 螢幕尺寸
  ///
  /// 回傳掃描框的 Rect
  static Rect calculateScanFrame(Size screenSize) {
    const aspectRatio = 1.618; // 名片的寬高比（黃金比例）
    final frameWidth = screenSize.width * 0.8;
    final frameHeight = frameWidth / aspectRatio;
    final frameLeft = (screenSize.width - frameWidth) / 2;
    final frameTop = (screenSize.height - frameHeight) / 2 - 50; // 稍微上移

    return Rect.fromLTWH(frameLeft, frameTop, frameWidth, frameHeight);
  }
}
