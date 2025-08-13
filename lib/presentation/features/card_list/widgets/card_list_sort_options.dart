import 'package:busines_card_scanner_flutter/presentation/features/card_list/view_models/card_list_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// 排序選項元件
///
/// 提供名片列表的排序選項，包含：
/// - 多種排序欄位選項
/// - 升序/降序切換
/// - 視覺化的選中狀態
/// - 底部模態選單格式
class CardListSortOptions extends StatelessWidget {
  const CardListSortOptions({
    required this.currentSortBy,
    required this.currentSortOrder,
    super.key,
    this.onSortChanged,
    this.showTitle = true,
    this.title = '排序方式',
  });

  /// 當前排序欄位
  final CardListSortBy currentSortBy;

  /// 當前排序順序
  final SortOrder currentSortOrder;

  /// 排序變更回調
  final Function(CardListSortBy sortBy, SortOrder sortOrder)? onSortChanged;

  /// 是否顯示標題
  final bool showTitle;

  /// 標題文字
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖曳指示器
            _buildDragIndicator(),

            // 標題
            if (showTitle) _buildTitle(),

            // 排序選項列表
            _buildSortOptions(context),

            const SizedBox(height: AppDimensions.space2),
          ],
        ),
      ),
    );
  }

  /// 建立拖曳指示器
  Widget _buildDragIndicator() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.space2),
      decoration: BoxDecoration(
        color: AppColors.separator,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// 建立標題
  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.space4),
      child: Text(
        title,
        style: AppTextStyles.headline5.copyWith(color: AppColors.primaryText),
      ),
    );
  }

  /// 建立排序選項列表
  Widget _buildSortOptions(BuildContext context) {
    final sortOptions = [
      const SortOptionItem(
        sortBy: CardListSortBy.name,
        title: '按姓名排序',
        icon: Icons.person_outline,
      ),
      const SortOptionItem(
        sortBy: CardListSortBy.company,
        title: '按公司排序',
        icon: Icons.business_outlined,
      ),
      const SortOptionItem(
        sortBy: CardListSortBy.jobTitle,
        title: '按職稱排序',
        icon: Icons.work_outline,
      ),
      const SortOptionItem(
        sortBy: CardListSortBy.dateCreated,
        title: '按建立時間排序',
        icon: Icons.schedule_outlined,
      ),
      const SortOptionItem(
        sortBy: CardListSortBy.dateUpdated,
        title: '按更新時間排序',
        icon: Icons.update_outlined,
      ),
    ];

    return Column(
      children: sortOptions.map((option) {
        return _buildSortOptionTile(context, option);
      }).toList(),
    );
  }

  /// 建立排序選項項目
  Widget _buildSortOptionTile(BuildContext context, SortOptionItem option) {
    final isSelected = option.sortBy == currentSortBy;

    return ListTile(
      leading: Icon(
        option.icon,
        color: isSelected ? AppColors.primary : AppColors.secondaryText,
        size: AppDimensions.iconMedium,
      ),
      title: Text(
        option.title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isSelected ? AppColors.primary : AppColors.primaryText,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? _buildSortOrderControls() : null,
      onTap: () {
        onSortChanged?.call(option.sortBy, currentSortOrder);
        Navigator.of(context).pop();
      },
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space1,
      ),
    );
  }

  /// 建立排序順序控制項
  Widget _buildSortOrderControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 升序按鈕
        _buildSortOrderButton(
          icon: Icons.arrow_upward,
          isSelected: currentSortOrder == SortOrder.ascending,
          onTap: () => onSortChanged?.call(currentSortBy, SortOrder.ascending),
        ),
        const SizedBox(width: AppDimensions.space1),
        // 降序按鈕
        _buildSortOrderButton(
          icon: Icons.arrow_downward,
          isSelected: currentSortOrder == SortOrder.descending,
          onTap: () => onSortChanged?.call(currentSortBy, SortOrder.descending),
        ),
      ],
    );
  }

  /// 建立排序順序按鈕
  Widget _buildSortOrderButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space1),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : AppColors.secondaryText,
          size: AppDimensions.iconSmall,
        ),
      ),
    );
  }
}

/// 排序選項項目資料類別
class SortOptionItem {
  const SortOptionItem({
    required this.sortBy,
    required this.title,
    required this.icon,
  });

  /// 排序欄位
  final CardListSortBy sortBy;

  /// 顯示標題
  final String title;

  /// 圖示
  final IconData icon;
}

/// 排序方向指示器
///
/// 顯示當前排序方向的簡潔指示器
class SortDirectionIndicator extends StatelessWidget {
  const SortDirectionIndicator({
    required this.sortOrder,
    super.key,
    this.size = AppDimensions.iconSmall,
    this.color,
  });

  /// 排序順序
  final SortOrder sortOrder;

  /// 圖示大小
  final double size;

  /// 圖示顏色
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      sortOrder == SortOrder.ascending
          ? Icons.arrow_upward
          : Icons.arrow_downward,
      size: size,
      color: color ?? AppColors.primary,
    );
  }
}

/// 排序快速選擇器
///
/// 提供水平排列的快速排序選項
class QuickSortSelector extends StatelessWidget {
  const QuickSortSelector({
    required this.currentSortBy,
    required this.currentSortOrder,
    super.key,
    this.onSortChanged,
    this.options = const [
      CardListSortBy.name,
      CardListSortBy.company,
      CardListSortBy.dateCreated,
    ],
  });

  /// 當前排序欄位
  final CardListSortBy currentSortBy;

  /// 當前排序順序
  final SortOrder currentSortOrder;

  /// 排序變更回調
  final Function(CardListSortBy sortBy, SortOrder sortOrder)? onSortChanged;

  /// 顯示的排序選項
  final List<CardListSortBy> options;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppDimensions.space2),
        itemBuilder: (context, index) {
          final sortBy = options[index];
          final isSelected = sortBy == currentSortBy;

          return _buildQuickSortChip(sortBy, isSelected);
        },
      ),
    );
  }

  /// 建立快速排序標籤
  Widget _buildQuickSortChip(CardListSortBy sortBy, bool isSelected) {
    return GestureDetector(
      onTap: () {
        final newOrder = isSelected
            ? (currentSortOrder == SortOrder.ascending
                  ? SortOrder.descending
                  : SortOrder.ascending)
            : currentSortOrder;
        onSortChanged?.call(sortBy, newOrder);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space3,
          vertical: AppDimensions.space2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.separator,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getSortByDisplayName(sortBy),
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.primaryText,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppDimensions.space1),
              Icon(
                currentSortOrder == SortOrder.ascending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 12,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 取得排序欄位的顯示名稱
  String _getSortByDisplayName(CardListSortBy sortBy) {
    switch (sortBy) {
      case CardListSortBy.name:
        return '姓名';
      case CardListSortBy.company:
        return '公司';
      case CardListSortBy.jobTitle:
        return '職稱';
      case CardListSortBy.dateCreated:
        return '建立時間';
      case CardListSortBy.dateUpdated:
        return '更新時間';
    }
  }
}
