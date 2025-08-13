import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_card.dart';
import 'package:flutter/material.dart';

/// 名片列表項目元件
///
/// 負責顯示單個名片的資訊，包含：
/// - 名片縮圖
/// - 基本資訊（姓名、職稱、公司）
/// - 點擊和長按手勢處理
/// - 支援可選的更多操作按鈕
class CardListItem extends StatelessWidget {
  const CardListItem({
    required this.card,
    super.key,
    this.onTap,
    this.onLongPress,
    this.onMoreActions,
    this.showMoreButton = true,
    this.isSelected = false,
    this.elevation,
    this.margin,
  });

  /// 名片實體
  final BusinessCard card;

  /// 點擊回調
  final VoidCallback? onTap;

  /// 長按回調
  final VoidCallback? onLongPress;

  /// 更多操作回調
  final VoidCallback? onMoreActions;

  /// 是否顯示更多操作按鈕
  final bool showMoreButton;

  /// 是否為選中狀態（用於多選模式）
  final bool isSelected;

  /// 自定義陰影高度
  final double? elevation;

  /// 自定義外邊距
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppDimensions.space2),
      child: ThemedCard(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                  border: Border.all(color: AppColors.primary, width: 2),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space4),
            child: Row(
              children: [
                // 名片縮圖
                _buildCardThumbnail(),
                const SizedBox(width: AppDimensions.space4),
                // 名片資訊
                Expanded(child: _buildCardInfo()),
                // 更多操作按鈕
                if (showMoreButton && onMoreActions != null)
                  _buildMoreActionsButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 建立名片縮圖
  Widget _buildCardThumbnail() {
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: _buildThumbnailContent(),
    );
  }

  /// 建立縮圖內容
  Widget _buildThumbnailContent() {
    if (card.imageUrl != null && card.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        child: Image.network(
          card.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultThumbnail();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return _buildLoadingThumbnail();
          },
        ),
      );
    }
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

  /// 建立載入中縮圖
  Widget _buildLoadingThumbnail() {
    return const Center(
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  /// 建立名片資訊
  Widget _buildCardInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 姓名
        _buildNameText(),
        // 職稱
        if (card.jobTitle != null && card.jobTitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          _buildJobTitleText(),
        ],
        // 公司
        if (card.company != null && card.company!.isNotEmpty) ...[
          const SizedBox(height: 2),
          _buildCompanyText(),
        ],
        // 聯絡資訊指示器
        if (card.hasContactInfo()) ...[
          const SizedBox(height: 4),
          _buildContactIndicators(),
        ],
      ],
    );
  }

  /// 建立姓名文字
  Widget _buildNameText() {
    return Text(
      card.name,
      style: AppTextStyles.headline6.copyWith(
        color: AppColors.primaryText,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 建立職稱文字
  Widget _buildJobTitleText() {
    return Text(
      card.jobTitle!,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 建立公司文字
  Widget _buildCompanyText() {
    return Text(
      card.company!,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 建立聯絡資訊指示器
  Widget _buildContactIndicators() {
    final indicators = <Widget>[];

    if (card.email != null && card.email!.isNotEmpty) {
      indicators.add(_buildContactIcon(Icons.email, AppColors.info));
    }

    if (card.phone != null && card.phone!.isNotEmpty) {
      indicators.add(_buildContactIcon(Icons.phone, AppColors.success));
    }

    if (card.address != null && card.address!.isNotEmpty) {
      indicators.add(_buildContactIcon(Icons.location_on, AppColors.warning));
    }

    if (card.website != null && card.website!.isNotEmpty) {
      indicators.add(_buildContactIcon(Icons.language, AppColors.primary));
    }

    if (indicators.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: indicators
          .expand((icon) => [icon, const SizedBox(width: 4)])
          .take(indicators.length * 2 - 1) // 移除最後一個間距
          .toList(),
    );
  }

  /// 建立聯絡方式圖示
  Widget _buildContactIcon(IconData icon, Color color) {
    return Icon(icon, size: 12, color: color.withValues(alpha: 0.7));
  }

  /// 建立更多操作按鈕
  Widget _buildMoreActionsButton() {
    return IconButton(
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.secondaryText,
        size: AppDimensions.iconSmall,
      ),
      onPressed: onMoreActions,
      padding: const EdgeInsets.all(AppDimensions.space1),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
                  // 縮圖骨架
                  _buildSkeletonBox(60, 40),
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
