import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 主題化輸入框類型
enum ThemedTextFieldType {
  /// 普通文字輸入
  text,
  /// 密碼輸入
  password,
  /// 電子郵件輸入
  email,
  /// 電話號碼輸入
  phone,
  /// 數字輸入
  number,
  /// 搜尋輸入
  search,
  /// 多行文字輸入
  multiline,
  /// URL 輸入
  url,
}

/// 主題化輸入框驗證狀態
enum ThemedTextFieldValidationState {
  /// 正常狀態
  normal,
  /// 成功狀態
  success,
  /// 警告狀態
  warning,
  /// 錯誤狀態
  error,
}

/// 主題化輸入框尺寸
enum ThemedTextFieldSize {
  /// 小尺寸
  small,
  /// 中等尺寸（預設）
  medium,
  /// 大尺寸
  large,
}

/// 主題化輸入框元件
///
/// 提供一致的輸入框樣式，支援：
/// - 多種輸入類型和驗證狀態
/// - 淺色/深色主題自動適應
/// - 前綴和後綴圖示
/// - 字數限制和提示
/// - Material Design 3 設計規範
/// - 無障礙支援
///
/// 使用範例：
/// ```dart
/// ThemedTextField(
///   label: '使用者名稱',
///   type: ThemedTextFieldType.text,
///   onChanged: (value) => print(value),
/// )
/// ```
class ThemedTextField extends StatefulWidget {
  /// 控制器
  final TextEditingController? controller;

  /// 標籤文字
  final String? label;

  /// 提示文字
  final String? hint;

  /// 輔助文字
  final String? helperText;

  /// 錯誤文字
  final String? errorText;

  /// 輸入框類型
  final ThemedTextFieldType type;

  /// 驗證狀態
  final ThemedTextFieldValidationState validationState;

  /// 輸入框尺寸
  final ThemedTextFieldSize size;

  /// 文字變更回調
  final ValueChanged<String>? onChanged;

  /// 提交回調
  final ValueChanged<String>? onSubmitted;

  /// 焦點變更回調
  final ValueChanged<bool>? onFocusChanged;

  /// 前綴圖示
  final IconData? prefixIcon;

  /// 後綴圖示
  final IconData? suffixIcon;

  /// 後綴圖示點擊回調
  final VoidCallback? onSuffixIconPressed;

  /// 是否為必填欄位
  final bool required;

  /// 是否啟用
  final bool enabled;

  /// 是否唯讀
  final bool readOnly;

  /// 是否自動對焦
  final bool autofocus;

  /// 字數限制
  final int? maxLength;

  /// 最大行數
  final int? maxLines;

  /// 最小行數
  final int? minLines;

  /// 輸入格式化器
  final List<TextInputFormatter>? inputFormatters;

  /// 鍵盤類型（可覆寫預設）
  final TextInputType? keyboardType;

  /// 輸入動作
  final TextInputAction? textInputAction;

  /// 文字對齊
  final TextAlign textAlign;

  /// 自動校正
  final bool autocorrect;

  /// 文字大小寫
  final TextCapitalization textCapitalization;

  /// 模糊文字（密碼）
  final bool obscureText;

  /// 自定義內邊距
  final EdgeInsets? contentPadding;

  /// 自定義外邊距
  final EdgeInsets? margin;

  /// 語義標籤（無障礙）
  final String? semanticLabel;

  const ThemedTextField({
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.type = ThemedTextFieldType.text,
    this.validationState = ThemedTextFieldValidationState.normal,
    this.size = ThemedTextFieldSize.medium,
    this.onChanged,
    this.onSubmitted,
    this.onFocusChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLength,
    this.maxLines,
    this.minLines,
    this.inputFormatters,
    this.keyboardType,
    this.textInputAction,
    this.textAlign = TextAlign.start,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.contentPadding,
    this.margin,
    this.semanticLabel,
    super.key,
  });

  @override
  State<ThemedTextField> createState() => _ThemedTextFieldState();
}

class _ThemedTextFieldState extends State<ThemedTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _obscureText = false;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _obscureText = widget.obscureText || widget.type == ThemedTextFieldType.password;

    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(ThemedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obscureText != oldWidget.obscureText ||
        widget.type != oldWidget.type) {
      _obscureText = widget.obscureText || widget.type == ThemedTextFieldType.password;
    }
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (_hasFocus != hasFocus) {
      setState(() {
        _hasFocus = hasFocus;
      });
      widget.onFocusChanged?.call(hasFocus);
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getTextFieldConfig(widget.size);
    final colorScheme = _getColorScheme(context, widget.validationState);

    Widget textField = TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      maxLength: widget.maxLength,
      maxLines: _getMaxLines(),
      minLines: widget.minLines,
      keyboardType: _getKeyboardType(),
      textInputAction: widget.textInputAction ?? _getDefaultTextInputAction(),
      textAlign: widget.textAlign,
      autocorrect: widget.autocorrect,
      textCapitalization: widget.textCapitalization,
      obscureText: _obscureText,
      inputFormatters: _getInputFormatters(),
      style: config.textStyle.copyWith(
        color: widget.enabled 
            ? AppColors.getTextColor(theme.brightness)
            : AppColors.getTextColor(theme.brightness)
                .withValues(alpha: AppColorConstants.opacityDisabled),
      ),
      decoration: InputDecoration(
        labelText: _getLabelText(),
        hintText: widget.hint,
        helperText: widget.helperText,
        errorText: widget.errorText,
        prefixIcon: _buildPrefixIcon(colorScheme),
        suffixIcon: _buildSuffixIcon(colorScheme),
        contentPadding: widget.contentPadding ?? config.contentPadding,
        border: _buildBorder(colorScheme.border),
        enabledBorder: _buildBorder(colorScheme.border),
        focusedBorder: _buildBorder(colorScheme.focusedBorder),
        errorBorder: _buildBorder(colorScheme.errorBorder),
        focusedErrorBorder: _buildBorder(colorScheme.errorBorder),
        disabledBorder: _buildBorder(
          colorScheme.border.withValues(alpha: AppColorConstants.opacityDisabled),
        ),
        filled: true,
        fillColor: widget.enabled 
            ? colorScheme.fillColor
            : colorScheme.fillColor.withValues(alpha: AppColorConstants.opacityDisabled),
        labelStyle: config.labelStyle.copyWith(color: colorScheme.labelColor),
        hintStyle: config.hintStyle.copyWith(color: colorScheme.hintColor),
        helperStyle: config.helperStyle.copyWith(color: colorScheme.helperColor),
        errorStyle: config.errorStyle.copyWith(color: colorScheme.errorColor),
        counterStyle: config.counterStyle.copyWith(color: colorScheme.hintColor),
      ),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );

    // 添加外邊距
    if (widget.margin != null) {
      textField = Padding(
        padding: widget.margin!,
        child: textField,
      );
    }

    // 添加語義標籤
    if (widget.semanticLabel != null) {
      textField = Semantics(
        label: widget.semanticLabel,
        textField: true,
        enabled: widget.enabled,
        child: textField,
      );
    }

    return textField;
  }

  /// 獲取標籤文字
  String? _getLabelText() {
    if (widget.label == null) {
      return null;
    }
    return widget.required ? '${widget.label} *' : widget.label;
  }

  /// 獲取最大行數
  int? _getMaxLines() {
    if (widget.type == ThemedTextFieldType.multiline) {
      return widget.maxLines ?? 5;
    }
    return widget.maxLines ?? 1;
  }

  /// 獲取鍵盤類型
  TextInputType _getKeyboardType() {
    if (widget.keyboardType != null) {
      return widget.keyboardType!;
    }

    switch (widget.type) {
      case ThemedTextFieldType.email:
        return TextInputType.emailAddress;
      case ThemedTextFieldType.phone:
        return TextInputType.phone;
      case ThemedTextFieldType.number:
        return TextInputType.number;
      case ThemedTextFieldType.url:
        return TextInputType.url;
      case ThemedTextFieldType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  /// 獲取預設輸入動作
  TextInputAction _getDefaultTextInputAction() {
    switch (widget.type) {
      case ThemedTextFieldType.search:
        return TextInputAction.search;
      case ThemedTextFieldType.multiline:
        return TextInputAction.newline;
      default:
        return TextInputAction.done;
    }
  }

  /// 獲取輸入格式化器
  List<TextInputFormatter>? _getInputFormatters() {
    if (widget.inputFormatters != null) {
      return widget.inputFormatters;
    }

    switch (widget.type) {
      case ThemedTextFieldType.phone:
        return [FilteringTextInputFormatter.digitsOnly];
      case ThemedTextFieldType.number:
        return [FilteringTextInputFormatter.digitsOnly];
      case ThemedTextFieldType.email:
        return [FilteringTextInputFormatter.deny(RegExp(r'\s'))];
      default:
        return null;
    }
  }

  /// 建立前綴圖示
  Widget? _buildPrefixIcon(_TextFieldColorScheme colorScheme) {
    IconData? iconData = widget.prefixIcon;

    // 根據類型設定預設圖示
    if (iconData == null) {
      switch (widget.type) {
        case ThemedTextFieldType.email:
          iconData = Icons.email_outlined;
          break;
        case ThemedTextFieldType.phone:
          iconData = Icons.phone_outlined;
          break;
        case ThemedTextFieldType.search:
          iconData = Icons.search;
          break;
        case ThemedTextFieldType.url:
          iconData = Icons.link;
          break;
        default:
          break;
      }
    }

    if (iconData == null) {
      return null;
    }

    return Icon(
      iconData,
      color: widget.enabled ? colorScheme.iconColor : colorScheme.iconColor
          .withValues(alpha: AppColorConstants.opacityDisabled),
    );
  }

  /// 建立後綴圖示
  Widget? _buildSuffixIcon(_TextFieldColorScheme colorScheme) {
    // 密碼可見性切換
    if (widget.type == ThemedTextFieldType.password) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: widget.enabled ? colorScheme.iconColor : colorScheme.iconColor
              .withValues(alpha: AppColorConstants.opacityDisabled),
        ),
        onPressed: widget.enabled ? _togglePasswordVisibility : null,
      );
    }

    // 搜尋清除按鈕
    if (widget.type == ThemedTextFieldType.search && 
        _controller.text.isNotEmpty && 
        widget.enabled) {
      return IconButton(
        icon: Icon(
          Icons.clear,
          color: colorScheme.iconColor,
        ),
        onPressed: () {
          _controller.clear();
          widget.onChanged?.call('');
        },
      );
    }

    // 自定義後綴圖示
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          color: widget.enabled ? colorScheme.iconColor : colorScheme.iconColor
              .withValues(alpha: AppColorConstants.opacityDisabled),
        ),
        onPressed: widget.enabled ? widget.onSuffixIconPressed : null,
      );
    }

    return null;
  }

  /// 建立邊框
  InputBorder _buildBorder(Color color) {
    final config = _getTextFieldConfig(widget.size);
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(config.borderRadius),
      borderSide: BorderSide(
        color: color,
        width: AppDimensions.borderMedium,
      ),
    );
  }

  /// 獲取輸入框配置
  _TextFieldConfig _getTextFieldConfig(ThemedTextFieldSize size) {
    switch (size) {
      case ThemedTextFieldSize.small:
        return _TextFieldConfig(
          height: AppDimensions.textFieldHeightSmall,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.space3,
            vertical: AppDimensions.space2,
          ),
          borderRadius: AppDimensions.radiusSmall,
          textStyle: const TextStyle(fontSize: 14),
          labelStyle: const TextStyle(fontSize: 12),
          hintStyle: const TextStyle(fontSize: 14),
          helperStyle: const TextStyle(fontSize: 11),
          errorStyle: const TextStyle(fontSize: 11),
          counterStyle: const TextStyle(fontSize: 11),
        );

      case ThemedTextFieldSize.medium:
        return _TextFieldConfig(
          height: AppDimensions.textFieldHeight,
          contentPadding: AppDimensions.paddingTextField,
          borderRadius: AppDimensions.radiusMedium,
          textStyle: const TextStyle(fontSize: 16),
          labelStyle: const TextStyle(fontSize: 14),
          hintStyle: const TextStyle(fontSize: 16),
          helperStyle: const TextStyle(fontSize: 12),
          errorStyle: const TextStyle(fontSize: 12),
          counterStyle: const TextStyle(fontSize: 12),
        );

      case ThemedTextFieldSize.large:
        return _TextFieldConfig(
          height: AppDimensions.textFieldHeightLarge,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppDimensions.space5,
            vertical: AppDimensions.space4,
          ),
          borderRadius: AppDimensions.radiusLarge,
          textStyle: const TextStyle(fontSize: 18),
          labelStyle: const TextStyle(fontSize: 16),
          hintStyle: const TextStyle(fontSize: 18),
          helperStyle: const TextStyle(fontSize: 14),
          errorStyle: const TextStyle(fontSize: 14),
          counterStyle: const TextStyle(fontSize: 14),
        );
    }
  }

  /// 獲取顏色方案
  _TextFieldColorScheme _getColorScheme(
    BuildContext context,
    ThemedTextFieldValidationState state,
  ) {
    final theme = Theme.of(context);

    final baseColors = _TextFieldColorScheme(
      border: AppColors.getBorderColor(theme.brightness),
      focusedBorder: AppColors.primary,
      errorBorder: AppColors.error,
      fillColor: AppColors.getCardBackgroundColor(theme.brightness),
      labelColor: AppColors.getTextColor(theme.brightness)
          .withValues(alpha: AppColorConstants.opacityMedium),
      hintColor: AppColors.placeholder,
      helperColor: AppColors.getTextColor(theme.brightness)
          .withValues(alpha: AppColorConstants.opacityMedium),
      errorColor: AppColors.error,
      iconColor: AppColors.getTextColor(theme.brightness)
          .withValues(alpha: AppColorConstants.opacityMedium),
    );

    switch (state) {
      case ThemedTextFieldValidationState.success:
        return baseColors.copyWith(
          border: AppColors.success,
          focusedBorder: AppColors.success,
        );

      case ThemedTextFieldValidationState.warning:
        return baseColors.copyWith(
          border: AppColors.warning,
          focusedBorder: AppColors.warning,
        );

      case ThemedTextFieldValidationState.error:
        return baseColors.copyWith(
          border: AppColors.error,
          focusedBorder: AppColors.error,
        );

      case ThemedTextFieldValidationState.normal:
      default:
        return baseColors;
    }
  }
}

/// 輸入框配置資料類別
class _TextFieldConfig {
  final double height;
  final EdgeInsets contentPadding;
  final double borderRadius;
  final TextStyle textStyle;
  final TextStyle labelStyle;
  final TextStyle hintStyle;
  final TextStyle helperStyle;
  final TextStyle errorStyle;
  final TextStyle counterStyle;

  const _TextFieldConfig({
    required this.height,
    required this.contentPadding,
    required this.borderRadius,
    required this.textStyle,
    required this.labelStyle,
    required this.hintStyle,
    required this.helperStyle,
    required this.errorStyle,
    required this.counterStyle,
  });
}

/// 輸入框顏色方案資料類別
class _TextFieldColorScheme {
  final Color border;
  final Color focusedBorder;
  final Color errorBorder;
  final Color fillColor;
  final Color labelColor;
  final Color hintColor;
  final Color helperColor;
  final Color errorColor;
  final Color iconColor;

  const _TextFieldColorScheme({
    required this.border,
    required this.focusedBorder,
    required this.errorBorder,
    required this.fillColor,
    required this.labelColor,
    required this.hintColor,
    required this.helperColor,
    required this.errorColor,
    required this.iconColor,
  });

  _TextFieldColorScheme copyWith({
    Color? border,
    Color? focusedBorder,
    Color? errorBorder,
    Color? fillColor,
    Color? labelColor,
    Color? hintColor,
    Color? helperColor,
    Color? errorColor,
    Color? iconColor,
  }) {
    return _TextFieldColorScheme(
      border: border ?? this.border,
      focusedBorder: focusedBorder ?? this.focusedBorder,
      errorBorder: errorBorder ?? this.errorBorder,
      fillColor: fillColor ?? this.fillColor,
      labelColor: labelColor ?? this.labelColor,
      hintColor: hintColor ?? this.hintColor,
      helperColor: helperColor ?? this.helperColor,
      errorColor: errorColor ?? this.errorColor,
      iconColor: iconColor ?? this.iconColor,
    );
  }
}