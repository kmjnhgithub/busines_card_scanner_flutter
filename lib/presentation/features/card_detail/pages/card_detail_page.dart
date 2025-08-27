import 'dart:io';

import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_detail/view_models/card_detail_state.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_detail/view_models/card_detail_view_model_basic.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_button.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 名片詳情頁面
///
/// 支援四種模式：
/// - 檢視模式：唯讀顯示既有名片
/// - 編輯模式：修改既有名片資料
/// - 新增模式：OCR 結果預填，可編輯
/// - 手動模式：空白表單建立
class CardDetailPage extends ConsumerStatefulWidget {
  const CardDetailPage({
    super.key,
    this.cardId,
    this.mode = CardDetailMode.viewing,
    this.ocrParsedCard,
  });

  /// 名片 ID（檢視和編輯模式必需）
  final String? cardId;

  /// 頁面模式
  final CardDetailMode mode;

  /// OCR 解析的名片資料（新增模式使用）
  final BusinessCard? ocrParsedCard;

  @override
  ConsumerState<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends ConsumerState<CardDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _companyController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _websiteController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();

    // 初始化控制器
    _nameController = TextEditingController();
    _jobTitleController = TextEditingController();
    _companyController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _websiteController = TextEditingController();
    _notesController = TextEditingController();

    // 頁面初始化後初始化 ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeViewModel();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// 初始化 ViewModel
  void _initializeViewModel() {
    final viewModel = ref.read(cardDetailViewModelBasicProvider.notifier);

    // 除錯資訊
    debugPrint('CardDetailPage 初始化:');
    debugPrint('  mode: ${widget.mode}');
    debugPrint('  cardId: ${widget.cardId}');
    debugPrint('  ocrParsedCard: ${widget.ocrParsedCard?.name ?? '無'}');

    switch (widget.mode) {
      case CardDetailMode.viewing:
        if (widget.cardId != null) {
          viewModel.initializeViewing(widget.cardId!);
        }
        break;
      case CardDetailMode.editing:
        if (widget.cardId != null) {
          viewModel.initializeViewing(widget.cardId!);
          // 載入完成後切換到編輯模式
          Future.delayed(
            const Duration(milliseconds: 600),
            viewModel.switchToEditMode,
          );
        }
        break;
      case CardDetailMode.creating:
        if (widget.ocrParsedCard != null) {
          viewModel.initializeCreating(widget.ocrParsedCard!);
        } else {
          // 如果沒有 OCR 資料，切換到手動建立模式
          debugPrint('CardDetailPage: OCR 資料為空，切換到手動建立模式');
          viewModel.initializeManual();
        }
        break;
      case CardDetailMode.manual:
        viewModel.initializeManual();
        break;
    }
  }

  /// 更新表單控制器內容
  void _updateControllers(BusinessCard card) {
    _nameController.text = card.name;
    _jobTitleController.text = card.jobTitle ?? '';
    _companyController.text = card.company ?? '';
    _emailController.text = card.email ?? '';
    _phoneController.text = card.phone ?? '';
    _addressController.text = card.address ?? '';
    _websiteController.text = card.website ?? '';
    _notesController.text = card.notes ?? '';
  }

  /// 檢查是否需要更新控制器
  bool _shouldUpdateControllers(BusinessCard card) {
    // 當控制器的值與卡片資料不一致時才更新
    return _nameController.text != card.name ||
        _jobTitleController.text != (card.jobTitle ?? '') ||
        _companyController.text != (card.company ?? '') ||
        _emailController.text != (card.email ?? '') ||
        _phoneController.text != (card.phone ?? '') ||
        _addressController.text != (card.address ?? '') ||
        _websiteController.text != (card.website ?? '') ||
        _notesController.text != (card.notes ?? '');
  }

  /// 儲存名片
  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final viewModel = ref.read(cardDetailViewModelBasicProvider.notifier);
    final success = await viewModel.saveCard();

    if (success && mounted) {
      // 儲存成功，返回列表頁面（列表頁面會自動重新載入）
      context.go('/card-list');
    }
  }

  /// 取消編輯
  void _cancel() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cardDetailViewModelBasicProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle()),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        actions: _buildAppBarActions(state),
      ),
      backgroundColor: AppColors.background,
      body: _buildBody(state),
    );
  }

  /// 取得頁面標題
  String _getPageTitle() {
    final state = ref.watch(cardDetailViewModelBasicProvider);

    return state.maybeWhen(
      (
        mode,
        isLoading,
        isSaving,
        error,
        originalCard,
        currentCard,
        validationErrors,
        hasChanges,
        ocrParsedCard,
        confidence,
        fromAIParsing,
      ) {
        switch (mode) {
          case CardDetailMode.viewing:
            return '名片詳情';
          case CardDetailMode.editing:
            return '編輯名片';
          case CardDetailMode.creating:
            return '新增名片';
          case CardDetailMode.manual:
            return '手動建立';
        }
      },
      initial: () => '初始化...',
      viewing: (card) => '名片詳情',
      editing: (originalCard, currentCard, hasChanges, validationErrors) =>
          '編輯名片',
      creating: (parsedCard, confidence, fromAIParsing, validationErrors) =>
          '新增名片',
      manual: (emptyCard, validationErrors) => '手動建立',
      loading: () => '載入中...',
      error: (message) => '錯誤',
      orElse: () => '名片詳情',
    );
  }

  /// 建立 AppBar 動作按鈕
  List<Widget> _buildAppBarActions(CardDetailState state) {
    final canEdit = ref.read(cardDetailViewModelBasicProvider.notifier).canEdit;

    return [
      if (canEdit)
        IconButton(
          onPressed: _saveCard,
          icon: const Icon(Icons.save),
          tooltip: '儲存',
        ),
    ];
  }

  /// 建立主要內容
  Widget _buildBody(CardDetailState state) {
    return state.maybeWhen(
      (
        mode,
        isLoading,
        isSaving,
        error,
        originalCard,
        currentCard,
        validationErrors,
        hasChanges,
        ocrParsedCard,
        confidence,
        fromAIParsing,
      ) => const Center(child: Text('預設狀態')),
      initial: () => const Center(child: Text('初始化中...')),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: _buildErrorView,
      viewing: (card) => _buildFormView(card, false),
      editing: (originalCard, currentCard, hasChanges, validationErrors) {
        return _buildFormView(currentCard, true);
      },
      creating: (parsedCard, confidence, fromAIParsing, validationErrors) {
        return _buildFormView(parsedCard, true);
      },
      manual: (emptyCard, validationErrors) {
        return _buildFormView(emptyCard, true);
      },
      orElse: () => const Center(child: Text('未知狀態')),
    );
  }

  /// 建立錯誤視圖
  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppDimensions.space6),
          Text(message, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppDimensions.space8),
          ThemedButton(text: '返回', onPressed: _cancel),
        ],
      ),
    );
  }

  /// 建立表單視圖
  Widget _buildFormView(BusinessCard card, bool canEdit) {
    // 只在需要時更新控制器內容（避免編輯時的無限循環）
    if (_shouldUpdateControllers(card)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateControllers(card);
      });
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space4),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 名片圖片預覽（如果有）
              if (card.imagePath != null && card.imagePath!.isNotEmpty)
                _buildImagePreview(card.imagePath!),

              // 基本資訊區塊
              _buildSectionCard('基本資訊', [
                _buildTextField(
                  '姓名 *',
                  _nameController,
                  enabled: canEdit,
                  required: true,
                  icon: Icons.person,
                ),
                _buildTextField(
                  '職稱',
                  _jobTitleController,
                  enabled: canEdit,
                  icon: Icons.work,
                ),
                _buildTextField(
                  '公司',
                  _companyController,
                  enabled: canEdit,
                  icon: Icons.business,
                ),
              ]),

              const SizedBox(height: AppDimensions.space6),

              // 聯絡資訊區塊
              _buildSectionCard('聯絡資訊', [
                _buildTextField(
                  '電話',
                  _phoneController,
                  enabled: canEdit,
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  'Email',
                  _emailController,
                  enabled: canEdit,
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildTextField(
                  '地址',
                  _addressController,
                  enabled: canEdit,
                  icon: Icons.location_on,
                  maxLines: 2,
                ),
                _buildTextField(
                  '網站',
                  _websiteController,
                  enabled: canEdit,
                  icon: Icons.web,
                  keyboardType: TextInputType.url,
                ),
              ]),

              const SizedBox(height: AppDimensions.space6),

              // 備註區塊
              _buildSectionCard('備註', [
                _buildTextField(
                  '備註',
                  _notesController,
                  enabled: canEdit,
                  icon: Icons.note,
                  maxLines: 3,
                ),
              ]),

              const SizedBox(height: AppDimensions.space8),

              // 操作按鈕
              if (canEdit) _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  /// 建立區塊卡片
  Widget _buildSectionCard(String title, List<Widget> children) {
    return ThemedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headline3),
          const SizedBox(height: AppDimensions.space4),
          ...children,
        ],
      ),
    );
  }

  /// 建立文字輸入欄位
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    bool required = false,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space4),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: enabled ? (value) => _onFieldChanged(label, value) : null,
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label 不能為空';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const UnderlineInputBorder(),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          enabled: enabled,
        ),
        style: enabled
            ? AppTextStyles.bodyMedium
            : AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText),
      ),
    );
  }

  /// 處理欄位變更
  void _onFieldChanged(String fieldLabel, String value) {
    final viewModel = ref.read(cardDetailViewModelBasicProvider.notifier);

    switch (fieldLabel) {
      case '姓名 *':
        viewModel.updateField(name: value);
        break;
      case '職稱':
        viewModel.updateField(jobTitle: value);
        break;
      case '公司':
        viewModel.updateField(company: value);
        break;
      case '電話':
        viewModel.updateField(phone: value);
        break;
      case 'Email':
        viewModel.updateField(email: value);
        break;
      case '地址':
        viewModel.updateField(address: value);
        break;
      case '網站':
        viewModel.updateField(website: value);
        break;
      case '備註':
        viewModel.updateField(notes: value);
        break;
    }
  }

  /// 建立操作按鈕
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ThemedButton(
            text: '取消',
            onPressed: _cancel,
            backgroundColor: AppColors.secondaryBackground,
            foregroundColor: AppColors.primaryText,
          ),
        ),
        const SizedBox(width: AppDimensions.space4),
        Expanded(
          child: ThemedButton(text: '儲存', onPressed: _saveCard),
        ),
      ],
    );
  }

  /// 建立圖片預覽
  Widget _buildImagePreview(String imagePath) {
    return ThemedCard(
      margin: const EdgeInsets.only(bottom: AppDimensions.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('名片圖片', style: AppTextStyles.subtitle1),
              IconButton(
                onPressed: () {
                  // 可以加入放大查看功能
                  _showImageDialog(imagePath);
                },
                icon: const Icon(Icons.zoom_in),
                tooltip: '放大查看',
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space3),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.space3),
            child: Image.file(
              File(imagePath),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
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
                      Text('無法載入圖片', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 顯示圖片對話框
  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(AppDimensions.space8),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, size: 64, color: AppColors.error),
                    SizedBox(height: AppDimensions.space4),
                    Text('無法載入圖片', style: AppTextStyles.bodyLarge),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
