import 'package:flutter/material.dart';

/// 應用程式尺寸規範系統
///
/// 提供一致的間距、尺寸和佈局定義
/// 遵循 Material Design 3 和 iOS 人機介面指南
/// 確保跨平台的視覺一致性和良好的使用者體驗
class AppDimensions {
  AppDimensions._();

  // ==================== 基礎間距單位 ====================

  /// 基礎間距單位 - 8dp/pt 作為設計系統的基礎
  static const double baseUnit = 8;

  /// 最小間距 - 4dp/pt
  static const double space1 = baseUnit * 0.5; // 4.0

  /// 小間距 - 8dp/pt
  static const double space2 = baseUnit * 1.0; // 8.0

  /// 中間距 - 12dp/pt
  static const double space3 = baseUnit * 1.5; // 12.0

  /// 標準間距 - 16dp/pt
  static const double space4 = baseUnit * 2.0; // 16.0

  /// 大間距 - 20dp/pt
  static const double space5 = baseUnit * 2.5; // 20.0

  /// 較大間距 - 24dp/pt
  static const double space6 = baseUnit * 3.0; // 24.0

  /// 很大間距 - 32dp/pt
  static const double space8 = baseUnit * 4.0; // 32.0

  /// 超大間距 - 40dp/pt
  static const double space10 = baseUnit * 5.0; // 40.0

  /// 巨大間距 - 48dp/pt
  static const double space12 = baseUnit * 6.0; // 48.0

  /// 特大間距 - 64dp/pt
  static const double space16 = baseUnit * 8.0; // 64.0

  // ==================== 內邊距 (Padding) ====================

  /// 極小內邊距
  static const EdgeInsets paddingTiny = EdgeInsets.all(space1);

  /// 小內邊距
  static const EdgeInsets paddingSmall = EdgeInsets.all(space2);

  /// 中內邊距
  static const EdgeInsets paddingMedium = EdgeInsets.all(space4);

  /// 大內邊距
  static const EdgeInsets paddingLarge = EdgeInsets.all(space6);

  /// 超大內邊距
  static const EdgeInsets paddingExtraLarge = EdgeInsets.all(space8);

  /// 水平小內邊距
  static const EdgeInsets paddingHorizontalSmall = EdgeInsets.symmetric(
    horizontal: space2,
  );

  /// 水平中內邊距
  static const EdgeInsets paddingHorizontalMedium = EdgeInsets.symmetric(
    horizontal: space4,
  );

  /// 水平大內邊距
  static const EdgeInsets paddingHorizontalLarge = EdgeInsets.symmetric(
    horizontal: space6,
  );

  /// 垂直小內邊距
  static const EdgeInsets paddingVerticalSmall = EdgeInsets.symmetric(
    vertical: space2,
  );

  /// 垂直中內邊距
  static const EdgeInsets paddingVerticalMedium = EdgeInsets.symmetric(
    vertical: space4,
  );

  /// 垂直大內邊距
  static const EdgeInsets paddingVerticalLarge = EdgeInsets.symmetric(
    vertical: space6,
  );

  /// 頁面內邊距 - 適用於頁面主要內容區域
  static const EdgeInsets paddingPage = EdgeInsets.all(space4);

  /// 卡片內邊距 - 適用於卡片內容
  static const EdgeInsets paddingCard = EdgeInsets.all(space4);

  /// 按鈕內邊距 - 適用於按鈕文字周圍
  static const EdgeInsets paddingButton = EdgeInsets.symmetric(
    horizontal: space6,
    vertical: space3,
  );

  /// 輸入框內邊距 - 適用於文字輸入框
  static const EdgeInsets paddingTextField = EdgeInsets.symmetric(
    horizontal: space4,
    vertical: space3,
  );

  // ==================== 外邊距 (Margin) ====================

  /// 小外邊距
  static const EdgeInsets marginSmall = EdgeInsets.all(space2);

  /// 中外邊距
  static const EdgeInsets marginMedium = EdgeInsets.all(space4);

  /// 大外邊距
  static const EdgeInsets marginLarge = EdgeInsets.all(space6);

  /// 列表項外邊距
  static const EdgeInsets marginListItem = EdgeInsets.symmetric(
    horizontal: space4,
    vertical: space1,
  );

  /// 卡片外邊距
  static const EdgeInsets marginCard = EdgeInsets.symmetric(
    horizontal: space4,
    vertical: space2,
  );

  /// 節區外邊距 - 用於分隔不同內容節區
  static const EdgeInsets marginSection = EdgeInsets.only(bottom: space6);

  // ==================== 圓角半徑 ====================

  /// 極小圓角
  static const double radiusTiny = 2;

  /// 小圓角 - 用於按鈕、標籤
  static const double radiusSmall = 4;

  /// 中圓角 - 用於輸入框、小卡片
  static const double radiusMedium = 8;

  /// 大圓角 - 用於卡片、對話框
  static const double radiusLarge = 12;

  /// 超大圓角 - 用於底部選單、大卡片
  static const double radiusExtraLarge = 16;

  /// 巨大圓角 - 用於圓形按鈕或特殊元件
  static const double radiusGigantic = 24;

  /// 圓形 - 完全圓形元件
  static const double radiusCircular = 1000;

  // ==================== 邊框寬度 ====================

  /// 極細邊框
  static const double borderThin = 0.5;

  /// 標準邊框
  static const double borderMedium = 1;

  /// 粗邊框
  static const double borderThick = 2;

  /// 焦點邊框 - 當元件獲得焦點時
  static const double borderFocus = 2;

  // ==================== 陰影配置 ====================

  /// 小陰影 - 用於懸浮按鈕
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// 中陰影 - 用於卡片
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  /// 大陰影 - 用於對話框、底部選單
  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  /// 超大陰影 - 用於模態對話框
  static const List<BoxShadow> shadowExtraLarge = [
    BoxShadow(
      color: Color(0x29000000),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  // ==================== 元件尺寸 ====================

  /// 圖示尺寸
  static const double iconTiny = 12;
  static const double iconSmall = 16;
  static const double iconMedium = 24;
  static const double iconLarge = 32;
  static const double iconExtraLarge = 48;

  /// 按鈕高度
  static const double buttonHeightSmall = 32;
  static const double buttonHeightMedium = 40;
  static const double buttonHeightLarge = 48;
  static const double buttonHeightExtraLarge = 56;

  /// 輸入框高度
  static const double textFieldHeight = 48;
  static const double textFieldHeightSmall = 40;
  static const double textFieldHeightLarge = 56;

  /// 列表項高度
  static const double listItemHeight = 56;
  static const double listItemHeightSmall = 48;
  static const double listItemHeightLarge = 72;

  /// 應用程式欄高度
  static const double appBarHeight = 56;
  static const double appBarHeightLarge = 64;

  /// 底部導航欄高度
  static const double bottomNavigationHeight = 60;

  /// 標籤欄高度
  static const double tabBarHeight = 48;

  /// 分隔線高度
  static const double separatorHeight = 1;

  /// 進度指示器尺寸
  static const double progressIndicatorSize = 20;
  static const double progressIndicatorSizeLarge = 40;

  // ==================== 動畫持續時間 ====================

  /// 極快動畫 - 100ms
  static const Duration animationFast = Duration(milliseconds: 100);

  /// 標準動畫 - 200ms
  static const Duration animationMedium = Duration(milliseconds: 200);

  /// 慢動畫 - 300ms
  static const Duration animationSlow = Duration(milliseconds: 300);

  /// 超慢動畫 - 500ms
  static const Duration animationExtraSlow = Duration(milliseconds: 500);

  // ==================== 斷點 (Breakpoints) ====================

  /// 手機斷點
  static const double breakpointMobile = 480;

  /// 平板斷點
  static const double breakpointTablet = 768;

  /// 桌面斷點
  static const double breakpointDesktop = 1024;

  /// 大桌面斷點
  static const double breakpointLargeDesktop = 1440;

  // ==================== 特殊尺寸 ====================

  /// 名片掃描框最小尺寸
  static const Size scannerFrameMinSize = Size(280, 180);

  /// 名片掃描框最大尺寸
  static const Size scannerFrameMaxSize = Size(360, 240);

  /// 名片預覽尺寸
  static const Size cardPreviewSize = Size(320, 200);

  /// 名片縮圖尺寸
  static const Size cardThumbnailSize = Size(80, 50);

  /// 頭像尺寸
  static const double avatarSizeSmall = 32;
  static const double avatarSizeMedium = 48;
  static const double avatarSizeLarge = 72;

  /// 載入指示器尺寸
  static const double loadingIndicatorSize = 24;
  static const double loadingIndicatorSizeLarge = 48;

  // ==================== 輔助方法 ====================

  /// 根據螢幕寬度決定是否為手機版面
  static bool isMobile(double screenWidth) {
    return screenWidth < breakpointTablet;
  }

  /// 根據螢幕寬度決定是否為平板版面
  static bool isTablet(double screenWidth) {
    return screenWidth >= breakpointTablet && screenWidth < breakpointDesktop;
  }

  /// 根據螢幕寬度決定是否為桌面版面
  static bool isDesktop(double screenWidth) {
    return screenWidth >= breakpointDesktop;
  }

  /// 根據螢幕尺寸獲取適當的內邊距
  static EdgeInsets getResponsivePadding(double screenWidth) {
    if (isMobile(screenWidth)) {
      return paddingMedium;
    } else if (isTablet(screenWidth)) {
      return paddingLarge;
    } else {
      return paddingExtraLarge;
    }
  }

  /// 根據螢幕尺寸獲取適當的按鈕高度
  static double getResponsiveButtonHeight(double screenWidth) {
    if (isMobile(screenWidth)) {
      return buttonHeightMedium;
    } else {
      return buttonHeightLarge;
    }
  }

  /// 建立對稱內邊距
  static EdgeInsets symmetric({double? horizontal, double? vertical}) {
    return EdgeInsets.symmetric(
      horizontal: horizontal ?? 0,
      vertical: vertical ?? 0,
    );
  }

  /// 建立僅特定方向的內邊距
  static EdgeInsets only({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return EdgeInsets.only(
      left: left ?? 0,
      top: top ?? 0,
      right: right ?? 0,
      bottom: bottom ?? 0,
    );
  }

  /// 建立圓角邊框
  static BorderRadius circular(double radius) {
    return BorderRadius.circular(radius);
  }

  /// 建立僅特定角的圓角邊框
  static BorderRadius radiusOnly({
    double? topLeft,
    double? topRight,
    double? bottomLeft,
    double? bottomRight,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft ?? 0),
      topRight: Radius.circular(topRight ?? 0),
      bottomLeft: Radius.circular(bottomLeft ?? 0),
      bottomRight: Radius.circular(bottomRight ?? 0),
    );
  }

  /// 建立上方圓角邊框
  static BorderRadius topCircular(double radius) {
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );
  }

  /// 建立下方圓角邊框
  static BorderRadius bottomCircular(double radius) {
    return BorderRadius.only(
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
  }
}
