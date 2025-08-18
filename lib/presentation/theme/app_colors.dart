import 'package:flutter/material.dart';

/// 應用程式顏色系統
///
/// 提供一致的顏色定義，專注於淺色主題
/// 遵循 Material Design 3 和 iOS 設計規範
/// 適用於商務名片掃描應用的專業風格
class AppColors {
  AppColors._();

  // ==================== 品牌色彩 ====================

  /// 主要品牌色 - iOS Blue，傳達專業與信任
  static const Color primary = Color(0xFF007AFF);

  /// 主要品牌色的變體
  static const Color primaryVariant = Color(0xFF0056CC);

  /// 次要品牌色 - Purple，用於強調和輔助元素
  static const Color secondary = Color(0xFF5856D6);

  /// 次要品牌色的變體
  static const Color secondaryVariant = Color(0xFF4339A3);

  // ==================== 語義顏色 ====================

  /// 成功狀態色 - Green
  static const Color success = Color(0xFF34C759);

  /// 成功狀態色的淺色變體
  static const Color successLight = Color(0xFFE8F5E8);

  /// 警告狀態色 - Orange
  static const Color warning = Color(0xFFFF9500);

  /// 警告狀態色的淺色變體
  static const Color warningLight = Color(0xFFFFF4E5);

  /// 錯誤狀態色 - Red
  static const Color error = Color(0xFFFF3B30);

  /// 錯誤狀態色的淺色變體
  static const Color errorLight = Color(0xFFFFEDEC);

  /// 資訊狀態色 - Blue
  static const Color info = Color(0xFF007AFF);

  /// 資訊狀態色的淺色變體
  static const Color infoLight = Color(0xFFE5F3FF);

  // ==================== 背景顏色 ====================

  /// 主背景色 - 淺灰色，營造乾淨的視覺效果
  static const Color background = Color(0xFFF2F2F7);

  /// 卡片背景色 - 純白，突出內容
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// 次要背景色 - 用於分組和區域劃分
  static const Color secondaryBackground = Color(0xFFE5E5EA);

  /// 表面色 - 用於元件表面
  static const Color surface = Color(0xFFFFFFFF);

  // ==================== 文字顏色 ====================

  /// 主要文字色 - 90% 黑色，確保良好的可讀性
  static const Color primaryText = Color(0xE6000000);

  /// 次要文字色 - 60% 黑色，用於輔助資訊
  static const Color secondaryText = Color(0x99000000);

  /// 預留位置文字色 - 用於 placeholder 和 hint
  static const Color placeholder = Color(0xFF8E8E93);

  /// 禁用文字色
  static const Color disabledText = Color(0x42000000);

  // ==================== 邊框與分隔線 ====================

  /// 分隔線色 - 用於分隔不同區域
  static const Color separator = Color(0xFFC6C6C8);

  /// 邊框色 - 用於輸入框、按鈕等元件邊框
  static const Color border = Color(0xFFE5E5EA);

  /// 焦點邊框色 - 當元件獲得焦點時使用
  static const Color focusBorder = primary;

  // ==================== 特殊用途顏色 ====================

  /// 掃描框邊框色 - 黃色，在相機預覽中顯眼
  static const Color scannerFrame = Color(0xFFFFCC00);

  /// 掃描覆蓋層色 - 40% 黑色，用於相機預覽遮罩
  static const Color scannerOverlay = Color(0x66000000);

  /// 陰影色 - 用於卡片和元件陰影
  static const Color shadow = Color(0x1A000000);

  /// 高光色 - 用於按鈕按下狀態
  static const Color highlight = Color(0x1F000000);

  /// 選中狀態色
  static const Color selection = Color(0x3D007AFF);

  // ==================== 漸變色定義 ====================

  /// 主要漸變 - 用於按鈕和重要元素
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 次要漸變 - 用於輔助元素
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 成功漸變
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF28A745)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== 輔助方法 ====================

  /// 獲取文字顏色（淺色模式專用）
  static Color getTextColor(Brightness brightness) {
    return primaryText;
  }

  /// 獲取背景顏色（淺色模式專用）
  static Color getBackgroundColor(Brightness brightness) {
    return background;
  }

  /// 獲取卡片背景顏色（淺色模式專用）
  static Color getCardBackgroundColor(Brightness brightness) {
    return cardBackground;
  }

  /// 獲取邊框顏色（淺色模式專用）
  static Color getBorderColor(Brightness brightness) {
    return border;
  }

  /// 獲取帶透明度的顏色
  static Color withOpacity(Color color, double opacity) {
    final alpha = (opacity * 255).round();
    return color.withValues(alpha: alpha.toDouble() / 255);
  }

  /// 獲取顏色的淺色變體
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(
      amount >= 0 && amount <= 1,
      'Lighten amount must be between 0.0 and 1.0, got: $amount',
    );
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }

  /// 獲取顏色的深色變體
  static Color darken(Color color, [double amount = 0.1]) {
    assert(
      amount >= 0 && amount <= 1,
      'Darken amount must be between 0.0 and 1.0, got: $amount',
    );
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

/// 顏色系統常數
class AppColorConstants {
  AppColorConstants._();

  /// 標準不透明度值
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.87;
  static const double opacityOverlay = 0.4;

  /// 標準圓角半徑（用於有顏色的元件）
  static const double radiusSmall = 4;
  static const double radiusMedium = 8;
  static const double radiusLarge = 12;
  static const double radiusExtraLarge = 16;
}
