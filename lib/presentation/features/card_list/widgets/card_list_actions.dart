import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// 名片動作選項類型
enum CardAction {
  /// 檢視詳情
  view,
  /// 編輯
  edit,
  /// 分享
  share,
  /// 複製
  duplicate,
  /// 匯出
  export,
  /// 加入最愛
  favorite,
  /// 刪除
  delete,
}

/// 名片動作選項元件
/// 
/// 提供名片的各種操作選項，支援：
/// - 底部模態選單格式
/// - 自訂動作列表
/// - 圖示和描述文字
/// - 危險操作的特殊樣式
class CardListActions extends StatelessWidget {
  const CardListActions({
    required this.card, super.key,
    this.actions = const [
      CardAction.view,
      CardAction.edit,
      CardAction.share,
      CardAction.duplicate,
      CardAction.delete,
    ],
    this.onActionSelected,
    this.showCardInfo = true,
  });

  /// 名片實體
  final BusinessCard card;

  /// 可用動作列表
  final List<CardAction> actions;

  /// 動作選擇回調
  final Function(CardAction action)? onActionSelected;

  /// 是否顯示名片資訊
  final bool showCardInfo;

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
            
            // 名片資訊（可選）
            if (showCardInfo) _buildCardInfo(),
            
            // 動作列表
            _buildActionsList(context),
            
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

  /// 建立名片資訊
  Widget _buildCardInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space4),
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          // 名片縮圖
          _buildCardThumbnail(),
          const SizedBox(width: AppDimensions.space3),
          
          // 名片資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  style: AppTextStyles.headline6.copyWith(
                    color: AppColors.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (card.jobTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    card.jobTitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (card.company != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    card.company!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建立名片縮圖
  Widget _buildCardThumbnail() {
    return Container(
      width: 48,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.separator,
          width: 0.5,
        ),
      ),
      child: card.imageUrl != null && card.imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              child: Image.network(
                card.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.credit_card,
                    color: AppColors.placeholder,
                    size: 16,
                  );
                },
              ),
            )
          : const Icon(
              Icons.credit_card,
              color: AppColors.placeholder,
              size: 16,
            ),
    );
  }

  /// 建立動作列表
  Widget _buildActionsList(BuildContext context) {
    return Column(
      children: actions.map((action) {
        return _buildActionTile(context, action);
      }).toList(),
    );
  }

  /// 建立動作項目
  Widget _buildActionTile(BuildContext context, CardAction action) {
    final config = _getActionConfig(action);
    
    return ListTile(
      leading: Icon(
        config.icon,
        color: config.isDangerous ? AppColors.error : AppColors.primaryText,
        size: AppDimensions.iconMedium,
      ),
      title: Text(
        config.title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: config.isDangerous ? AppColors.error : AppColors.primaryText,
        ),
      ),
      subtitle: config.subtitle != null
          ? Text(
              config.subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryText,
              ),
            )
          : null,
      onTap: () {
        Navigator.of(context).pop();
        onActionSelected?.call(action);
      },
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space1,
      ),
    );
  }

  /// 取得動作配置
  ActionConfig _getActionConfig(CardAction action) {
    switch (action) {
      case CardAction.view:
        return const ActionConfig(
          icon: Icons.visibility_outlined,
          title: '檢視詳情',
          subtitle: '查看完整名片資訊',
        );
      
      case CardAction.edit:
        return const ActionConfig(
          icon: Icons.edit_outlined,
          title: '編輯',
          subtitle: '修改名片資訊',
        );
      
      case CardAction.share:
        return const ActionConfig(
          icon: Icons.share_outlined,
          title: '分享',
          subtitle: '分享名片給其他人',
        );
      
      case CardAction.duplicate:
        return const ActionConfig(
          icon: Icons.copy_outlined,
          title: '複製',
          subtitle: '建立這張名片的副本',
        );
      
      case CardAction.export:
        return const ActionConfig(
          icon: Icons.download_outlined,
          title: '匯出',
          subtitle: '匯出為 vCard 或其他格式',
        );
      
      case CardAction.favorite:
        return const ActionConfig(
          icon: Icons.favorite_border_outlined,
          title: '加入最愛',
          subtitle: '標記為常用名片',
        );
      
      case CardAction.delete:
        return const ActionConfig(
          icon: Icons.delete_outline,
          title: '刪除',
          subtitle: '永久刪除這張名片',
          isDangerous: true,
        );
    }
  }
}

/// 動作配置資料類別
class ActionConfig {
  const ActionConfig({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDangerous = false,
  });

  /// 圖示
  final IconData icon;

  /// 標題
  final String title;

  /// 副標題
  final String? subtitle;

  /// 是否為危險操作
  final bool isDangerous;
}

/// 快速動作按鈕列
/// 
/// 提供水平排列的快速動作按鈕
class QuickActionBar extends StatelessWidget {
  const QuickActionBar({
    required this.card, super.key,
    this.actions = const [
      CardAction.view,
      CardAction.edit,
      CardAction.share,
      CardAction.delete,
    ],
    this.onActionSelected,
    this.buttonSize = 48.0,
  });

  /// 名片實體
  final BusinessCard card;

  /// 快速動作列表
  final List<CardAction> actions;

  /// 動作選擇回調
  final Function(CardAction action)? onActionSelected;

  /// 按鈕大小
  final double buttonSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: buttonSize + 16,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions.map(_buildQuickActionButton).toList(),
      ),
    );
  }

  /// 建立快速動作按鈕
  Widget _buildQuickActionButton(CardAction action) {
    final config = _getActionConfig(action);
    
    return GestureDetector(
      onTap: () => onActionSelected?.call(action),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: config.isDangerous 
              ? AppColors.error.withValues(alpha: 0.1)
              : AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(buttonSize / 2),
          border: Border.all(
            color: config.isDangerous ? AppColors.error : AppColors.separator,
          ),
        ),
        child: Icon(
          config.icon,
          color: config.isDangerous ? AppColors.error : AppColors.primaryText,
          size: AppDimensions.iconMedium,
        ),
      ),
    );
  }

  /// 取得動作配置（簡化版）
  ActionConfig _getActionConfig(CardAction action) {
    switch (action) {
      case CardAction.view:
        return const ActionConfig(
          icon: Icons.visibility_outlined,
          title: '檢視',
        );
      
      case CardAction.edit:
        return const ActionConfig(
          icon: Icons.edit_outlined,
          title: '編輯',
        );
      
      case CardAction.share:
        return const ActionConfig(
          icon: Icons.share_outlined,
          title: '分享',
        );
      
      case CardAction.duplicate:
        return const ActionConfig(
          icon: Icons.copy_outlined,
          title: '複製',
        );
      
      case CardAction.export:
        return const ActionConfig(
          icon: Icons.download_outlined,
          title: '匯出',
        );
      
      case CardAction.favorite:
        return const ActionConfig(
          icon: Icons.favorite_border_outlined,
          title: '最愛',
        );
      
      case CardAction.delete:
        return const ActionConfig(
          icon: Icons.delete_outline,
          title: '刪除',
          isDangerous: true,
        );
    }
  }
}

/// 批次動作工具列
/// 
/// 用於多選模式下的批次操作
class BatchActionToolbar extends StatelessWidget {
  const BatchActionToolbar({
    required this.selectedCount, super.key,
    this.onSelectAll,
    this.onClearSelection,
    this.onBatchShare,
    this.onBatchExport,
    this.onBatchDelete,
    this.showSelectAll = true,
  });

  /// 已選擇的數量
  final int selectedCount;

  /// 全選回調
  final VoidCallback? onSelectAll;

  /// 清除選擇回調
  final VoidCallback? onClearSelection;

  /// 批次分享回調
  final VoidCallback? onBatchShare;

  /// 批次匯出回調
  final VoidCallback? onBatchExport;

  /// 批次刪除回調
  final VoidCallback? onBatchDelete;

  /// 是否顯示全選按鈕
  final bool showSelectAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: const Border(
          bottom: BorderSide(
            color: AppColors.separator,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppDimensions.space4),
          
          // 選擇數量
          Text(
            '已選擇 $selectedCount 項',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const Spacer(),
          
          // 全選按鈕
          if (showSelectAll && onSelectAll != null)
            TextButton(
              onPressed: onSelectAll,
              child: Text(
                '全選',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          
          // 清除選擇按鈕
          if (onClearSelection != null)
            TextButton(
              onPressed: onClearSelection,
              child: Text(
                '取消',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          
          // 批次動作按鈕
          _buildBatchActionButton(
            icon: Icons.share_outlined,
            onPressed: onBatchShare,
          ),
          
          _buildBatchActionButton(
            icon: Icons.download_outlined,
            onPressed: onBatchExport,
          ),
          
          _buildBatchActionButton(
            icon: Icons.delete_outline,
            onPressed: onBatchDelete,
            isDangerous: true,
          ),
          
          const SizedBox(width: AppDimensions.space4),
        ],
      ),
    );
  }

  /// 建立批次動作按鈕
  Widget _buildBatchActionButton({
    required IconData icon,
    VoidCallback? onPressed,
    bool isDangerous = false,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        color: isDangerous ? AppColors.error : AppColors.primaryText,
        size: AppDimensions.iconMedium,
      ),
      onPressed: onPressed,
      padding: const EdgeInsets.all(AppDimensions.space2),
    );
  }
}