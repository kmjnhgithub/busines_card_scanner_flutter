import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_list/view_models/card_list_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/dialog_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/toast_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/router/app_routes.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      body: Column(
        children: [
          // 搜尋欄位
          _buildSearchBar(viewModel),
          // 名片列表
          Expanded(
            child: _buildBody(context, state, viewModel),
          ),
        ],
      ),
    );
  }

  /// 建立應用程式列
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    CardListViewModel viewModel,
  ) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      title: Text(
        '名片',
        style: AppTextStyles.headline3.copyWith(
          color: AppColors.primaryText,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.add,
            color: AppColors.primary,
            size: AppDimensions.iconMedium,
          ),
          onPressed: () => _showCreateCardOptions(context),
        ),
      ],
    );
  }

  /// 建立搜尋欄位
  Widget _buildSearchBar(CardListViewModel viewModel) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeScreen = screenWidth > 600;
        
        return Container(
          margin: EdgeInsets.all(screenWidth * 0.04), // 4% 螢幕寬度邊距
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.02,
          ),
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: AppColors.secondaryText,
                size: isLargeScreen 
                    ? AppDimensions.iconMedium 
                    : AppDimensions.iconSmall,
              ),
              SizedBox(width: screenWidth * 0.02), // 2% 間距
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: (isLargeScreen 
                      ? AppTextStyles.bodyLarge 
                      : AppTextStyles.bodyMedium
                  ).copyWith(color: AppColors.primaryText),
                  decoration: InputDecoration(
                    hintText: '搜尋姓名、公司、電話、Email',
                    hintStyle: (isLargeScreen 
                        ? AppTextStyles.bodyLarge 
                        : AppTextStyles.bodyMedium
                    ).copyWith(
                      color: AppColors.placeholder,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (query) {
                    viewModel.searchCards(query);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 建立主體內容
  Widget _buildBody(
    BuildContext context,
    CardListState state,
    CardListViewModel viewModel,
  ) {
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
              isSearchResult ? '試著搜尋其他關鍵字' : '點擊右下角的 + 新增第一張名片',
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
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04, // 4% 螢幕寬度
        vertical: AppDimensions.space2,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _buildCardItem(context, card, viewModel);
      },
    );
  }

  /// 建立名片項目
  Widget _buildCardItem(
    BuildContext context,
    BusinessCard card,
    CardListViewModel viewModel,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      margin: EdgeInsets.only(
        bottom: screenWidth * 0.02, // 2% 螢幕寬度作為間距
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          onTap: () => _navigateToCardDetail(context, card),
          onLongPress: () => _showCardOptions(context, card, viewModel),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.03), // 3% 螢幕寬度內邊距
            child: Row(
              children: [
                // 左側名片圖片
                _buildCardImage(card),
                SizedBox(width: screenWidth * 0.03), // 3% 間距
                // 右側名片資訊
                Expanded(
                  child: _buildCardInfo(card),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 建立名片圖片
  Widget _buildCardImage(BusinessCard card) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final imageWidth = screenWidth * 0.25; // 25% 螢幕寬度
        final imageHeight = imageWidth * 0.63; // 保持名片比例 (約 5:8)
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          child: Container(
            width: imageWidth,
            height: imageHeight,
            color: AppColors.secondaryBackground,
            child: card.imagePath != null && card.imagePath!.isNotEmpty
                ? _buildCardImageContent(card.imagePath!)
                : _buildDefaultCardImage(),
          ),
        );
      },
    );
  }

  /// 建立名片圖片內容
  Widget _buildCardImageContent(String imagePath) {
    // 由於是假資料路徑，暫時使用預設圖片
    return _buildDefaultCardImage();
  }

  /// 建立預設名片圖片
  Widget _buildDefaultCardImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.credit_card,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  /// 建立名片資訊
  Widget _buildCardInfo(BusinessCard card) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeScreen = screenWidth > 600; // 平板或大螢幕
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 姓名 - 大標題
            Text(
              card.name,
              style: (isLargeScreen 
                  ? AppTextStyles.headline5 
                  : AppTextStyles.headline6
              ).copyWith(
                color: AppColors.primaryText,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: screenWidth * 0.01), // 1% 螢幕寬度間距
            
            // 公司名稱 - 主要副標題
            if (card.company != null) ...[
              Text(
                card.company!,
                style: (isLargeScreen 
                    ? AppTextStyles.bodyLarge 
                    : AppTextStyles.bodyMedium
                ).copyWith(
                  color: AppColors.secondaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: screenWidth * 0.005), // 0.5% 間距
            ],
            
            // 職稱 - 次要副標題
            if (card.jobTitle != null) ...[
              Text(
                card.jobTitle!,
                style: (isLargeScreen 
                    ? AppTextStyles.bodyMedium 
                    : AppTextStyles.bodySmall
                ).copyWith(
                  color: AppColors.secondaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );
      },
    );
  }


  /// 顯示新增名片選項
  void _showCreateCardOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖曳指示器
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(
                vertical: AppDimensions.space2,
              ),
              decoration: BoxDecoration(
                color: AppColors.separator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimensions.space4),
              child: Text(
                '新增名片',
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ),
            _buildCreateOption(
              context,
              Icons.camera_alt,
              '拍照',
              '使用相機拍攝名片',
              () => _navigateToCamera(context),
            ),
            _buildCreateOption(
              context,
              Icons.photo_library,
              '從相簿選擇',
              '選擇已存在的名片圖片',
              () => _navigateToPhotoLibrary(context),
            ),
            _buildCreateOption(
              context,
              Icons.edit,
              '手動輸入',
              '手動建立名片資料',
              () => _navigateToManualCreate(context),
            ),
            const SizedBox(height: AppDimensions.space2),
          ],
        ),
      ),
    );
  }


  /// 顯示名片操作選項
  void _showCardOptions(
    BuildContext context,
    BusinessCard card,
    CardListViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖曳指示器
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(
                vertical: AppDimensions.space2,
              ),
              decoration: BoxDecoration(
                color: AppColors.separator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primaryText),
              title: Text(
                '編輯',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryText,
                ),
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
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryText,
                ),
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
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
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
  Future<void> _confirmDeleteCard(
    BuildContext context,
    BusinessCard card,
    CardListViewModel viewModel,
  ) async {
    final confirmed = await DialogPresenter.showDeleteConfirmation(
      context,
      title: '刪除名片',
      content: '確定要刪除「${card.name}」的名片嗎？此操作無法復原。',
      deleteText: '刪除',
      cancelText: '取消',
    );

    if (confirmed == true) {
      final success = await viewModel.deleteCard(card.id);
      if (!context.mounted) {
        return;
      }

      if (success) {
        ToastHelper.showSnackBar(context, '名片已刪除', type: ToastType.success);
      } else {
        ToastHelper.showSnackBar(context, '刪除名片失敗', type: ToastType.error);
      }
    }
  }

  /// 導航到名片詳情頁面
  void _navigateToCardDetail(BuildContext context, BusinessCard card) {
    // 導航到名片詳情頁面
    context.push('${AppRoutes.cardDetail}/${card.id}');
  }

  /// 建立選項項目
  Widget _buildCreateOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: AppDimensions.iconSmall,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.secondaryText,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  /// 導航到相機頁面
  void _navigateToCamera(BuildContext context) {
    context.push(AppRoutes.camera);
  }

  /// 導航到相簿選擇（暫時跳轉到相機）
  void _navigateToPhotoLibrary(BuildContext context) {
    // TODO: 實作相簿選擇功能，暫時跳轉到相機
    context.push(AppRoutes.camera);
  }

  /// 導航到手動建立頁面
  void _navigateToManualCreate(BuildContext context) {
    context.push('/card-detail/manual');
  }

  /// 導航到名片編輯頁面
  void _navigateToCardEdit(BuildContext context, BusinessCard card) {
    // 導航到名片編輯頁面
    context.push('/card-detail/${card.id}/edit');
  }

  /// 分享名片
  void _shareCard(BuildContext context, BusinessCard card) {
    // TODO: 實作名片分享功能
    ToastHelper.showSnackBar(context, '分享功能尚未實作');
  }
}
