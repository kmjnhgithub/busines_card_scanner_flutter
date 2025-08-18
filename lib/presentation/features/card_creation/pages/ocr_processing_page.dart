import 'dart:io';

import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_creation/view_models/ocr_processing_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/router/app_routes.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_button.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// OCR 處理頁面
///
/// 功能包括：
/// - 圖片預覽
/// - OCR 文字識別進度
/// - AI 解析進度
/// - 文字編輯功能
/// - 名片預覽
/// - 處理完成導航
class OCRProcessingPage extends ConsumerStatefulWidget {
  const OCRProcessingPage({required this.imagePath, super.key});

  final String imagePath;

  @override
  ConsumerState<OCRProcessingPage> createState() => _OCRProcessingPageState();
}

class _OCRProcessingPageState extends ConsumerState<OCRProcessingPage> {
  final TextEditingController _textEditController = TextEditingController();
  bool _isEditingText = false;

  @override
  void initState() {
    super.initState();

    // 頁面初始化時載入圖片
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadImageData();
    });
  }

  @override
  void dispose() {
    _textEditController.dispose();
    super.dispose();
  }

  /// 載入圖片資料
  Future<void> _loadImageData() async {
    try {
      // 解碼URL編碼的路徑
      final decodedPath = Uri.decodeComponent(widget.imagePath);
      final imageFile = File(decodedPath);
      final imageData = await imageFile.readAsBytes();
      await ref
          .read(ocrProcessingViewModelProvider.notifier)
          .loadImage(imageData);
    } on Exception catch (e) {
      debugPrint('載入圖片失敗: $e');
    }
  }

  /// 處理文字編輯
  void _handleTextEdit() {
    final state = ref.read(ocrProcessingViewModelProvider);
    _textEditController.text = state.ocrResult?.rawText ?? '';

    setState(() {
      _isEditingText = true;
    });
  }

  /// 確認文字編輯
  void _confirmTextEdit() {
    final newText = _textEditController.text;
    ref.read(ocrProcessingViewModelProvider.notifier).updateOCRText(newText);

    setState(() {
      _isEditingText = false;
    });
  }

  /// 取消文字編輯
  void _cancelTextEdit() {
    setState(() {
      _isEditingText = false;
    });
  }

  /// 導航到編輯頁面
  void _navigateToEditPage(BusinessCard businessCard) {
    // 名片保存成功，返回名片列表頁面
    // 可以選擇導航到名片詳情頁面或直接返回列表
    context.go(AppRoutes.cardList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('處理名片'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(ocrProcessingViewModelProvider);

          return SafeArea(
            child: Column(
              children: [
                // 進度步驟指示器
                _buildProgressSteps(state),

                // 內容區域
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.space4),
                    child: Column(
                      children: [
                        // 圖片預覽
                        _buildImagePreview(),

                        const SizedBox(height: AppDimensions.space6),

                        // 主要內容區域
                        _buildMainContent(state),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 建立進度步驟指示器
  Widget _buildProgressSteps(OCRProcessingState state) {
    return ThemedCard(
      key: const Key('progress_steps'),
      margin: const EdgeInsets.all(AppDimensions.space4),
      child: Row(
        children: [
          _buildStepItem(1, '圖片載入', _getStepStatus(state, 1)),
          _buildStepConnector(),
          _buildStepItem(2, '文字識別', _getStepStatus(state, 2)),
          _buildStepConnector(),
          _buildStepItem(3, 'AI 解析', _getStepStatus(state, 3)),
        ],
      ),
    );
  }

  /// 建立單個步驟項目
  Widget _buildStepItem(int step, String title, StepStatus status) {
    Color color;
    Widget icon;

    switch (status) {
      case StepStatus.completed:
        color = AppColors.success;
        icon = const Icon(Icons.check, color: Colors.white, size: 16);
        break;
      case StepStatus.active:
        color = AppColors.primary;
        icon = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
        break;
      case StepStatus.pending:
        color = AppColors.separator;
        icon = Text(
          step.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
        break;
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(child: icon),
          ),
          const SizedBox(height: AppDimensions.space2),
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: status == StepStatus.pending
                  ? AppColors.secondaryText
                  : AppColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 建立步驟連接器
  Widget _buildStepConnector() {
    return Container(
      width: 32,
      height: 2,
      color: AppColors.separator,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.space2),
    );
  }

  /// 獲取步驟狀態
  StepStatus _getStepStatus(OCRProcessingState state, int step) {
    switch (step) {
      case 1: // 圖片載入
        if (state.processingStep == OCRProcessingStep.idle) {
          return StepStatus.active;
        } else if (state.processingStep.index >=
            OCRProcessingStep.imageLoaded.index) {
          return StepStatus.completed;
        } else {
          return StepStatus.pending;
        }

      case 2: // 文字識別
        if (state.processingStep == OCRProcessingStep.ocrProcessing) {
          return StepStatus.active;
        } else if (state.processingStep.index >=
            OCRProcessingStep.ocrCompleted.index) {
          return StepStatus.completed;
        } else {
          return StepStatus.pending;
        }

      case 3: // AI 解析
        if (state.processingStep == OCRProcessingStep.aiProcessing) {
          return StepStatus.active;
        } else if (state.processingStep == OCRProcessingStep.completed) {
          return StepStatus.completed;
        } else {
          return StepStatus.pending;
        }

      default:
        return StepStatus.pending;
    }
  }

  /// 建立圖片預覽
  Widget _buildImagePreview() {
    return ThemedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('圖片預覽', style: AppTextStyles.headline3),
          const SizedBox(height: AppDimensions.space3),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.space3),
            child: Semantics(
              label: '名片圖片預覽',
              child: Image.file(
                key: const Key('image_preview'),
                File(widget.imagePath),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Semantics(
                    label: '名片圖片預覽',
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      color: AppColors.separator,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 48,
                            color: AppColors.secondaryText,
                          ),
                          SizedBox(height: AppDimensions.space3),
                          Text('圖片載入失敗', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 建立主要內容區域
  Widget _buildMainContent(OCRProcessingState state) {
    // 錯誤狀態
    if (state.error != null) {
      return _buildErrorView(state.error!);
    }

    // 根據步驟顯示不同內容
    switch (state.processingStep) {
      case OCRProcessingStep.idle:
        return _buildInitialView();

      case OCRProcessingStep.imageLoaded:
        return _buildImageLoadedView();

      case OCRProcessingStep.ocrProcessing:
        return _buildOCRProcessingView();

      case OCRProcessingStep.ocrCompleted:
        return _buildOCRCompletedView(state);

      case OCRProcessingStep.aiProcessing:
        return _buildAIProcessingView(state);

      case OCRProcessingStep.completed:
        return _buildCompletedView(state);
    }
  }

  /// 建立初始視圖
  Widget _buildInitialView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppDimensions.space4),
          Text('載入圖片中...'),
        ],
      ),
    );
  }

  /// 建立圖片載入完成視圖
  Widget _buildImageLoadedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo, size: 64, color: AppColors.primary),
          const SizedBox(height: AppDimensions.space6),
          const Text('圖片載入完成', style: AppTextStyles.headline3),
          const SizedBox(height: AppDimensions.space3),
          const Text('點擊開始處理按鈕進行文字識別', style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppDimensions.space8),
          ThemedButton(
            key: const Key('start_processing_button'),
            text: '開始處理',
            onPressed: () =>
                ref.read(ocrProcessingViewModelProvider.notifier).processOCR(),
          ),
        ],
      ),
    );
  }

  /// 建立 OCR 處理中視圖
  Widget _buildOCRProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(label: '文字識別進度', child: const CircularProgressIndicator()),
          const SizedBox(height: AppDimensions.space6),
          const Text('文字識別中...', style: AppTextStyles.headline3),
          const SizedBox(height: AppDimensions.space3),
          const Text('正在從圖片中識別文字內容', style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppDimensions.space6),
          const LinearProgressIndicator(),
        ],
      ),
    );
  }

  /// 建立 OCR 完成視圖
  Widget _buildOCRCompletedView(OCRProcessingState state) {
    return Column(
      children: [
        // 低信心度警告
        if (state.confidence != null && state.confidence! < 0.7)
          _buildLowConfidenceWarning(),

        // 識別文字顯示
        ThemedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('識別文字', style: AppTextStyles.headline3),
                  IconButton(
                    key: const Key('edit_text_button'),
                    onPressed: _handleTextEdit,
                    icon: const Icon(Icons.edit),
                    tooltip: '編輯文字',
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space3),
              if (_isEditingText)
                _buildTextEditor()
              else
                _buildTextDisplay(state),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.space6),

        // 操作按鈕
        _buildOCRCompletedActions(),
      ],
    );
  }

  /// 建立低信心度警告
  Widget _buildLowConfidenceWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space4),
      padding: const EdgeInsets.all(AppDimensions.space4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.space3),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppColors.warning, size: 24),
          const SizedBox(width: AppDimensions.space3),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('識別信心度較低', style: AppTextStyles.labelLarge),
                Text('建議重新拍攝或手動編輯文字', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          TextButton(
            key: const Key('retake_photo_button'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('重新拍攝'),
          ),
        ],
      ),
    );
  }

  /// 建立文字顯示
  Widget _buildTextDisplay(OCRProcessingState state) {
    return Container(
      key: const Key('raw_text_display'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space3),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppDimensions.space2),
      ),
      child: Text(
        state.ocrResult?.rawText ?? '無識別文字',
        style: AppTextStyles.bodyMedium,
      ),
    );
  }

  /// 建立文字編輯器
  Widget _buildTextEditor() {
    return Column(
      children: [
        TextField(
          key: const Key('text_editor'),
          controller: _textEditController,
          maxLines: 6,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '編輯識別的文字內容...',
          ),
        ),
        const SizedBox(height: AppDimensions.space3),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: _cancelTextEdit, child: const Text('取消')),
            const SizedBox(width: AppDimensions.space3),
            ElevatedButton(
              key: const Key('confirm_edit_button'),
              onPressed: _confirmTextEdit,
              child: const Text('確定'),
            ),
          ],
        ),
      ],
    );
  }

  /// 建立 OCR 完成操作按鈕
  Widget _buildOCRCompletedActions() {
    return Row(
      children: [
        Expanded(
          child: ThemedButton(
            key: const Key('reprocess_ai_button'),
            text: '重新 AI 解析',
            onPressed: () =>
                ref.read(ocrProcessingViewModelProvider.notifier).parseWithAI(),
          ),
        ),
        const SizedBox(width: AppDimensions.space4),
        Expanded(
          child: ThemedButton(
            key: const Key('complete_processing_button'),
            text: '完成處理',
            onPressed: () =>
                ref.read(ocrProcessingViewModelProvider.notifier).parseWithAI(),
          ),
        ),
      ],
    );
  }

  /// 建立 AI 處理中視圖
  Widget _buildAIProcessingView(OCRProcessingState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.psychology, size: 64, color: AppColors.primary),
          const SizedBox(height: AppDimensions.space6),
          const Text('AI 解析中...', style: AppTextStyles.headline3),
          const SizedBox(height: AppDimensions.space3),
          const Text('正在使用 AI 分析名片資訊', style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppDimensions.space6),
          const LinearProgressIndicator(),

          // 顯示識別的文字（僅供參考）
          if (state.ocrResult != null) ...[
            const SizedBox(height: AppDimensions.space8),
            ThemedCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('識別文字（供參考）', style: AppTextStyles.subtitle1),
                  const SizedBox(height: AppDimensions.space3),
                  Text(
                    state.ocrResult!.rawText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondaryText,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 建立完成視圖
  Widget _buildCompletedView(OCRProcessingState state) {
    return Column(
      children: [
        // 成功圖示
        const Icon(Icons.check_circle, size: 64, color: AppColors.success),
        const SizedBox(height: AppDimensions.space6),
        const Text('處理完成', style: AppTextStyles.headline2),
        const SizedBox(height: AppDimensions.space3),
        const Text('名片資訊已成功解析', style: AppTextStyles.bodyMedium),

        const SizedBox(height: AppDimensions.space8),

        // 名片預覽
        if (state.parsedCard != null)
          _buildBusinessCardPreview(state.parsedCard!),

        const SizedBox(height: AppDimensions.space8),

        // 保存按鈕
        SizedBox(
          width: double.infinity,
          child: Semantics(
            label: '保存名片',
            button: true,
            child: ThemedButton(
              key: const Key('save_card_button'),
              text: '保存名片',
              onPressed: () => _navigateToEditPage(state.parsedCard!),
            ),
          ),
        ),
      ],
    );
  }

  /// 建立名片預覽
  Widget _buildBusinessCardPreview(BusinessCard businessCard) {
    return ThemedCard(
      key: const Key('business_card_preview'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('名片預覽', style: AppTextStyles.headline3),
          const SizedBox(height: AppDimensions.space4),

          // 姓名
          if (businessCard.name.isNotEmpty) ...[
            _buildInfoRow(Icons.person, '姓名', businessCard.name),
            const SizedBox(height: AppDimensions.space3),
          ],

          // 職稱
          if (businessCard.jobTitle?.isNotEmpty == true) ...[
            _buildInfoRow(Icons.work, '職稱', businessCard.jobTitle!),
            const SizedBox(height: AppDimensions.space3),
          ],

          // 公司
          if (businessCard.company?.isNotEmpty == true) ...[
            _buildInfoRow(Icons.business, '公司', businessCard.company!),
            const SizedBox(height: AppDimensions.space3),
          ],

          // 電話
          if (businessCard.phone?.isNotEmpty == true) ...[
            _buildInfoRow(Icons.phone, '電話', businessCard.phone!),
            const SizedBox(height: AppDimensions.space3),
          ],

          // Email
          if (businessCard.email?.isNotEmpty == true) ...[
            _buildInfoRow(Icons.email, 'Email', businessCard.email!),
          ],
        ],
      ),
    );
  }

  /// 建立資訊行
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppDimensions.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  /// 建立錯誤視圖
  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppDimensions.space6),
          const Text('處理失敗', style: AppTextStyles.headline3),
          const SizedBox(height: AppDimensions.space3),
          Text(
            error,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.space8),
          ThemedButton(
            key: const Key('retry_button'),
            text: '重試',
            onPressed: () =>
                ref.read(ocrProcessingViewModelProvider.notifier).resetState(),
          ),
        ],
      ),
    );
  }
}

/// 步驟狀態
enum StepStatus { pending, active, completed }
