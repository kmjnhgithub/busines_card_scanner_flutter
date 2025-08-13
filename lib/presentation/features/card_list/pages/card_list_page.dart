import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_list/view_models/card_list_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/dialog_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/toast_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_button.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 名片列表頁面
/// 
/// 顯示所有名片的列表，支援搜尋、排序、刪除等功能
class CardListPage extends ConsumerStatefulWidget {
  const CardListPage({super.key});

  @override
  ConsumerState<CardListPage> createState() => _CardListPageState();
}

class _CardListPageState extends ConsumerState<CardListPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    // 初始載入名片列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cardListViewModelProvider.notifier).loadCards();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cardListViewModelProvider);
    final viewModel = ref.read(cardListViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, viewModel),
      body: _buildBody(context, state, viewModel),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  /// 建立應用程式列
  PreferredSizeWidget _buildAppBar(BuildContext context, CardListViewModel viewModel) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: _isSearchExpanded 
          ? _buildSearchField(viewModel)
          : Text(
              '名片',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.primaryText,
              ),
            ),
      centerTitle: !_isSearchExpanded,
      actions: [
        if (!_isSearchExpanded) ...[
          IconButton(
            icon: const Icon(
              Icons.search,
              color: AppColors.primaryText,
              size: AppDimensions.iconMedium,
            ),
            onPressed: () {
              setState(() {
                _isSearchExpanded = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.sort,
              color: AppColors.primaryText,
              size: AppDimensions.iconMedium,
            ),
            onPressed: () => _showSortOptions(context, viewModel),
          ),
        ] else ...[
          IconButton(
            icon: const Icon(
              Icons.close,
              color: AppColors.primaryText,
              size: AppDimensions.iconMedium,
            ),
            onPressed: () {
              setState(() {
                _isSearchExpanded = false;
                _searchController.clear();
                viewModel.searchCards('');
              });
            },
          ),
        ],
      ],
    );
  }

  /// 建立搜尋輸入框
  Widget _buildSearchField(CardListViewModel viewModel) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryText),
      decoration: InputDecoration(
        hintText: '搜尋姓名、公司、電話...',
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.placeholder),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (query) {
        viewModel.searchCards(query);
      },
    );
  }

  /// 建立主體內容
  Widget _buildBody(BuildContext context, CardListState state, CardListViewModel viewModel) {
    if (state.isLoading && state.cards.isEmpty) {
      return _buildLoadingState();
    }

    if (state.error != null) {
      return _buildErrorState(state.error!, viewModel);
    }

    if (state.filteredCards.isEmpty) {
      return _buildEmptyState(context, state.searchQuery.isNotEmpty);
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.refresh(),
      color: AppColors.primary,
      child: _buildCardList(state.filteredCards, viewModel),
    );
  }

  /// 建立載入狀態
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(
            '載入中...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  /// 建立錯誤狀態
  Widget _buildErrorState(String error, CardListViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: AppDimensions.iconExtraLarge,
              color: AppColors.error,
            ),
            const SizedBox(height: AppDimensions.space4),
            Text(
              '發生錯誤',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppDimensions.space2),
            Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space6),
            ThemedButton(
              text: '重試',
              onPressed: () {
                viewModel.clearError();
                viewModel.loadCards();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 建立空狀態
  Widget _buildEmptyState(BuildContext context, bool isSearchResult) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchResult ? Icons.search_off : Icons.credit_card_outlined,
              size: AppDimensions.iconExtraLarge,
              color: AppColors.secondaryText,
            ),
            const SizedBox(height: AppDimensions.space4),
            Text(
              isSearchResult ? '找不到相關名片' : '還沒有名片',
              style: AppTextStyles.headline3.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppDimensions.space2),
            Text(
              isSearchResult 
                  ? '試著搜尋其他關鍵字'
                  : '點擊右下角的 + 新增第一張名片',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 建立名片列表
  Widget _buildCardList(List<BusinessCard> cards, CardListViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: AppDimensions.space4,
        right: AppDimensions.space4,
        top: AppDimensions.space2,
        bottom: AppDimensions.space16, // 留空間給 FAB
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _buildCardItem(context, card, viewModel);
      },
    );
  }

  /// 建立名片項目
  Widget _buildCardItem(BuildContext context, BusinessCard card, CardListViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space2),
      child: ThemedCard(
        onTap: () => _navigateToCardDetail(context, card),
        child: Row(
          children: [
            // 名片縮圖區域
            _buildCardThumbnail(card),
            const SizedBox(width: AppDimensions.space4),
            // 名片資訊區域
            Expanded(
              child: _buildCardInfo(card),
            ),
            // 更多操作按鈕
            _buildMoreActionsButton(context, card, viewModel),
          ],
        ),
      ),
    );
  }

  /// 建立名片縮圖
  Widget _buildCardThumbnail(BusinessCard card) {
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.separator,
          width: 0.5,
        ),
      ),
      child: card.imageUrl != null 
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              child: Image.network(
                card.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultThumbnail();
                },
              ),
            )
          : _buildDefaultThumbnail(),
    );
  }

  /// 建立預設縮圖
  Widget _buildDefaultThumbnail() {
    return const Icon(
      Icons.credit_card,
      color: AppColors.placeholder,
      size: AppDimensions.iconSmall,
    );
  }

  /// 建立名片資訊
  Widget _buildCardInfo(BusinessCard card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 姓名
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
    );
  }

  /// 建立更多操作按鈕
  Widget _buildMoreActionsButton(BuildContext context, BusinessCard card, CardListViewModel viewModel) {
    return IconButton(
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.secondaryText,
        size: AppDimensions.iconSmall,
      ),
      onPressed: () => _showCardOptions(context, card, viewModel),
    );
  }

  /// 建立浮動操作按鈕
  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _navigateToCardCreation(context),
      backgroundColor: AppColors.primary,
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: AppDimensions.iconMedium,
      ),
    );
  }

  /// 顯示排序選項
  void _showSortOptions(BuildContext context, CardListViewModel viewModel) {
    final state = ref.read(cardListViewModelProvider);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖曳指示器
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppDimensions.space2),
              decoration: BoxDecoration(
                color: AppColors.separator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.space4),
              child: Text(
                '排序方式',
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ),
            _buildSortOption(
              context,
              '按姓名排序',
              CardListSortBy.name,
              state.sortBy,
              state.sortOrder,
              viewModel,
            ),
            _buildSortOption(
              context,
              '按公司排序',
              CardListSortBy.company,
              state.sortBy,
              state.sortOrder,
              viewModel,
            ),
            _buildSortOption(
              context,
              '按建立時間排序',
              CardListSortBy.dateCreated,
              state.sortBy,
              state.sortOrder,
              viewModel,
            ),
            const SizedBox(height: AppDimensions.space2),
          ],
        ),
      ),
    );
  }

  /// 建立排序選項項目
  Widget _buildSortOption(
    BuildContext context,
    String title,
    CardListSortBy sortBy,
    CardListSortBy currentSortBy,
    SortOrder currentSortOrder,
    CardListViewModel viewModel,
  ) {
    final isSelected = sortBy == currentSortBy;
    
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isSelected ? AppColors.primary : AppColors.primaryText,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_upward,
                    color: currentSortOrder == SortOrder.ascending 
                        ? AppColors.primary 
                        : AppColors.secondaryText,
                    size: AppDimensions.iconSmall,
                  ),
                  onPressed: () {
                    viewModel.sortCards(sortBy, SortOrder.ascending);
                    Navigator.pop(context);
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_downward,
                    color: currentSortOrder == SortOrder.descending 
                        ? AppColors.primary 
                        : AppColors.secondaryText,
                    size: AppDimensions.iconSmall,
                  ),
                  onPressed: () {
                    viewModel.sortCards(sortBy, SortOrder.descending);
                    Navigator.pop(context);
                  },
                ),
              ],
            )
          : null,
      onTap: () {
        viewModel.sortCards(sortBy, currentSortOrder);
        Navigator.pop(context);
      },
    );
  }

  /// 顯示名片操作選項
  void _showCardOptions(BuildContext context, BusinessCard card, CardListViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖曳指示器
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppDimensions.space2),
              decoration: BoxDecoration(
                color: AppColors.separator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primaryText),
              title: Text(
                '編輯',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryText),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToCardEdit(context, card);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.primaryText),
              title: Text(
                '分享',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryText),
              ),
              onTap: () {
                Navigator.pop(context);
                _shareCard(context, card);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: Text(
                '刪除',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteCard(context, card, viewModel);
              },
            ),
            const SizedBox(height: AppDimensions.space2),
          ],
        ),
      ),
    );
  }

  /// 確認刪除名片
  Future<void> _confirmDeleteCard(BuildContext context, BusinessCard card, CardListViewModel viewModel) async {
    final confirmed = await DialogPresenter.showDeleteConfirmation(
      context,
      title: '刪除名片',
      content: '確定要刪除「${card.name}」的名片嗎？此操作無法復原。',
      deleteText: '刪除',
      cancelText: '取消',
    );

    if (confirmed == true) {
      // 保存 context 到局部變量以避免跨異步使用
      final currentContext = context;
      final success = await viewModel.deleteCard(card.id);
      if (!mounted) {
        return;
      }
      
      if (success && mounted) {
        ToastHelper.showSnackBar(
          currentContext,
          '名片已刪除',
          type: ToastType.success,
        );
      } else if (!success && mounted) {
        ToastHelper.showSnackBar(
          currentContext,
          '刪除名片失敗',
          type: ToastType.error,
        );
      }
    }
  }

  /// 導航到名片詳情頁面
  void _navigateToCardDetail(BuildContext context, BusinessCard card) {
    // TODO: 實作導航到名片詳情頁面
    // Navigator.pushNamed(context, '/card_detail', arguments: card);
  }

  /// 導航到名片建立頁面
  void _navigateToCardCreation(BuildContext context) {
    // TODO: 實作導航到名片建立頁面
    // Navigator.pushNamed(context, '/card_creation');
  }

  /// 導航到名片編輯頁面
  void _navigateToCardEdit(BuildContext context, BusinessCard card) {
    // TODO: 實作導航到名片編輯頁面
    // Navigator.pushNamed(context, '/card_edit', arguments: card);
  }

  /// 分享名片
  void _shareCard(BuildContext context, BusinessCard card) {
    // TODO: 實作名片分享功能
    ToastHelper.showSnackBar(
      context,
      '分享功能尚未實作',
    );
  }
}