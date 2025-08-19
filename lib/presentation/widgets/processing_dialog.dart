import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_creation/view_models/ocr_processing_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 名片處理對話框
///
/// 顯示名片處理進度，包含：
/// - OCR 文字識別
/// - AI/本地解析
/// - 圖片壓縮
class ProcessingDialog extends ConsumerWidget {
  const ProcessingDialog({super.key});

  static Future<T?> show<T>(BuildContext context) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ProcessingDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ocrProcessingViewModelProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.space4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題
            const Text('處理名片中', style: AppTextStyles.headline2),
            const SizedBox(height: AppDimensions.space6),

            // 進度指示器
            _buildProgressIndicator(state),
            const SizedBox(height: AppDimensions.space6),

            // 步驟說明
            _buildStepDescription(state),
            const SizedBox(height: AppDimensions.space4),

            // 處理詳情
            _buildProcessingDetails(state),

            // 錯誤訊息
            if (state.error != null) ...[
              const SizedBox(height: AppDimensions.space4),
              _buildErrorMessage(state.error!),
            ],

            // 警告訊息
            if (state.warnings.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space4),
              _buildWarningMessage(state.warnings.first),
            ],
          ],
        ),
      ),
    );
  }

  /// 建立進度指示器
  Widget _buildProgressIndicator(OCRProcessingState state) {
    // 計算進度
    double progress = 0;
    switch (state.processingStep) {
      case OCRProcessingStep.idle:
        progress = 0.0;
        break;
      case OCRProcessingStep.imageLoaded:
        progress = 0.2;
        break;
      case OCRProcessingStep.ocrProcessing:
        progress = 0.4;
        break;
      case OCRProcessingStep.ocrCompleted:
        progress = 0.6;
        break;
      case OCRProcessingStep.aiProcessing:
        progress = 0.8;
        break;
      case OCRProcessingStep.completed:
        progress = 1.0;
        break;
    }

    return Column(
      children: [
        // 圓形進度指示器
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: state.isLoadingFromStep ? null : progress,
                strokeWidth: 6,
                backgroundColor: AppColors.separator,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
            // 百分比文字
            if (!state.isLoadingFromStep)
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.space4),

        // 線性進度條
        LinearProgressIndicator(
          value: state.isLoadingFromStep ? null : progress,
          backgroundColor: AppColors.separator,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ],
    );
  }

  /// 建立步驟說明
  Widget _buildStepDescription(OCRProcessingState state) {
    String description;
    IconData icon;

    switch (state.processingStep) {
      case OCRProcessingStep.idle:
        description = '準備中...';
        icon = Icons.hourglass_empty;
        break;
      case OCRProcessingStep.imageLoaded:
        description = '圖片已載入';
        icon = Icons.image;
        break;
      case OCRProcessingStep.ocrProcessing:
        description = '正在識別文字...';
        icon = Icons.text_fields;
        break;
      case OCRProcessingStep.ocrCompleted:
        description = '文字識別完成';
        icon = Icons.check_circle_outline;
        break;
      case OCRProcessingStep.aiProcessing:
        description = state.parseSource == ParseSource.ai
            ? 'AI 正在解析名片資訊...'
            : '正在解析名片資訊...';
        icon = Icons.psychology;
        break;
      case OCRProcessingStep.completed:
        description = '處理完成！';
        icon = Icons.check_circle;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: state.processingStep == OCRProcessingStep.completed
              ? AppColors.success
              : AppColors.primary,
          size: 24,
        ),
        const SizedBox(width: AppDimensions.space3),
        Text(description, style: AppTextStyles.bodyLarge),
      ],
    );
  }

  /// 建立處理詳情
  Widget _buildProcessingDetails(OCRProcessingState state) {
    final details = <String>[];

    // OCR 信心度
    if (state.confidence != null) {
      final confidencePercent = (state.confidence! * 100).toInt();
      details.add('識別信心度: $confidencePercent%');
    }

    // 解析來源
    if (state.parseSource != null) {
      final source = state.parseSource == ParseSource.ai ? 'AI 智慧解析' : '本地解析';
      details.add('解析方式: $source');
    }

    // 已識別的文字長度
    if (state.ocrResult != null) {
      final textLength = state.ocrResult!.rawText.length;
      details.add('識別文字: $textLength 字元');
    }

    if (details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space3),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppDimensions.space2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: details
            .map(
              (detail) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.space1,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: AppDimensions.space2),
                    Text(
                      detail,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  /// 建立錯誤訊息
  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space3),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.space2),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppDimensions.space2),
          Expanded(
            child: Text(
              error,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// 建立警告訊息
  Widget _buildWarningMessage(String warning) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space3),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.space2),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
          const SizedBox(width: AppDimensions.space2),
          Expanded(
            child: Text(
              warning,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

/// 步驟指示器元件
class ProcessingStepIndicator extends StatelessWidget {
  const ProcessingStepIndicator({
    required this.steps,
    required this.currentStep,
    super.key,
  });

  final List<String> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(steps.length * 2 - 1, (index) {
        // 偶數是步驟，奇數是連接線
        if (index.isEven) {
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final isActive = stepIndex == currentStep;

          return _buildStep(
            steps[stepIndex],
            stepIndex + 1,
            isCompleted: isCompleted,
            isActive: isActive,
          );
        } else {
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;

          return _buildConnector(isCompleted: isCompleted);
        }
      }),
    );
  }

  Widget _buildStep(
    String label,
    int number, {
    required bool isCompleted,
    required bool isActive,
  }) {
    Color color;
    Widget icon;

    if (isCompleted) {
      color = AppColors.success;
      icon = const Icon(Icons.check, color: Colors.white, size: 16);
    } else if (isActive) {
      color = AppColors.primary;
      icon = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else {
      color = AppColors.separator;
      icon = Text(
        number.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(child: icon),
        ),
        const SizedBox(height: AppDimensions.space1),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isActive || isCompleted
                ? AppColors.primaryText
                : AppColors.secondaryText,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector({required bool isCompleted}) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isCompleted ? AppColors.success : AppColors.separator,
    );
  }
}
