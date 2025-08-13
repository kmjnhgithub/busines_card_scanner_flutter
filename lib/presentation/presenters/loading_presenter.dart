import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';

/// 載入狀態類型
enum LoadingType {
  /// 一般載入
  normal,

  /// 上傳檔案
  uploading,

  /// 下載檔案
  downloading,

  /// 處理中
  processing,

  /// 同步中
  syncing,

  /// 自訂載入
  custom,
}

/// 載入狀態配置
@immutable
class LoadingState {
  const LoadingState({
    required this.isLoading,
    this.message,
    this.type = LoadingType.normal,
    this.progress,
    this.canCancel = false,
    this.onCancel,
  });

  /// 是否正在載入
  final bool isLoading;

  /// 載入訊息
  final String? message;

  /// 載入類型
  final LoadingType type;

  /// 載入進度 (0.0 - 1.0)，null 表示不顯示進度
  final double? progress;

  /// 是否可以取消
  final bool canCancel;

  /// 取消回調
  final VoidCallback? onCancel;

  /// 建立不載入狀態
  static const LoadingState idle = LoadingState(isLoading: false);

  /// 建立基本載入狀態
  static LoadingState loading([String? message]) {
    return LoadingState(isLoading: true, message: message);
  }

  /// 建立帶進度的載入狀態
  static LoadingState withProgress({
    String? message,
    required double progress,
    LoadingType type = LoadingType.normal,
    bool canCancel = false,
    VoidCallback? onCancel,
  }) {
    return LoadingState(
      isLoading: true,
      message: message,
      type: type,
      progress: progress,
      canCancel: canCancel,
      onCancel: onCancel,
    );
  }

  /// 建立可取消的載入狀態
  static LoadingState cancellable({
    String? message,
    LoadingType type = LoadingType.normal,
    required VoidCallback onCancel,
  }) {
    return LoadingState(
      isLoading: true,
      message: message,
      type: type,
      canCancel: true,
      onCancel: onCancel,
    );
  }

  /// 複製並更新載入狀態
  LoadingState copyWith({
    bool? isLoading,
    String? message,
    LoadingType? type,
    double? progress,
    bool? canCancel,
    VoidCallback? onCancel,
  }) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      type: type ?? this.type,
      progress: progress ?? this.progress,
      canCancel: canCancel ?? this.canCancel,
      onCancel: onCancel ?? this.onCancel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadingState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          message == other.message &&
          type == other.type &&
          progress == other.progress &&
          canCancel == other.canCancel;

  @override
  int get hashCode =>
      isLoading.hashCode ^
      message.hashCode ^
      type.hashCode ^
      progress.hashCode ^
      canCancel.hashCode;

  @override
  String toString() {
    return 'LoadingState(isLoading: $isLoading, message: $message, type: $type, progress: $progress, canCancel: $canCancel)';
  }
}

/// Loading Presenter
///
/// 負責管理應用程式中的載入狀態
/// 提供統一的載入指示器和進度管理
class LoadingPresenter extends StateNotifier<LoadingState> {
  LoadingPresenter() : super(LoadingState.idle);

  /// 顯示基本載入
  void show([String? message]) {
    state = LoadingState.loading(message);
  }

  /// 顯示帶類型的載入
  void showWithType(LoadingType type, [String? message]) {
    state = LoadingState(isLoading: true, message: message, type: type);
  }

  /// 顯示帶進度的載入
  void showWithProgress({
    String? message,
    required double progress,
    LoadingType type = LoadingType.normal,
    bool canCancel = false,
    VoidCallback? onCancel,
  }) {
    state = LoadingState.withProgress(
      message: message,
      progress: progress,
      type: type,
      canCancel: canCancel,
      onCancel: onCancel,
    );
  }

  /// 顯示可取消的載入
  void showCancellable({
    String? message,
    LoadingType type = LoadingType.normal,
    required VoidCallback onCancel,
  }) {
    state = LoadingState.cancellable(
      message: message,
      type: type,
      onCancel: onCancel,
    );
  }

  /// 更新載入訊息
  void updateMessage(String message) {
    if (state.isLoading) {
      state = state.copyWith(message: message);
    }
  }

  /// 更新載入進度
  void updateProgress(double progress) {
    if (state.isLoading) {
      state = state.copyWith(progress: progress);
    }
  }

  /// 更新載入訊息和進度
  void updateMessageAndProgress(String message, double progress) {
    if (state.isLoading) {
      state = state.copyWith(message: message, progress: progress);
    }
  }

  /// 隱藏載入
  void hide() {
    state = LoadingState.idle;
  }

  /// 檢查是否正在載入
  bool get isLoading => state.isLoading;

  /// 獲取當前載入訊息
  String? get currentMessage => state.message;

  /// 獲取當前載入進度
  double? get currentProgress => state.progress;
}

/// Loading Presenter Provider
final loadingPresenterProvider =
    StateNotifierProvider<LoadingPresenter, LoadingState>((ref) {
      return LoadingPresenter();
    });

/// 載入樣式配置
class LoadingStyleConfig {
  LoadingStyleConfig._();

  /// 獲取載入類型對應的顏色
  static Color getAccentColor(LoadingType type) {
    switch (type) {
      case LoadingType.normal:
        return AppColors.primary;
      case LoadingType.uploading:
        return AppColors.info;
      case LoadingType.downloading:
        return AppColors.success;
      case LoadingType.processing:
        return AppColors.warning;
      case LoadingType.syncing:
        return AppColors.secondary;
      case LoadingType.custom:
        return AppColors.primary;
    }
  }

  /// 獲取載入類型對應的圖示
  static IconData getIcon(LoadingType type) {
    switch (type) {
      case LoadingType.normal:
        return Icons.hourglass_empty;
      case LoadingType.uploading:
        return Icons.cloud_upload_outlined;
      case LoadingType.downloading:
        return Icons.cloud_download_outlined;
      case LoadingType.processing:
        return Icons.memory;
      case LoadingType.syncing:
        return Icons.sync;
      case LoadingType.custom:
        return Icons.hourglass_empty;
    }
  }

  /// 獲取載入類型對應的預設訊息
  static String getDefaultMessage(LoadingType type) {
    switch (type) {
      case LoadingType.normal:
        return '載入中...';
      case LoadingType.uploading:
        return '上傳中...';
      case LoadingType.downloading:
        return '下載中...';
      case LoadingType.processing:
        return '處理中...';
      case LoadingType.syncing:
        return '同步中...';
      case LoadingType.custom:
        return '載入中...';
    }
  }
}

/// 載入指示器 Widget
class LoadingIndicator extends ConsumerWidget {
  const LoadingIndicator({
    super.key,
    this.size = AppDimensions.loadingIndicatorSize,
    this.color,
    this.strokeWidth = 2.0,
  });

  /// 指示器尺寸
  final double size;

  /// 指示器顏色
  final Color? color;

  /// 線條寬度
  final double strokeWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingState = ref.watch(loadingPresenterProvider);

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? LoadingStyleConfig.getAccentColor(loadingState.type),
        value: loadingState.progress,
      ),
    );
  }
}

/// 全螢幕載入覆蓋層 Widget
class LoadingOverlay extends ConsumerWidget {
  const LoadingOverlay({super.key, required this.child, this.backgroundColor});

  /// 子 Widget
  final Widget child;

  /// 覆蓋層背景顏色
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingState = ref.watch(loadingPresenterProvider);

    return Stack(
      children: [
        child,
        if (loadingState.isLoading)
          Container(
            color: backgroundColor ?? AppColors.scannerOverlay.withValues(alpha: 0.5),
            child: Center(child: LoadingCard(loadingState: loadingState)),
          ),
      ],
    );
  }
}

/// 載入卡片 Widget
class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key, required this.loadingState});

  final LoadingState loadingState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = LoadingStyleConfig.getAccentColor(loadingState.type);
    final message =
        loadingState.message ??
        LoadingStyleConfig.getDefaultMessage(loadingState.type);

    return Card(
      margin: AppDimensions.paddingLarge,
      child: Padding(
        padding: AppDimensions.paddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 載入指示器
            SizedBox(
              width: AppDimensions.loadingIndicatorSizeLarge,
              height: AppDimensions.loadingIndicatorSizeLarge,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                color: accentColor,
                value: loadingState.progress,
              ),
            ),

            const SizedBox(height: AppDimensions.space4),

            // 載入訊息
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.brightness == Brightness.light
                    ? AppColors.primaryText
                    : AppColors.primaryTextDark,
              ),
              textAlign: TextAlign.center,
            ),

            // 進度百分比
            if (loadingState.progress != null) ...[
              const SizedBox(height: AppDimensions.space2),
              Text(
                '${(loadingState.progress! * 100).toInt()}%',
                style: AppTextStyles.labelMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            // 取消按鈕
            if (loadingState.canCancel && loadingState.onCancel != null) ...[
              const SizedBox(height: AppDimensions.space4),
              TextButton(
                onPressed: loadingState.onCancel,
                child: Text(
                  '取消',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 內聯載入指示器 Widget
class InlineLoadingIndicator extends ConsumerWidget {
  const InlineLoadingIndicator({
    super.key,
    this.message,
    this.size = AppDimensions.iconMedium,
  });

  /// 載入訊息
  final String? message;

  /// 指示器尺寸
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadingState = ref.watch(loadingPresenterProvider);

    if (!loadingState.isLoading) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: LoadingStyleConfig.getAccentColor(loadingState.type),
          ),
        ),
        if (message != null) ...[
          const SizedBox(width: AppDimensions.space2),
          Text(
            message!,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).brightness == Brightness.light
                  ? AppColors.secondaryText
                  : AppColors.secondaryTextDark,
            ),
          ),
        ],
      ],
    );
  }
}

/// Loading Provider 的便利擴展
extension LoadingProviderExtension on WidgetRef {
  /// 獲取 Loading Presenter
  LoadingPresenter get loading => read(loadingPresenterProvider.notifier);

  /// 監聽當前載入狀態
  LoadingState get loadingState => watch(loadingPresenterProvider);

  /// 檢查是否正在載入
  bool get isLoading => loadingState.isLoading;

  /// 顯示載入
  void showLoading([String? message]) {
    loading.show(message);
  }

  /// 顯示帶類型的載入
  void showLoadingWithType(LoadingType type, [String? message]) {
    loading.showWithType(type, message);
  }

  /// 顯示帶進度的載入
  void showLoadingWithProgress({
    String? message,
    required double progress,
    LoadingType type = LoadingType.normal,
    bool canCancel = false,
    VoidCallback? onCancel,
  }) {
    loading.showWithProgress(
      message: message,
      progress: progress,
      type: type,
      canCancel: canCancel,
      onCancel: onCancel,
    );
  }

  /// 顯示可取消的載入
  void showCancellableLoading({
    String? message,
    LoadingType type = LoadingType.normal,
    required VoidCallback onCancel,
  }) {
    loading.showCancellable(message: message, type: type, onCancel: onCancel);
  }

  /// 更新載入訊息
  void updateLoadingMessage(String message) {
    loading.updateMessage(message);
  }

  /// 更新載入進度
  void updateLoadingProgress(double progress) {
    loading.updateProgress(progress);
  }

  /// 隱藏載入
  void hideLoading() {
    loading.hide();
  }
}
