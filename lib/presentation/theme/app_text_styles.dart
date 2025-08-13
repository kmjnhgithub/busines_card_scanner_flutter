import 'package:flutter/material.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';

/// 應用程式文字樣式系統
///
/// 提供一致的文字樣式定義，遵循 Material Design 3 和 iOS 設計規範
/// 適用於商務名片掃描應用，注重可讀性和專業感
/// 支援多種字重、尺寸和層次結構
class AppTextStyles {
  AppTextStyles._();

  // ==================== 字體定義 ====================

  /// 主要字體家族 - 系統字體，確保跨平台一致性
  static const String fontFamily = 'SF Pro Text'; // iOS 使用 SF Pro Text

  /// 展示字體家族 - 用於大標題和展示文字
  static const String displayFontFamily =
      'SF Pro Display'; // iOS 使用 SF Pro Display

  /// 等寬字體家族 - 用於代碼和數據展示
  static const String monospaceFontFamily = 'SF Mono';

  // ==================== 字重定義 ====================

  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // ==================== 標題樣式 (Headlines) ====================

  /// 大標題 - 用於主要頁面標題
  static const TextStyle headline1 = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 32.0,
    fontWeight: bold,
    letterSpacing: -0.5,
    height: 1.25,
    color: AppColors.primaryText,
  );

  /// 中標題 - 用於節區標題
  static const TextStyle headline2 = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 28.0,
    fontWeight: bold,
    letterSpacing: -0.25,
    height: 1.29,
    color: AppColors.primaryText,
  );

  /// 小標題 - 用於子節區標題
  static const TextStyle headline3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24.0,
    fontWeight: semiBold,
    letterSpacing: 0.0,
    height: 1.33,
    color: AppColors.primaryText,
  );

  /// 卡片標題 - 用於卡片和列表項標題
  static const TextStyle headline4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20.0,
    fontWeight: semiBold,
    letterSpacing: 0.0,
    height: 1.4,
    color: AppColors.primaryText,
  );

  /// 組件標題 - 用於小組件標題
  static const TextStyle headline5 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18.0,
    fontWeight: semiBold,
    letterSpacing: 0.15,
    height: 1.44,
    color: AppColors.primaryText,
  );

  /// 最小標題 - 用於表單標籤和小標題
  static const TextStyle headline6 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: medium,
    letterSpacing: 0.15,
    height: 1.5,
    color: AppColors.primaryText,
  );

  // ==================== 副標題樣式 (Subtitles) ====================

  /// 主副標題 - 用於重要的輔助資訊
  static const TextStyle subtitle1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: regular,
    letterSpacing: 0.15,
    height: 1.5,
    color: AppColors.primaryText,
  );

  /// 次副標題 - 用於一般的輔助資訊
  static const TextStyle subtitle2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.57,
    color: AppColors.secondaryText,
  );

  // ==================== 正文樣式 (Body Text) ====================

  /// 大正文 - 用於主要內容
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: regular,
    letterSpacing: 0.5,
    height: 1.5,
    color: AppColors.primaryText,
  );

  /// 中正文 - 用於一般內容
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: regular,
    letterSpacing: 0.25,
    height: 1.57,
    color: AppColors.primaryText,
  );

  /// 小正文 - 用於輔助內容
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.67,
    color: AppColors.secondaryText,
  );

  // ==================== 標籤樣式 (Labels) ====================

  /// 大標籤 - 用於按鈕文字
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: medium,
    letterSpacing: 1.25,
    height: 1.43,
    color: AppColors.primaryText,
  );

  /// 中標籤 - 用於標籤和小按鈕
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: medium,
    letterSpacing: 1.5,
    height: 1.67,
    color: AppColors.primaryText,
  );

  /// 小標籤 - 用於圖示標籤和輔助標籤
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10.0,
    fontWeight: medium,
    letterSpacing: 1.5,
    height: 1.6,
    color: AppColors.secondaryText,
  );

  // ==================== 特殊用途樣式 ====================

  /// 展示文字 - 用於重要數據展示
  static const TextStyle display = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 40.0,
    fontWeight: light,
    letterSpacing: -1.5,
    height: 1.2,
    color: AppColors.primaryText,
  );

  /// 超大文字 - 用於首頁或啟動頁面
  static const TextStyle gigantic = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 48.0,
    fontWeight: extraBold,
    letterSpacing: -2.0,
    height: 1.17,
    color: AppColors.primary,
  );

  /// 提示文字 - 用於 placeholder 和 hint
  static const TextStyle hint = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: regular,
    letterSpacing: 0.25,
    height: 1.57,
    color: AppColors.placeholder,
  );

  /// 錯誤文字 - 用於錯誤訊息
  static const TextStyle error = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.67,
    color: AppColors.error,
  );

  /// 成功文字 - 用於成功訊息
  static const TextStyle success = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.67,
    color: AppColors.success,
  );

  /// 警告文字 - 用於警告訊息
  static const TextStyle warning = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.67,
    color: AppColors.warning,
  );

  /// 等寬文字 - 用於代碼、ID 和結構化數據
  static const TextStyle monospace = TextStyle(
    fontFamily: monospaceFontFamily,
    fontSize: 14.0,
    fontWeight: regular,
    letterSpacing: 0.0,
    height: 1.57,
    color: AppColors.primaryText,
  );

  // ==================== 按鈕樣式 ====================

  /// 主要按鈕文字
  static const TextStyle primaryButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: semiBold,
    letterSpacing: 0.5,
    height: 1.25,
    color: Colors.white,
  );

  /// 次要按鈕文字
  static const TextStyle secondaryButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: semiBold,
    letterSpacing: 0.5,
    height: 1.25,
    color: AppColors.primary,
  );

  /// 文字按鈕
  static const TextStyle textButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: medium,
    letterSpacing: 1.25,
    height: 1.43,
    color: AppColors.primary,
  );

  // ==================== 輔助方法 ====================

  /// 根據主題亮度調整文字樣式
  static TextStyle adaptToTheme(TextStyle style, Brightness brightness) {
    if (brightness == Brightness.dark) {
      // 深色主題調整
      Color newColor;
      if (style.color == AppColors.primaryText) {
        newColor = AppColors.primaryTextDark;
      } else if (style.color == AppColors.secondaryText) {
        newColor = AppColors.secondaryTextDark;
      } else if (style.color == AppColors.placeholder) {
        newColor = AppColors.placeholderDark;
      } else {
        newColor = style.color ?? AppColors.primaryTextDark;
      }
      return style.copyWith(color: newColor);
    }
    return style;
  }

  /// 建立帶特定顏色的文字樣式
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// 建立帶特定字重的文字樣式
  static TextStyle withFontWeight(TextStyle style, FontWeight fontWeight) {
    return style.copyWith(fontWeight: fontWeight);
  }

  /// 建立帶特定字體大小的文字樣式
  static TextStyle withFontSize(TextStyle style, double fontSize) {
    return style.copyWith(fontSize: fontSize);
  }

  /// 建立帶透明度的文字樣式
  static TextStyle withOpacity(TextStyle style, double opacity) {
    final color = style.color ?? AppColors.primaryText;
    final alpha = (opacity * 255).round();
    return style.copyWith(
      color: color.withValues(alpha: alpha.toDouble() / 255),
    );
  }

  /// 建立禁用狀態的文字樣式
  static TextStyle disabled(TextStyle style) {
    return style.copyWith(color: AppColors.disabledText);
  }

  /// 建立深色主題的禁用文字樣式
  static TextStyle disabledDark(TextStyle style) {
    return style.copyWith(color: AppColors.disabledTextDark);
  }
}

/// 文字樣式常數
class AppTextConstants {
  AppTextConstants._();

  /// 標準行高倍數
  static const double lineHeightSmall = 1.2;
  static const double lineHeightMedium = 1.5;
  static const double lineHeightLarge = 1.8;

  /// 標準字間距
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingLoose = 1.0;
  static const double letterSpacingExtraLoose = 1.5;

  /// 段落間距
  static const double paragraphSpacing = 16.0;
  static const double sectionSpacing = 24.0;

  /// 文字截斷樣式
  static const TextOverflow defaultOverflow = TextOverflow.ellipsis;
  static const int maxLinesDefault = 2;
  static const int maxLinesLarge = 4;
}
