import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';

/// Toast 訊息類型
enum ToastType {
  /// 一般資訊
  info,

  /// 成功訊息
  success,

  /// 警告訊息
  warning,

  /// 錯誤訊息
  error,
}

/// Toast 訊息設定
@immutable
class ToastMessage {
  const ToastMessage({
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
    this.action,
  });

  /// 訊息內容
  final String message;

  /// 訊息類型
  final ToastType type;

  /// 顯示持續時間
  final Duration duration;

  /// 可選的動作按鈕
  final ToastAction? action;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToastMessage &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          type == other.type &&
          duration == other.duration &&
          action == other.action;

  @override
  int get hashCode =>
      message.hashCode ^ type.hashCode ^ duration.hashCode ^ action.hashCode;

  @override
  String toString() {
    return 'ToastMessage(message: $message, type: $type, duration: $duration, action: $action)';
  }
}

/// Toast 動作按鈕設定
@immutable
class ToastAction {
  const ToastAction({required this.label, required this.onPressed});

  /// 按鈕標籤
  final String label;

  /// 按鈕點擊回調
  final VoidCallback onPressed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToastAction &&
          runtimeType == other.runtimeType &&
          label == other.label;

  @override
  int get hashCode => label.hashCode;

  @override
  String toString() {
    return 'ToastAction(label: $label)';
  }
}

/// Toast Presenter
///
/// 負責管理應用程式中的 Toast 訊息顯示
/// 提供統一的 Toast 樣式和行為管理
class ToastPresenter extends StateNotifier<ToastMessage?> {
  ToastPresenter() : super(null);

  /// 顯示一般資訊 Toast
  void showInfo(String message, {Duration? duration, ToastAction? action}) {
    _showToast(
      ToastMessage(
        message: message,
        type: ToastType.info,
        duration: duration ?? const Duration(seconds: 3),
        action: action,
      ),
    );
  }

  /// 顯示成功 Toast
  void showSuccess(String message, {Duration? duration, ToastAction? action}) {
    _showToast(
      ToastMessage(
        message: message,
        type: ToastType.success,
        duration: duration ?? const Duration(seconds: 3),
        action: action,
      ),
    );
  }

  /// 顯示警告 Toast
  void showWarning(String message, {Duration? duration, ToastAction? action}) {
    _showToast(
      ToastMessage(
        message: message,
        type: ToastType.warning,
        duration: duration ?? const Duration(seconds: 4),
        action: action,
      ),
    );
  }

  /// 顯示錯誤 Toast
  void showError(String message, {Duration? duration, ToastAction? action}) {
    _showToast(
      ToastMessage(
        message: message,
        type: ToastType.error,
        duration: duration ?? const Duration(seconds: 5),
        action: action,
      ),
    );
  }

  /// 顯示自訂 Toast
  void showCustom(ToastMessage toast) {
    _showToast(toast);
  }

  /// 隱藏當前 Toast
  void hide() {
    state = null;
  }

  /// 內部方法：顯示 Toast
  void _showToast(ToastMessage toast) {
    state = toast;

    // 自動隱藏
    Future.delayed(toast.duration, () {
      if (state == toast) {
        hide();
      }
    });
  }
}

/// Toast Presenter Provider
final toastPresenterProvider =
    StateNotifierProvider<ToastPresenter, ToastMessage?>((ref) {
      return ToastPresenter();
    });

/// Toast 樣式配置
class ToastStyleConfig {
  ToastStyleConfig._();

  /// 獲取 Toast 類型對應的顏色
  static Color getBackgroundColor(ToastType type, Brightness brightness) {
    switch (type) {
      case ToastType.info:
        return brightness == Brightness.light
            ? AppColors.infoLight
            : AppColors.info.withOpacity(0.2);
      case ToastType.success:
        return brightness == Brightness.light
            ? AppColors.successLight
            : AppColors.success.withOpacity(0.2);
      case ToastType.warning:
        return brightness == Brightness.light
            ? AppColors.warningLight
            : AppColors.warning.withOpacity(0.2);
      case ToastType.error:
        return brightness == Brightness.light
            ? AppColors.errorLight
            : AppColors.error.withOpacity(0.2);
    }
  }

  /// 獲取 Toast 類型對應的文字顏色
  static Color getTextColor(ToastType type) {
    switch (type) {
      case ToastType.info:
        return AppColors.info;
      case ToastType.success:
        return AppColors.success;
      case ToastType.warning:
        return AppColors.warning;
      case ToastType.error:
        return AppColors.error;
    }
  }

  /// 獲取 Toast 類型對應的圖示
  static IconData getIcon(ToastType type) {
    switch (type) {
      case ToastType.info:
        return Icons.info_outline;
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.warning:
        return Icons.warning_amber_outlined;
      case ToastType.error:
        return Icons.error_outline;
    }
  }

  /// 獲取 Toast 類型對應的語義標籤
  static String getSemanticLabel(ToastType type) {
    switch (type) {
      case ToastType.info:
        return '資訊';
      case ToastType.success:
        return '成功';
      case ToastType.warning:
        return '警告';
      case ToastType.error:
        return '錯誤';
    }
  }
}

/// Toast Widget
///
/// 實際顯示 Toast 訊息的 Widget
class ToastWidget extends ConsumerWidget {
  const ToastWidget({super.key, required this.toast, this.onDismiss});

  /// Toast 訊息
  final ToastMessage toast;

  /// 關閉回調
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    final backgroundColor = ToastStyleConfig.getBackgroundColor(
      toast.type,
      brightness,
    );
    final textColor = ToastStyleConfig.getTextColor(toast.type);
    final icon = ToastStyleConfig.getIcon(toast.type);
    final semanticLabel = ToastStyleConfig.getSemanticLabel(toast.type);

    return Semantics(
      label: '$semanticLabel: ${toast.message}',
      child: Container(
        margin: AppDimensions.paddingMedium,
        padding: AppDimensions.paddingMedium,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: textColor.withOpacity(0.3),
            width: AppDimensions.borderThin,
          ),
          boxShadow: AppDimensions.shadowMedium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 圖示
            Icon(icon, color: textColor, size: AppDimensions.iconMedium),

            const SizedBox(width: AppDimensions.space3),

            // 訊息文字
            Expanded(
              child: Text(
                toast.message,
                style: AppTextStyles.adaptToTheme(
                  AppTextStyles.bodyMedium,
                  brightness,
                ).copyWith(color: textColor),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 動作按鈕
            if (toast.action != null) ...[
              const SizedBox(width: AppDimensions.space3),
              TextButton(
                onPressed: toast.action!.onPressed,
                style: TextButton.styleFrom(
                  foregroundColor: textColor,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space3,
                    vertical: AppDimensions.space2,
                  ),
                ),
                child: Text(
                  toast.action!.label,
                  style: AppTextStyles.labelMedium.copyWith(color: textColor),
                ),
              ),
            ],

            // 關閉按鈕
            const SizedBox(width: AppDimensions.space2),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.space1),
                child: Icon(
                  Icons.close,
                  color: textColor.withOpacity(0.7),
                  size: AppDimensions.iconSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Toast 顯示輔助方法
class ToastHelper {
  ToastHelper._();

  /// 在指定 context 中顯示 SnackBar 形式的 Toast
  static void showSnackBar(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration? duration,
    ToastAction? action,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 清除之前的 SnackBar
    scaffoldMessenger.clearSnackBars();

    final textColor = ToastStyleConfig.getTextColor(type);
    final backgroundColor = ToastStyleConfig.getBackgroundColor(
      type,
      Theme.of(context).brightness,
    );

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              ToastStyleConfig.getIcon(type),
              color: textColor,
              size: AppDimensions.iconMedium,
            ),
            const SizedBox(width: AppDimensions.space3),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(color: textColor),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        action: action != null
            ? SnackBarAction(
                label: action.label,
                textColor: textColor,
                onPressed: action.onPressed,
              )
            : null,
      ),
    );
  }
}

/// Toast Provider 的便利擴展
extension ToastProviderExtension on WidgetRef {
  /// 獲取 Toast Presenter
  ToastPresenter get toast => read(toastPresenterProvider.notifier);

  /// 監聽當前 Toast 訊息
  ToastMessage? get currentToast => watch(toastPresenterProvider);

  /// 顯示資訊 Toast
  void showInfoToast(
    String message, {
    Duration? duration,
    ToastAction? action,
  }) {
    toast.showInfo(message, duration: duration, action: action);
  }

  /// 顯示成功 Toast
  void showSuccessToast(
    String message, {
    Duration? duration,
    ToastAction? action,
  }) {
    toast.showSuccess(message, duration: duration, action: action);
  }

  /// 顯示警告 Toast
  void showWarningToast(
    String message, {
    Duration? duration,
    ToastAction? action,
  }) {
    toast.showWarning(message, duration: duration, action: action);
  }

  /// 顯示錯誤 Toast
  void showErrorToast(
    String message, {
    Duration? duration,
    ToastAction? action,
  }) {
    toast.showError(message, duration: duration, action: action);
  }

  /// 隱藏 Toast
  void hideToast() {
    toast.hide();
  }
}
