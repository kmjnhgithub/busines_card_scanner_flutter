import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 主題化卡片元件尺寸類型
enum ThemedCardSize {
  /// 小尺寸卡片
  small,
  /// 中等尺寸卡片（預設）
  medium,
  /// 大尺寸卡片
  large,
}

/// 主題化卡片元件
///
/// 提供一致的卡片樣式，支援：
/// - 淺色/深色主題自動適應
/// - 多種尺寸選項
/// - 自定義內容
/// - 點擊事件
/// - 載入狀態
/// - Material Design 3 設計規範
///
/// 使用範例：
/// ```dart
/// ThemedCard(
///   size: ThemedCardSize.medium,
///   onTap: () => print('Card tapped'),
///   child: Text('Card content'),
/// )
/// ```
class ThemedCard extends StatelessWidget {
  /// 卡片內容
  final Widget child;

  /// 卡片尺寸
  final ThemedCardSize size;

  /// 點擊回調
  final VoidCallback? onTap;

  /// 長按回調
  final VoidCallback? onLongPress;

  /// 是否顯示陰影
  final bool showShadow;

  /// 是否顯示邊框
  final bool showBorder;

  /// 自定義背景色（覆寫主題色）
  final Color? backgroundColor;

  /// 自定義邊框色（覆寫主題色）
  final Color? borderColor;

  /// 是否處於載入狀態
  final bool isLoading;

  /// 載入指示器顏色
  final Color? loadingColor;

  /// 自定義內邊距
  final EdgeInsets? padding;

  /// 自定義外邊距
  final EdgeInsets? margin;

  /// 自定義圓角半徑
  final double? borderRadius;

  /// 是否啟用（影響透明度和點擊）
  final bool enabled;

  const ThemedCard({
    required this.child,
    this.size = ThemedCardSize.medium,
    this.onTap,
    this.onLongPress,
    this.showShadow = true,
    this.showBorder = false,
    this.backgroundColor,
    this.borderColor,
    this.isLoading = false,
    this.loadingColor,
    this.padding,
    this.margin,
    this.borderRadius,
    this.enabled = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 根據尺寸獲取配置
    final config = _getCardConfig(size);

    // 獲取顏色
    final bgColor = backgroundColor ?? 
        AppColors.getCardBackgroundColor(theme.brightness);
    final actualBorderColor = borderColor ?? 
        AppColors.getBorderColor(theme.brightness);

    // 建立卡片裝飾
    final decoration = BoxDecoration(
      color: enabled ? bgColor : AppColors.withOpacity(bgColor, 0.6),
      borderRadius: BorderRadius.circular(
        borderRadius ?? config.borderRadius,
      ),
      border: showBorder
          ? Border.all(
              color: enabled 
                  ? actualBorderColor 
                  : AppColors.withOpacity(actualBorderColor, 0.3),
              width: AppDimensions.borderMedium,
            )
          : null,
      boxShadow: showShadow && enabled ? config.shadows : null,
    );

    // 建立內容
    Widget content = Container(
      margin: margin ?? config.margin,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          borderRadius: BorderRadius.circular(
            borderRadius ?? config.borderRadius,
          ),
          child: Container(
            padding: padding ?? config.padding,
            child: isLoading ? _buildLoadingContent(context) : child,
          ),
        ),
      ),
    );

    // 如果禁用，添加透明度
    if (!enabled) {
      content = Opacity(
        opacity: AppColorConstants.opacityDisabled,
        child: content,
      );
    }

    return content;
  }

  /// 建立載入狀態內容
  Widget _buildLoadingContent(BuildContext context) {
    final loadingIndicator = SizedBox(
      width: AppDimensions.progressIndicatorSize,
      height: AppDimensions.progressIndicatorSize,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          loadingColor ?? Theme.of(context).primaryColor,
        ),
      ),
    );

    return Stack(
      children: [
        // 原始內容（半透明）
        Opacity(
          opacity: AppColorConstants.opacityMedium,
          child: child,
        ),
        // 載入指示器（置中）
        Center(
          child: Container(
            padding: AppDimensions.paddingSmall,
            decoration: BoxDecoration(
              color: AppColors.getBackgroundColor(
                Theme.of(context).brightness,
              ).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(
                AppDimensions.radiusSmall,
              ),
            ),
            child: loadingIndicator,
          ),
        ),
      ],
    );
  }

  /// 獲取卡片配置
  _CardConfig _getCardConfig(ThemedCardSize size) {
    switch (size) {
      case ThemedCardSize.small:
        return const _CardConfig(
          padding: AppDimensions.paddingSmall,
          margin: AppDimensions.marginSmall,
          borderRadius: AppDimensions.radiusSmall,
          shadows: AppDimensions.shadowSmall,
        );
      case ThemedCardSize.medium:
        return const _CardConfig(
          padding: AppDimensions.paddingMedium,
          margin: AppDimensions.marginMedium,
          borderRadius: AppDimensions.radiusMedium,
          shadows: AppDimensions.shadowMedium,
        );
      case ThemedCardSize.large:
        return const _CardConfig(
          padding: AppDimensions.paddingLarge,
          margin: AppDimensions.marginLarge,
          borderRadius: AppDimensions.radiusLarge,
          shadows: AppDimensions.shadowLarge,
        );
    }
  }
}

/// 卡片配置資料類別
class _CardConfig {
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;
  final List<BoxShadow> shadows;

  const _CardConfig({
    required this.padding,
    required this.margin,
    required this.borderRadius,
    required this.shadows,
  });
}

/// 特殊用途的卡片變體

/// 名片預覽卡片
///
/// 專門用於顯示名片資訊的卡片元件
class BusinessCardPreviewCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isLoading;

  const BusinessCardPreviewCard({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ThemedCard(
      size: ThemedCardSize.medium,
      onTap: onTap,
      onLongPress: onLongPress,
      isLoading: isLoading,
      showBorder: isSelected,
      borderColor: isSelected ? AppColors.primary : null,
      backgroundColor: isSelected 
          ? AppColors.withOpacity(AppColors.primary, 0.05)
          : null,
      child: child,
    );
  }
}

/// 設定項目卡片
///
/// 專門用於設定頁面項目的卡片元件
class SettingsItemCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool showDivider;

  const SettingsItemCard({
    required this.child,
    this.onTap,
    this.showDivider = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ThemedCard(
      size: ThemedCardSize.small,
      onTap: onTap,
      showShadow: false,
      margin: EdgeInsets.zero,
      borderRadius: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          if (showDivider)
            Container(
              height: AppDimensions.separatorHeight,
              color: AppColors.getBorderColor(
                Theme.of(context).brightness,
              ),
            ),
        ],
      ),
    );
  }
}

/// 統計資訊卡片
///
/// 專門用於顯示統計資訊的卡片元件
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const StatsCard({
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ThemedCard(
      size: ThemedCardSize.medium,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppDimensions.iconLarge,
              color: iconColor ?? theme.primaryColor,
            ),
            const SizedBox(height: AppDimensions.space2),
          ],
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.getTextColor(theme.brightness)
                  .withValues(alpha: AppColorConstants.opacityMedium),
            ),
          ),
          const SizedBox(height: AppDimensions.space1),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.getTextColor(theme.brightness),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}