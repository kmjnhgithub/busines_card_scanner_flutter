import 'dart:io';

import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_responsive.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_card.dart';
import 'package:flutter/material.dart';

/// 名片列表項目元件
///
/// 使用響應式設計系統，對齊 iOS 原生版本設計：
/// - 響應式 Cell 高度（螢幕高度的 12%）
/// - 黃金比例名片圖片（1:0.618）
/// - iOS 字型系統（姓名 18pt Semibold、公司 16pt、職稱 14pt）
/// - 左貼齊圖片佈局，1/2 垂直分割文字區域
/// - iOS 觸控回饋動畫（縮放 0.95、透明度 0.8）
class CardListItem extends StatefulWidget {
  const CardListItem({
    required this.card,
    super.key,
    this.onTap,
    this.onLongPress,
    this.onMoreActions,
    this.onDelete,
    this.showMoreButton = true,
    this.isSelected = false,
    this.elevation,
    this.margin,
    this.enableSwipeToDelete = true,
  });

  /// 名片實體
  final BusinessCard card;

  /// 點擊回調
  final VoidCallback? onTap;

  /// 長按回調
  final VoidCallback? onLongPress;

  /// 更多操作回調
  final VoidCallback? onMoreActions;

  /// 刪除回調
  final Future<bool> Function()? onDelete;

  /// 是否顯示更多操作按鈕
  final bool showMoreButton;

  /// 是否為選中狀態（用於多選模式）
  final bool isSelected;

  /// 自定義陰影高度
  final double? elevation;

  /// 自定義外邊距
  final EdgeInsets? margin;

  /// 是否啟用滑動刪除功能
  final bool enableSwipeToDelete;

  @override
  State<CardListItem> createState() => _CardListItemState();
}

class _CardListItemState extends State<CardListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation =
        Tween<double>(
          begin: 1,
          end: 0.98, // iOS 觸控回饋縮放比例
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
    _opacityAnimation =
        Tween<double>(
          begin: 1,
          end: 0.8, // iOS 觸控回饋透明度
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cellHeight = AppResponsiveCardList.calculateCellHeight(
      screenSize.height,
    );
    final containerHeight = AppResponsiveCardList.calculateContainerHeight(
      cellHeight,
    );
    final imageSize = AppResponsiveCardList.calculateImageSize(containerHeight);

    final cardWidget = AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              height: cellHeight,
              margin:
                  widget.margin ??
                  const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space4,
                    vertical: AppResponsiveCardList.verticalMargin / 2,
                  ),
              child: GestureDetector(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: Container(
                  height: containerHeight,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusMedium,
                    ),
                    border: widget.isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space4,
                      vertical: AppResponsiveCardList.verticalMargin,
                    ),
                    child: Row(
                      children: [
                        // 名片圖片（左貼齊，黃金比例）
                        _buildCardImage(imageSize),
                        const SizedBox(
                          width: AppResponsiveCardList.imageToTextSpacing,
                        ),
                        // 名片資訊（垂直 1/2 分割佈局）
                        Expanded(child: _buildCardInfo(containerHeight)),
                        // 更多操作按鈕
                        if (widget.showMoreButton &&
                            widget.onMoreActions != null)
                          _buildMoreActionsButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // 如果啟用滑動刪除功能，則包裝在 Dismissible 中
    if (widget.enableSwipeToDelete && widget.onDelete != null) {
      return Dismissible(
        key: Key('card_${widget.card.id}'),
        direction: DismissDirection.endToStart,
        dismissThresholds: const {
          DismissDirection.endToStart: 0.4, // 需要滑動40%才觸發
        },
        background: _buildSwipeBackground(),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart &&
              widget.onDelete != null) {
            return widget.onDelete!();
          }
          return false;
        },
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  /// 建立名片圖片（響應式尺寸，黃金比例）
  Widget _buildCardImage(Size imageSize) {
    return Container(
      width: imageSize.width,
      height: imageSize.height,
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(
          AppResponsiveCardList.imageCornerRadius,
        ),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: _buildThumbnailContent(),
    );
  }

  /// 建立縮圖內容
  Widget _buildThumbnailContent() {
    // 優先顯示本地圖片
    if (widget.card.imagePath != null && widget.card.imagePath!.isNotEmpty) {
      final imageFile = File(widget.card.imagePath!);

      // 確認檔案存在
      if (imageFile.existsSync()) {
        return Image.file(
          imageFile,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultThumbnail();
          },
        );
      } else {}
    } else {}

    // 沒有圖片時顯示預設圖示
    return _buildDefaultThumbnail();
  }

  /// 建立預設縮圖
  Widget _buildDefaultThumbnail() {
    return const Icon(
      Icons.credit_card,
      color: AppColors.placeholder,
      size: AppDimensions.iconSmall,
    );
  }

  /// 建立名片資訊（垂直 1/2 分割佈局，對齊 iOS 設計）
  Widget _buildCardInfo(double containerHeight) {
    final nameAreaHeight = AppResponsiveCardList.calculateNameAreaHeight(
      containerHeight,
    );
    final companyAreaHeight = AppResponsiveCardList.calculateCompanyAreaHeight(
      containerHeight,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 姓名區域（上半部 50%）
        SizedBox(height: nameAreaHeight, child: _buildNameText()),
        // 公司+職稱區域（下半部 50%）
        SizedBox(
          height: companyAreaHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 公司名稱（多行顯示）
              Expanded(child: _buildCompanyText()),
              // 職稱（固定高度）
              SizedBox(
                height: AppResponsiveCardList.jobTitleHeight,
                child: _buildJobTitleText(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 建立姓名文字（iOS 專用字型：18pt Semibold）
  Widget _buildNameText() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        widget.card.name,
        style: const TextStyle(
          fontSize: 18, // iOS cardName 字型
          fontWeight: FontWeight.w600, // Semibold
          color: AppColors.primaryText,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.left,
      ),
    );
  }

  /// 建立職稱文字（iOS 專用字型：14pt Regular）
  Widget _buildJobTitleText() {
    if (widget.card.jobTitle == null || widget.card.jobTitle!.isEmpty) {
      return const Text(
        '未知職稱',
        style: TextStyle(
          fontSize: 14, // iOS jobTitle 字型
          fontWeight: FontWeight.w400, // Regular
          color: AppColors.secondaryText,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Align(
      alignment: Alignment.bottomLeft,
      child: Text(
        widget.card.jobTitle!,
        style: const TextStyle(
          fontSize: 14, // iOS jobTitle 字型
          fontWeight: FontWeight.w400, // Regular
          color: AppColors.secondaryText,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 建立公司文字（iOS 專用字型：16pt Regular，支援多行顯示）
  Widget _buildCompanyText() {
    final companyName = widget.card.company?.isNotEmpty == true
        ? widget.card.company!
        : '未知公司';

    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        companyName,
        style: const TextStyle(
          fontSize: 16, // iOS companyName 字型
          fontWeight: FontWeight.w400, // Regular
          color: AppColors.secondaryText,
        ),
        maxLines: 2, // 支援多行顯示
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.left,
      ),
    );
  }

  /// 建立更多操作按鈕
  Widget _buildMoreActionsButton() {
    return IconButton(
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.secondaryText,
        size: AppDimensions.iconSmall,
      ),
      onPressed: widget.onMoreActions,
      padding: const EdgeInsets.all(AppDimensions.space1),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  /// 建立滑動時的背景效果
  Widget _buildSwipeBackground() {
    return Container(
      margin:
          widget.margin ??
          const EdgeInsets.symmetric(
            horizontal: AppDimensions.space4,
            vertical: AppResponsiveCardList.verticalMargin / 2,
          ),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF6B6B), // 較淺的紅色
            Color(0xFFFF4757), // 較深的紅色
          ],
        ),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space6),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete_outline, color: Colors.white, size: 28),
          SizedBox(width: AppDimensions.space2),
          Text(
            '刪除',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// 名片列表項目骨架載入元件
///
/// 用於顯示載入狀態的骨架畫面
class CardListItemSkeleton extends StatefulWidget {
  const CardListItemSkeleton({super.key, this.margin});

  /// 自定義外邊距
  final EdgeInsets? margin;

  @override
  State<CardListItemSkeleton> createState() => _CardListItemSkeletonState();
}

class _CardListItemSkeletonState extends State<CardListItemSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          widget.margin ?? const EdgeInsets.only(bottom: AppDimensions.space2),
      child: ThemedCard(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space4),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Row(
                children: [
                  // 縮圖骨架（使用響應式尺寸）
                  Builder(
                    builder: (context) {
                      final screenHeight = MediaQuery.of(context).size.height;
                      final cellHeight =
                          AppResponsiveCardList.calculateCellHeight(
                            screenHeight,
                          );
                      final containerHeight =
                          AppResponsiveCardList.calculateContainerHeight(
                            cellHeight,
                          );
                      final imageSize =
                          AppResponsiveCardList.calculateImageSize(
                            containerHeight,
                          );
                      return _buildSkeletonBox(
                        imageSize.width,
                        imageSize.height,
                      );
                    },
                  ),
                  const SizedBox(width: AppDimensions.space4),
                  // 資訊骨架
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 姓名骨架
                        _buildSkeletonBox(120, 16),
                        const SizedBox(height: 6),
                        // 職稱骨架
                        _buildSkeletonBox(80, 12),
                        const SizedBox(height: 4),
                        // 公司骨架
                        _buildSkeletonBox(100, 12),
                      ],
                    ),
                  ),
                  // 更多按鈕骨架
                  _buildSkeletonBox(24, 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 建立骨架方塊
  Widget _buildSkeletonBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.placeholder.withValues(alpha: _animation.value),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
    );
  }
}

/// 名片列表項目分隔線
class CardListItemDivider extends StatelessWidget {
  const CardListItemDivider({
    super.key,
    this.height = 1.0,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.color,
  });

  /// 分隔線高度
  final double height;

  /// 左側縮進
  final double indent;

  /// 右側縮進
  final double endIndent;

  /// 分隔線顏色
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: height,
      indent: indent,
      endIndent: endIndent,
      color: color ?? AppColors.separator,
    );
  }
}

/// 名片列表項目包裝器
///
/// 提供統一的邊距和間距管理
class CardListItemWrapper extends StatelessWidget {
  const CardListItemWrapper({
    required this.child,
    super.key,
    this.padding,
    this.showDivider = false,
    this.dividerIndent = 0.0,
  });

  /// 子元件
  final Widget child;

  /// 內邊距
  final EdgeInsets? padding;

  /// 是否顯示分隔線
  final bool showDivider;

  /// 分隔線縮進
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (showDivider) {
      content = Column(
        children: [
          content,
          CardListItemDivider(indent: dividerIndent, endIndent: dividerIndent),
        ],
      );
    }

    return content;
  }
}
