import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 主題化按鈕類型
enum ThemedButtonType {
  /// 主要按鈕（實心，品牌色背景）
  primary,
  /// 次要按鈕（實心，灰色背景）
  secondary,
  /// 外框按鈕（透明背景，彩色邊框）
  outline,
  /// 文字按鈕（透明背景，無邊框）
  text,
  /// 圖示按鈕（圓形，僅圖示）
  icon,
}

/// 主題化按鈕尺寸
enum ThemedButtonSize {
  /// 小尺寸
  small,
  /// 中等尺寸（預設）
  medium,
  /// 大尺寸
  large,
  /// 超大尺寸
  extraLarge,
}

/// 主題化按鈕元件
///
/// 提供一致的按鈕樣式，支援：
/// - 多種按鈕類型和尺寸
/// - 淺色/深色主題自動適應
/// - 載入狀態顯示
/// - 圖示和文字組合
/// - Material Design 3 設計規範
/// - 無障礙支援
///
/// 使用範例：
/// ```dart
/// ThemedButton(
///   text: '確認',
///   type: ThemedButtonType.primary,
///   size: ThemedButtonSize.medium,
///   onPressed: () => print('Button pressed'),
/// )
/// ```
class ThemedButton extends StatelessWidget {
  /// 按鈕文字
  final String? text;

  /// 按鈕類型
  final ThemedButtonType type;

  /// 按鈕尺寸
  final ThemedButtonSize size;

  /// 點擊回調
  final VoidCallback? onPressed;

  /// 圖示（可選）
  final IconData? icon;

  /// 圖示位置（文字前或後）
  final bool iconAfterText;

  /// 是否處於載入狀態
  final bool isLoading;

  /// 載入指示器顏色
  final Color? loadingColor;

  /// 自定義背景色（覆寫主題色）
  final Color? backgroundColor;

  /// 自定義前景色（文字和圖示）
  final Color? foregroundColor;

  /// 自定義邊框色
  final Color? borderColor;

  /// 是否展開填滿可用寬度
  final bool expanded;

  /// 自定義內邊距
  final EdgeInsets? padding;

  /// 自定義外邊距
  final EdgeInsets? margin;

  /// 自定義圓角半徑
  final double? borderRadius;

  /// 語義標籤（無障礙）
  final String? semanticLabel;

  /// 提示文字（無障礙）
  final String? tooltip;

  const ThemedButton({
    this.text,
    this.type = ThemedButtonType.primary,
    this.size = ThemedButtonSize.medium,
    this.onPressed,
    this.icon,
    this.iconAfterText = false,
    this.isLoading = false,
    this.loadingColor,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.expanded = false,
    this.padding,
    this.margin,
    this.borderRadius,
    this.semanticLabel,
    this.tooltip,
    super.key,
  }) : assert(
         text != null || icon != null,
         'Either text or icon must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final config = _getButtonConfig(size);
    final colorScheme = _getColorScheme(context, type);

    // 建立按鈕內容
    Widget buttonContent = _buildButtonContent(context, config, colorScheme);

    // 建立按鈕
    Widget button = _buildButton(context, config, colorScheme, buttonContent);

    // 添加外邊距
    if (margin != null) {
      button = Padding(
        padding: margin!,
        child: button,
      );
    }

    // 展開填滿寬度
    if (expanded) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    // 添加提示文字
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    // 添加語義標籤
    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null && !isLoading,
        child: button,
      );
    }

    return button;
  }

  /// 建立按鈕內容
  Widget _buildButtonContent(
    BuildContext context,
    _ButtonConfig config,
    _ButtonColorScheme colorScheme,
  ) {
    if (isLoading) {
      return SizedBox(
        width: config.iconSize,
        height: config.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(
            loadingColor ?? colorScheme.foreground,
          ),
        ),
      );
    }

    final List<Widget> children = [];

    // 添加圖示（前）
    if (icon != null && !iconAfterText) {
      children.add(
        Icon(
          icon,
          size: config.iconSize,
          color: foregroundColor ?? colorScheme.foreground,
        ),
      );
      if (text != null) {
        children.add(SizedBox(width: config.spacing));
      }
    }

    // 添加文字
    if (text != null) {
      children.add(
        Text(
          text!,
          style: config.textStyle.copyWith(
            color: foregroundColor ?? colorScheme.foreground,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // 添加圖示（後）
    if (icon != null && iconAfterText) {
      if (text != null) {
        children.add(SizedBox(width: config.spacing));
      }
      children.add(
        Icon(
          icon,
          size: config.iconSize,
          color: foregroundColor ?? colorScheme.foreground,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  /// 建立按鈕
  Widget _buildButton(
    BuildContext context,
    _ButtonConfig config,
    _ButtonColorScheme colorScheme,
    Widget content,
  ) {
    final actualPadding = padding ?? config.padding;
    final actualBorderRadius = borderRadius ?? config.borderRadius;

    switch (type) {
      case ThemedButtonType.primary:
      case ThemedButtonType.secondary:
        return ElevatedButton(
          onPressed: onPressed != null && !isLoading ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? colorScheme.background,
            foregroundColor: foregroundColor ?? colorScheme.foreground,
            elevation: config.elevation,
            shadowColor: colorScheme.shadow,
            padding: actualPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(actualBorderRadius),
            ),
            minimumSize: Size(config.minWidth, config.height),
          ),
          child: content,
        );

      case ThemedButtonType.outline:
        return OutlinedButton(
          onPressed: onPressed != null && !isLoading ? onPressed : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor ?? colorScheme.background,
            foregroundColor: foregroundColor ?? colorScheme.foreground,
            side: BorderSide(
              color: borderColor ?? colorScheme.border,
              width: AppDimensions.borderMedium,
            ),
            padding: actualPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(actualBorderRadius),
            ),
            minimumSize: Size(config.minWidth, config.height),
          ),
          child: content,
        );

      case ThemedButtonType.text:
        return TextButton(
          onPressed: onPressed != null && !isLoading ? onPressed : null,
          style: TextButton.styleFrom(
            backgroundColor: backgroundColor ?? colorScheme.background,
            foregroundColor: foregroundColor ?? colorScheme.foreground,
            padding: actualPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(actualBorderRadius),
            ),
            minimumSize: Size(config.minWidth, config.height),
          ),
          child: content,
        );

      case ThemedButtonType.icon:
        return IconButton(
          onPressed: onPressed != null && !isLoading ? onPressed : null,
          icon: content,
          iconSize: config.iconSize,
          padding: actualPadding,
          color: foregroundColor ?? colorScheme.foreground,
          style: IconButton.styleFrom(
            backgroundColor: backgroundColor ?? colorScheme.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(actualBorderRadius),
            ),
            minimumSize: Size(config.height, config.height),
          ),
        );
    }
  }

  /// 獲取按鈕配置
  _ButtonConfig _getButtonConfig(ThemedButtonSize size) {
    switch (size) {
      case ThemedButtonSize.small:
        return _ButtonConfig(
          height: AppDimensions.buttonHeightSmall,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space3,
            vertical: AppDimensions.space1,
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          iconSize: AppDimensions.iconSmall,
          borderRadius: AppDimensions.radiusSmall,
          elevation: 1,
          spacing: AppDimensions.space1,
          minWidth: 64,
        );

      case ThemedButtonSize.medium:
        return _ButtonConfig(
          height: AppDimensions.buttonHeightMedium,
          padding: AppDimensions.paddingButton,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          iconSize: AppDimensions.iconMedium,
          borderRadius: AppDimensions.radiusMedium,
          elevation: 2,
          spacing: AppDimensions.space2,
          minWidth: 80,
        );

      case ThemedButtonSize.large:
        return _ButtonConfig(
          height: AppDimensions.buttonHeightLarge,
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.space8,
            vertical: AppDimensions.space4,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          iconSize: AppDimensions.iconLarge,
          borderRadius: AppDimensions.radiusLarge,
          elevation: 3,
          spacing: AppDimensions.space3,
          minWidth: 96,
        );

      case ThemedButtonSize.extraLarge:
        return _ButtonConfig(
          height: AppDimensions.buttonHeightExtraLarge,
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.space10,
            vertical: AppDimensions.space5,
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconSize: AppDimensions.iconLarge,
          borderRadius: AppDimensions.radiusLarge,
          elevation: 4,
          spacing: AppDimensions.space3,
          minWidth: 112,
        );
    }
  }

  /// 獲取顏色方案
  _ButtonColorScheme _getColorScheme(
    BuildContext context,
    ThemedButtonType type,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    switch (type) {
      case ThemedButtonType.primary:
        return _ButtonColorScheme(
          background: AppColors.primary,
          foreground: Colors.white,
          border: AppColors.primary,
          shadow: AppColors.shadow,
        );

      case ThemedButtonType.secondary:
        return _ButtonColorScheme(
          background: isDark 
              ? AppColors.secondaryBackgroundDark 
              : AppColors.secondaryBackground,
          foreground: AppColors.getTextColor(theme.brightness),
          border: AppColors.getBorderColor(theme.brightness),
          shadow: AppColors.shadow,
        );

      case ThemedButtonType.outline:
        return _ButtonColorScheme(
          background: Colors.transparent,
          foreground: AppColors.primary,
          border: AppColors.primary,
          shadow: Colors.transparent,
        );

      case ThemedButtonType.text:
        return _ButtonColorScheme(
          background: Colors.transparent,
          foreground: AppColors.primary,
          border: Colors.transparent,
          shadow: Colors.transparent,
        );

      case ThemedButtonType.icon:
        return _ButtonColorScheme(
          background: Colors.transparent,
          foreground: AppColors.getTextColor(theme.brightness),
          border: Colors.transparent,
          shadow: Colors.transparent,
        );
    }
  }
}

/// 按鈕配置資料類別
class _ButtonConfig {
  final double height;
  final EdgeInsets padding;
  final TextStyle textStyle;
  final double iconSize;
  final double borderRadius;
  final double elevation;
  final double spacing;
  final double minWidth;

  const _ButtonConfig({
    required this.height,
    required this.padding,
    required this.textStyle,
    required this.iconSize,
    required this.borderRadius,
    required this.elevation,
    required this.spacing,
    required this.minWidth,
  });
}

/// 按鈕顏色方案資料類別
class _ButtonColorScheme {
  final Color background;
  final Color foreground;
  final Color border;
  final Color shadow;

  const _ButtonColorScheme({
    required this.background,
    required this.foreground,
    required this.border,
    required this.shadow,
  });
}

/// 特殊用途的按鈕變體

/// 浮動操作按鈕
class ThemedFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final bool mini;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ThemedFloatingActionButton({
    required this.child,
    this.onPressed,
    this.tooltip,
    this.mini = false,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      mini: mini,
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: mini ? 2 : 6,
      child: child,
    );
  }
}

/// 危險操作按鈕
class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ThemedButtonSize size;
  final bool isLoading;
  final IconData? icon;

  const DangerButton({
    required this.text,
    this.onPressed,
    this.size = ThemedButtonSize.medium,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ThemedButton(
      text: text,
      type: ThemedButtonType.primary,
      size: size,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      backgroundColor: AppColors.error,
      foregroundColor: Colors.white,
    );
  }
}

/// 成功操作按鈕
class SuccessButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ThemedButtonSize size;
  final bool isLoading;
  final IconData? icon;

  const SuccessButton({
    required this.text,
    this.onPressed,
    this.size = ThemedButtonSize.medium,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ThemedButton(
      text: text,
      type: ThemedButtonType.primary,
      size: size,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      backgroundColor: AppColors.success,
      foregroundColor: Colors.white,
    );
  }
}

/// 按鈕組元件
class ThemedButtonGroup extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment alignment;
  final double spacing;
  final Axis direction;

  const ThemedButtonGroup({
    required this.children,
    this.alignment = MainAxisAlignment.center,
    this.spacing = AppDimensions.space2,
    this.direction = Axis.horizontal,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final separatedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      separatedChildren.add(children[i]);
      if (i < children.length - 1) {
        separatedChildren.add(
          direction == Axis.horizontal
              ? SizedBox(width: spacing)
              : SizedBox(height: spacing),
        );
      }
    }

    return direction == Axis.horizontal
        ? Row(
            mainAxisAlignment: alignment,
            children: separatedChildren,
          )
        : Column(
            mainAxisAlignment: alignment,
            children: separatedChildren,
          );
  }
}