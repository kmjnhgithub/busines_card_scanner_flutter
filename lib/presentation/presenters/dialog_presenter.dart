import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// 對話框類型
enum DialogType {
  /// 一般資訊對話框
  info,

  /// 確認對話框
  confirmation,

  /// 警告對話框
  warning,

  /// 錯誤對話框
  error,

  /// 自訂對話框
  custom,
}

/// 對話框按鈕配置
@immutable
class DialogButton {
  const DialogButton({
    required this.text,
    required this.onPressed,
    this.isDestructive = false,
    this.isPrimary = false,
  });

  /// 按鈕文字
  final String text;

  /// 按鈕點擊回調
  final VoidCallback? onPressed;

  /// 是否為破壞性操作按鈕（如刪除）
  final bool isDestructive;

  /// 是否為主要按鈕
  final bool isPrimary;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DialogButton &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          isDestructive == other.isDestructive &&
          isPrimary == other.isPrimary;

  @override
  int get hashCode =>
      text.hashCode ^ isDestructive.hashCode ^ isPrimary.hashCode;

  @override
  String toString() {
    return 'DialogButton(text: $text, isDestructive: $isDestructive, isPrimary: $isPrimary)';
  }
}

/// 對話框配置
@immutable
class DialogConfig {
  const DialogConfig({
    required this.title,
    required this.content,
    required this.type,
    this.buttons = const [],
    this.barrierDismissible = true,
    this.icon,
    this.customWidget,
  });

  /// 對話框標題
  final String title;

  /// 對話框內容
  final String content;

  /// 對話框類型
  final DialogType type;

  /// 按鈕列表
  final List<DialogButton> buttons;

  /// 是否可以點擊背景關閉
  final bool barrierDismissible;

  /// 自訂圖示
  final IconData? icon;

  /// 自訂 Widget（用於複雜對話框）
  final Widget? customWidget;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DialogConfig &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          content == other.content &&
          type == other.type &&
          buttons == other.buttons &&
          barrierDismissible == other.barrierDismissible &&
          icon == other.icon &&
          customWidget == other.customWidget;

  @override
  int get hashCode =>
      title.hashCode ^
      content.hashCode ^
      type.hashCode ^
      buttons.hashCode ^
      barrierDismissible.hashCode ^
      icon.hashCode ^
      customWidget.hashCode;

  @override
  String toString() {
    return 'DialogConfig(title: $title, content: $content, type: $type, buttons: $buttons, barrierDismissible: $barrierDismissible, icon: $icon)';
  }
}

/// Dialog Presenter
///
/// 負責管理應用程式中的對話框顯示
/// 提供統一的對話框樣式和行為管理
class DialogPresenter {
  DialogPresenter._();

  /// 顯示資訊對話框
  static Future<bool?> showInfo(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmText,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    return _showDialog(
      context,
      DialogConfig(
        title: title,
        content: content,
        type: DialogType.info,
        barrierDismissible: barrierDismissible,
        buttons: [
          DialogButton(
            text: confirmText ?? '確定',
            onPressed: () {
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop(true);
              }
              onConfirm?.call();
            },
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  /// 顯示確認對話框
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return _showDialog(
      context,
      DialogConfig(
        title: title,
        content: content,
        type: DialogType.confirmation,
        barrierDismissible: barrierDismissible,
        buttons: [
          DialogButton(
            text: cancelText ?? '取消',
            onPressed: () {
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop(false);
              }
              onCancel?.call();
            },
          ),
          DialogButton(
            text: confirmText ?? '確定',
            onPressed: () {
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop(true);
              }
              onConfirm?.call();
            },
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  /// 顯示警告對話框
  static Future<bool?> showWarning(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return _showDialog(
      context,
      DialogConfig(
        title: title,
        content: content,
        type: DialogType.warning,
        barrierDismissible: barrierDismissible,
        buttons: [
          if (cancelText != null)
            DialogButton(
              text: cancelText,
              onPressed: () {
                if (Navigator.of(context, rootNavigator: true).canPop()) {
                  Navigator.of(context, rootNavigator: true).pop(false);
                }
                onCancel?.call();
              },
            ),
          DialogButton(
            text: confirmText ?? '確定',
            onPressed: () {
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop(true);
              }
              onConfirm?.call();
            },
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  /// 顯示錯誤對話框
  static Future<bool?> showError(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmText,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    return _showDialog(
      context,
      DialogConfig(
        title: title,
        content: content,
        type: DialogType.error,
        barrierDismissible: barrierDismissible,
        buttons: [
          DialogButton(
            text: confirmText ?? '確定',
            onPressed: () {
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop(true);
              }
              onConfirm?.call();
            },
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  /// 顯示刪除確認對話框
  static Future<bool?> showDeleteConfirmation(
    BuildContext context, {
    required String title,
    required String content,
    String? deleteText,
    String? cancelText,
    VoidCallback? onDelete,
    VoidCallback? onCancel,
  }) {
    return _showDialog(
      context,
      DialogConfig(
        title: title,
        content: content,
        type: DialogType.warning,
        barrierDismissible: true,
        buttons: [
          DialogButton(
            text: cancelText ?? '取消',
            onPressed: () {
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop(false);
              }
              onCancel?.call();
            },
          ),
          DialogButton(
            text: deleteText ?? '刪除',
            onPressed: () {
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop(true);
              }
              onDelete?.call();
            },
            isDestructive: true,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  /// 顯示自訂對話框
  static Future<T?> showCustom<T>(
    BuildContext context, {
    required DialogConfig config,
  }) {
    return _showDialog<T>(context, config);
  }

  /// 顯示載入對話框
  static Future<void> showLoading(
    BuildContext context, {
    String? message,
    bool barrierDismissible = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => LoadingDialog(message: message),
    );
  }

  /// 隱藏對話框
  static void hide(BuildContext context) {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  /// 內部方法：顯示對話框
  static Future<T?> _showDialog<T>(BuildContext context, DialogConfig config) {
    return showDialog<T>(
      context: context,
      barrierDismissible: config.barrierDismissible,
      builder: (context) => CustomDialog(config: config),
    );
  }
}

/// 對話框樣式配置
class DialogStyleConfig {
  DialogStyleConfig._();

  /// 獲取對話框類型對應的顏色
  static Color getAccentColor(DialogType type) {
    switch (type) {
      case DialogType.info:
        return AppColors.info;
      case DialogType.confirmation:
        return AppColors.primary;
      case DialogType.warning:
        return AppColors.warning;
      case DialogType.error:
        return AppColors.error;
      case DialogType.custom:
        return AppColors.primary;
    }
  }

  /// 獲取對話框類型對應的圖示
  static IconData getIcon(DialogType type) {
    switch (type) {
      case DialogType.info:
        return Icons.info_outline;
      case DialogType.confirmation:
        return Icons.help_outline;
      case DialogType.warning:
        return Icons.warning_amber_outlined;
      case DialogType.error:
        return Icons.error_outline;
      case DialogType.custom:
        return Icons.info_outline;
    }
  }
}

/// 自訂對話框 Widget
class CustomDialog extends StatelessWidget {
  const CustomDialog({required this.config, super.key});

  final DialogConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = DialogStyleConfig.getAccentColor(config.type);

    return AlertDialog(
      title: Row(
        children: [
          if (config.icon != null || config.type != DialogType.custom) ...[
            Icon(
              config.icon ?? DialogStyleConfig.getIcon(config.type),
              color: accentColor,
              size: AppDimensions.iconMedium,
            ),
            const SizedBox(width: AppDimensions.space3),
          ],
          Expanded(
            child: Text(
              config.title,
              style: AppTextStyles.headline5.copyWith(
                color: theme.brightness == Brightness.light
                    ? AppColors.primaryText
                    : AppColors.primaryTextDark,
              ),
            ),
          ),
        ],
      ),
      content:
          config.customWidget ??
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320, minWidth: 280),
            child: Text(
              config.content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.brightness == Brightness.light
                    ? AppColors.secondaryText
                    : AppColors.secondaryTextDark,
              ),
            ),
          ),
      actions: config.buttons.isNotEmpty
          ? config.buttons
                .map((button) => _buildButton(context, button))
                .toList()
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      actionsPadding: const EdgeInsets.only(
        left: AppDimensions.space6,
        right: AppDimensions.space6,
        bottom: AppDimensions.space6,
      ),
    );
  }

  Widget _buildButton(BuildContext context, DialogButton button) {
    if (button.isPrimary) {
      return ElevatedButton(
        key: button.isDestructive ? const Key('delete_confirm_button') : null,
        onPressed: button.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: button.isDestructive
              ? AppColors.error
              : AppColors.primary,
          foregroundColor: Colors.white,
        ),
        child: Text(button.text),
      );
    } else {
      return TextButton(
        key: button.text == '取消' ? const Key('cancel_button') : null,
        onPressed: button.onPressed,
        style: TextButton.styleFrom(
          foregroundColor: button.isDestructive
              ? AppColors.error
              : AppColors.primary,
        ),
        child: Text(button.text),
      );
    }
  }
}

/// 載入對話框 Widget
class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: AppDimensions.loadingIndicatorSize,
              height: AppDimensions.loadingIndicatorSize,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            if (message != null) ...[
              const SizedBox(width: AppDimensions.space4),
              Expanded(
                child: Text(
                  message!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: theme.brightness == Brightness.light
                        ? AppColors.primaryText
                        : AppColors.primaryTextDark,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
    );
  }
}

/// 對話框便利擴展方法
extension DialogExtension on BuildContext {
  /// 顯示資訊對話框
  Future<bool?> showInfoDialog({
    required String title,
    required String content,
    String? confirmText,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    return DialogPresenter.showInfo(
      this,
      title: title,
      content: content,
      confirmText: confirmText,
      onConfirm: onConfirm,
      barrierDismissible: barrierDismissible,
    );
  }

  /// 顯示確認對話框
  Future<bool?> showConfirmationDialog({
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return DialogPresenter.showConfirmation(
      this,
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      barrierDismissible: barrierDismissible,
    );
  }

  /// 顯示警告對話框
  Future<bool?> showWarningDialog({
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool barrierDismissible = true,
  }) {
    return DialogPresenter.showWarning(
      this,
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      barrierDismissible: barrierDismissible,
    );
  }

  /// 顯示錯誤對話框
  Future<bool?> showErrorDialog({
    required String title,
    required String content,
    String? confirmText,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    return DialogPresenter.showError(
      this,
      title: title,
      content: content,
      confirmText: confirmText,
      onConfirm: onConfirm,
      barrierDismissible: barrierDismissible,
    );
  }

  /// 顯示刪除確認對話框
  Future<bool?> showDeleteConfirmationDialog({
    required String title,
    required String content,
    String? deleteText,
    String? cancelText,
    VoidCallback? onDelete,
    VoidCallback? onCancel,
  }) {
    return DialogPresenter.showDeleteConfirmation(
      this,
      title: title,
      content: content,
      deleteText: deleteText,
      cancelText: cancelText,
      onDelete: onDelete,
      onCancel: onCancel,
    );
  }

  /// 顯示載入對話框
  Future<void> showLoadingDialog({
    String? message,
    bool barrierDismissible = false,
  }) {
    return DialogPresenter.showLoading(
      this,
      message: message,
      barrierDismissible: barrierDismissible,
    );
  }

  /// 隱藏對話框
  void hideDialog() {
    DialogPresenter.hide(this);
  }
}
