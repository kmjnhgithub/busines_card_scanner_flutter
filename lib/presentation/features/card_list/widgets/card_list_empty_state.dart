import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_button.dart';
import 'package:flutter/material.dart';

/// 名片列表空狀態元件
/// 
/// 顯示不同情況下的空狀態，包含：
/// - 無名片狀態
/// - 搜尋無結果狀態
/// - 錯誤狀態
/// - 自訂空狀態
class CardListEmptyState extends StatelessWidget {
  const CardListEmptyState({
    required this.type, super.key,
    this.title,
    this.message,
    this.icon,
    this.illustration,
    this.actionText,
    this.onActionPressed,
    this.secondaryActionText,
    this.onSecondaryActionPressed,
    this.searchQuery,
  });

  /// 空狀態類型
  final EmptyStateType type;

  /// 自訂標題
  final String? title;

  /// 自訂訊息
  final String? message;

  /// 自訂圖示
  final IconData? icon;

  /// 自訂插圖
  final Widget? illustration;

  /// 主要動作文字
  final String? actionText;

  /// 主要動作回調
  final VoidCallback? onActionPressed;

  /// 次要動作文字
  final String? secondaryActionText;

  /// 次要動作回調
  final VoidCallback? onSecondaryActionPressed;

  /// 搜尋查詢（用於搜尋無結果狀態）
  final String? searchQuery;

  @override
  Widget build(BuildContext context) {
    final config = _getEmptyStateConfig();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 插圖或圖示
            _buildIllustration(config),
            
            const SizedBox(height: AppDimensions.space6),
            
            // 標題
            _buildTitle(config),
            
            const SizedBox(height: AppDimensions.space2),
            
            // 訊息
            _buildMessage(config),
            
            const SizedBox(height: AppDimensions.space8),
            
            // 動作按鈕
            _buildActions(config),
          ],
        ),
      ),
    );
  }

  /// 取得空狀態配置
  EmptyStateConfig _getEmptyStateConfig() {
    switch (type) {
      case EmptyStateType.noCards:
        return const EmptyStateConfig(
          icon: Icons.credit_card_outlined,
          title: '還沒有名片',
          message: '點擊右下角的 + 新增第一張名片',
          iconColor: AppColors.secondaryText,
          actionText: '新增名片',
        );
      
      case EmptyStateType.searchNoResults:
        return EmptyStateConfig(
          icon: Icons.search_off,
          title: '找不到相關名片',
          message: searchQuery != null 
              ? '沒有找到包含「$searchQuery」的名片\n試著搜尋其他關鍵字'
              : '試著搜尋其他關鍵字',
          iconColor: AppColors.secondaryText,
          actionText: '清除搜尋',
          secondaryActionText: '瀏覽所有名片',
        );
      
      case EmptyStateType.error:
        return const EmptyStateConfig(
          icon: Icons.error_outline,
          title: '載入失敗',
          message: '無法載入名片列表\n請檢查網路連線並重試',
          iconColor: AppColors.error,
          actionText: '重試',
          secondaryActionText: '重新整理',
        );
      
      case EmptyStateType.offline:
        return const EmptyStateConfig(
          icon: Icons.wifi_off,
          title: '無網路連線',
          message: '請檢查網路設定後重試',
          iconColor: AppColors.warning,
          actionText: '重試',
        );
      
      case EmptyStateType.loading:
        return const EmptyStateConfig(
          icon: Icons.hourglass_empty,
          title: '載入中...',
          message: '正在取得名片列表',
          iconColor: AppColors.primary,
        );
      
      case EmptyStateType.custom:
        return EmptyStateConfig(
          icon: icon ?? Icons.info_outline,
          title: title ?? '暫無內容',
          message: message ?? '',
          iconColor: AppColors.secondaryText,
          actionText: actionText,
          secondaryActionText: secondaryActionText,
        );
    }
  }

  /// 建立插圖或圖示
  Widget _buildIllustration(EmptyStateConfig config) {
    if (illustration != null) {
      return illustration!;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: config.iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        config.icon,
        size: 60,
        color: config.iconColor,
      ),
    );
  }

  /// 建立標題
  Widget _buildTitle(EmptyStateConfig config) {
    return Text(
      config.title,
      style: AppTextStyles.headline4.copyWith(
        color: AppColors.primaryText,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// 建立訊息
  Widget _buildMessage(EmptyStateConfig config) {
    return Text(
      config.message,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.secondaryText,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// 建立動作按鈕
  Widget _buildActions(EmptyStateConfig config) {
    final actions = <Widget>[];

    // 主要動作
    if (config.actionText != null) {
      actions.add(
        ThemedButton(
          text: config.actionText,
          onPressed: onActionPressed,
        ),
      );
    }

    // 次要動作
    if (config.secondaryActionText != null) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(height: AppDimensions.space3));
      }
      actions.add(
        ThemedButton(
          text: config.secondaryActionText,
          type: ThemedButtonType.outline,
          onPressed: onSecondaryActionPressed,
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(children: actions);
  }
}

/// 空狀態類型
enum EmptyStateType {
  /// 無名片
  noCards,
  /// 搜尋無結果
  searchNoResults,
  /// 錯誤狀態
  error,
  /// 離線狀態
  offline,
  /// 載入中
  loading,
  /// 自訂狀態
  custom,
}

/// 空狀態配置
class EmptyStateConfig {
  const EmptyStateConfig({
    required this.icon,
    required this.title,
    required this.message,
    required this.iconColor,
    this.actionText,
    this.secondaryActionText,
  });

  /// 圖示
  final IconData icon;

  /// 標題
  final String title;

  /// 訊息
  final String message;

  /// 圖示顏色
  final Color iconColor;

  /// 主要動作文字
  final String? actionText;

  /// 次要動作文字
  final String? secondaryActionText;
}

/// 載入狀態元件
/// 
/// 顯示載入中的視覺效果
class CardListLoadingState extends StatefulWidget {
  const CardListLoadingState({
    super.key,
    this.message = '載入中...',
    this.showProgress = true,
    this.showSkeleton = false,
    this.skeletonItemCount = 5,
  });

  /// 載入訊息
  final String message;

  /// 是否顯示進度指示器
  final bool showProgress;

  /// 是否顯示骨架畫面
  final bool showSkeleton;

  /// 骨架項目數量
  final int skeletonItemCount;

  @override
  State<CardListLoadingState> createState() => _CardListLoadingStateState();
}

class _CardListLoadingStateState extends State<CardListLoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showSkeleton) {
      return _buildSkeletonList();
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.showProgress) ...[
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: AppDimensions.space4),
          ],
          
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Text(
                  widget.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 建立骨架列表
  Widget _buildSkeletonList() {
    return ListView.builder(
      itemCount: widget.skeletonItemCount,
      padding: const EdgeInsets.all(AppDimensions.space4),
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.space2),
              padding: const EdgeInsets.all(AppDimensions.space4),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: Row(
                children: [
                  // 縮圖骨架
                  Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.placeholder.withValues(alpha: _fadeAnimation.value),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space4),
                  
                  // 資訊骨架
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.placeholder.withValues(alpha: _fadeAnimation.value),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 120,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.placeholder.withValues(alpha: _fadeAnimation.value * 0.7),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.placeholder.withValues(alpha: _fadeAnimation.value * 0.7),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 按鈕骨架
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.placeholder.withValues(alpha: _fadeAnimation.value),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}