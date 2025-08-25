import 'dart:ui';

/// 響應式設計系統
///
/// 基於 iOS Swift 版本的響應式佈局系統
/// 確保在不同螢幕尺寸上都有一致的視覺體驗
/// 參考：iOS BusinessCardScanner AppTheme.Layout.ResponsiveLayout
class AppResponsive {
  AppResponsive._();

  // ==================== 名片列表響應式規範 ====================
}

/// 名片列表響應式設計系統
class AppResponsiveCardList {
  AppResponsiveCardList._();

  /// Cell 高度比例（螢幕高度的 12%）
  /// 對齊 iOS 版本設計規範
  static const double cellHeightRatio = 0.12;

  /// 圖片黃金比例設定
  /// 高度相對於寬度的比例（寬:高 = 1:0.618）
  static const double imageAspectRatio = 0.618;

  /// 寬度相對於高度的比例（寬度 = 高度 × 1.618）
  static const double imageWidthToHeightRatio = 1.618;

  /// 圖片與文字間距
  static const double imageToTextSpacing = 12;

  /// 文字行間距
  static const double nameToCompanySpacing = 6;
  static const double companyToJobTitleSpacing = 4;

  /// 容器上下邊距
  static const double verticalMargin = 8;

  /// 容器內部間距
  static const double containerPadding = 2;

  /// 圖片圓角
  static const double imageCornerRadius = 8;

  /// 職稱固定高度
  static const double jobTitleHeight = 18;

  // ==================== 響應式計算方法 ====================

  /// 計算當前螢幕的最佳 Cell 高度
  /// 返回螢幕高度的 12%
  static double calculateCellHeight(double screenHeight) {
    return screenHeight * cellHeightRatio;
  }

  /// 計算容器高度（扣除上下邊距）
  static double calculateContainerHeight(double cellHeight) {
    return cellHeight - (verticalMargin * 2);
  }

  /// 計算圖片尺寸（基於容器高度和黃金比例）
  /// 返回 Size(width, height)
  static Size calculateImageSize(double containerHeight) {
    final imageHeight = containerHeight;
    final imageWidth = imageHeight * imageWidthToHeightRatio;
    return Size(imageWidth, imageHeight);
  }

  /// 根據螢幕尺寸獲取最佳圖片寬度占比
  /// 對齊 iOS 版本的響應式優化邏輯
  static double getImageWidthRatio(double screenWidth) {
    if (screenWidth < 375) {
      // 小螢幕 (iPhone SE, Mini 等)
      return 0.42; // 42% - 給文字更多空間
    } else if (screenWidth < 430) {
      // 標準螢幕 (iPhone 14, 15 等)
      return 0.45; // 45% - 平衡占比
    } else {
      // 大螢幕 (iPhone Pro Max, Android 大螢幕等)
      return 0.48; // 48% - 圖片可以稍大
    }
  }

  /// 計算響應式優化的圖片尺寸
  /// 基於螢幕尺寸和 Cell 寬度，提供更好的名片顯示效果
  static Size calculateResponsiveImageSize({
    required double containerHeight,
    required double containerWidth,
    required double screenWidth,
  }) {
    // 根據螢幕尺寸獲取最佳圖片寬度占比
    final widthRatio = getImageWidthRatio(screenWidth);

    // 計算目標圖片寬度
    final targetImageWidth = containerWidth * widthRatio;

    // 根據黃金比例計算對應的高度（寬:高 = 1:0.618）
    final imageHeightFromWidth = targetImageWidth * imageAspectRatio;

    // 確保不超過容器高度（遵循設計規範）
    final maxImageHeight = containerHeight;
    final finalImageHeight = imageHeightFromWidth.clamp(0.0, maxImageHeight);

    // 重新計算寬度，確保比例正確（寬度 = 高度 × 1.618）
    final finalImageWidth = finalImageHeight * imageWidthToHeightRatio;

    return Size(finalImageWidth, finalImageHeight);
  }

  /// 計算文字區域可用寬度
  static double calculateTextAreaWidth({required double containerWidth, required double imageWidth}) {
    return containerWidth - imageWidth - imageToTextSpacing;
  }

  /// 計算姓名區域高度（容器高度的 50%）
  static double calculateNameAreaHeight(double containerHeight) {
    return containerHeight * 0.5 - (containerPadding / 2);
  }

  /// 計算公司+職稱區域高度（容器高度的 50%）
  static double calculateCompanyAreaHeight(double containerHeight) {
    return containerHeight * 0.5 - (containerPadding / 2);
  }
}

/// 螢幕尺寸分類
enum ScreenSize {
  small, // < 375pt
  medium, // 375pt - 430pt
  large, // > 430pt
}

/// 通用響應式工具類
class AppResponsiveUtils {
  AppResponsiveUtils._();

  /// 根據螢幕寬度獲取螢幕尺寸分類
  static ScreenSize getScreenSizeCategory(double screenWidth) {
    if (screenWidth < 375) {
      return ScreenSize.small;
    } else if (screenWidth < 430) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.large;
    }
  }

  /// 根據螢幕尺寸返回不同的數值
  static T responsive<T>({required double screenWidth, required T small, required T medium, required T large}) {
    final screenSize = getScreenSizeCategory(screenWidth);
    switch (screenSize) {
      case ScreenSize.small:
        return small;
      case ScreenSize.medium:
        return medium;
      case ScreenSize.large:
        return large;
    }
  }

  /// 基於螢幕寬度的比例縮放
  /// 基準螢幕寬度：375（iPhone 標準螢幕）
  static double scale(double value, double screenWidth, {double baseWidth = 375}) {
    return value * (screenWidth / baseWidth);
  }

  /// 獲取安全的螢幕尺寸（排除狀態列和底部安全區域）
  static Size getSafeScreenSize(FlutterView view) {
    final physicalSize = view.physicalSize;
    final devicePixelRatio = view.devicePixelRatio;
    final padding = view.padding;

    final screenWidth = physicalSize.width / devicePixelRatio;
    final screenHeight = (physicalSize.height - padding.top - padding.bottom) / devicePixelRatio;

    return Size(screenWidth, screenHeight);
  }

  // ==================== 通用響應式工具方法 ====================
}

/// 響應式設計常數
class AppResponsiveConstants {
  AppResponsiveConstants._();

  /// 標準螢幕寬度基準點
  static const double baseScreenWidth = 375;

  /// 標準螢幕高度基準點
  static const double baseScreenHeight = 812;

  /// 最小支援螢幕寬度
  static const double minScreenWidth = 320;

  /// 最大支援螢幕寬度
  static const double maxScreenWidth = 430;

  /// 標準間距比例
  static const double spacingRatio = 0.04; // 螢幕寬度的 4%
}
