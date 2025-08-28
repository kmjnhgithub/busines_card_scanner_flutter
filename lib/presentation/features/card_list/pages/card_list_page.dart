import 'package:busines_card_scanner_flutter/core/utils/debouncer.dart';
import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_list/view_models/card_list_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_list/widgets/card_list_item.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/dialog_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/toast_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/router/app_routes.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// 名片列表頁面
///
/// 顯示所有名片的列表，支援搜尋、排序、刪除等功能
class CardListPage extends ConsumerStatefulWidget {
  const CardListPage({super.key});

  @override
  ConsumerState<CardListPage> createState() => _CardListPageState();
}

class _CardListPageState extends ConsumerState<CardListPage> {
  bool _isSearchExpanded = false;

  /// 搜尋防抖器，避免頻繁觸發搜尋操作
  late final Debouncer _searchDebouncer;

  /// 搜尋文字控制器，管理搜尋輸入
  late final TextEditingController _searchController;

  /// 圖片選擇器，用於從相簿選擇圖片
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 初始化搜尋防抖器
    _searchDebouncer = Debouncer();
    // 初始化搜尋控制器
    _searchController = TextEditingController();

    // 初始載入名片列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cardListViewModelProvider.notifier).loadCards();
    });
  }

  @override
  void dispose() {
    // 清理搜尋防抖器
    _searchDebouncer.dispose();
    // 清理搜尋控制器
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
      centerTitle: true,
      // 強制標題置中
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        // 使用簡單的 layoutBuilder，避免 Stack 導致的位置問題
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return currentChild ?? const SizedBox.shrink();
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          // 判斷是搜尋欄還是標題
          final isSearchBar = child.key == const ValueKey('searchBar');

          // 搜尋欄：從左側滑入 + 淡入
          if (isSearchBar) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(-0.3, 0), // 稍微從左側滑入
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                child: child,
              ),
            );
          }
          // 標題：只有淡入淡出，沒有任何位移
          else {
            return FadeTransition(opacity: animation, child: child);
          }
        },
        child: _isSearchExpanded
            ? _buildSearchBar(viewModel)
            : Text(
                '名片',
                key: const ValueKey('title'),
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
      actions: [
        // 固定寬度容器避免按鈕切換時的位置跳動
        SizedBox(
          width: AppDimensions.appBarActionsWidth,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.centerRight,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _isSearchExpanded
                ? Container(
                    key: const ValueKey('cancel'),
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isSearchExpanded = false;
                        });
                        // 清空搜尋控制器和搜尋結果
                        _searchController.clear();
                        viewModel.searchCards('');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space3,
                          vertical: AppDimensions.space2,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : Row(
                    key: const ValueKey('actions'),
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: AppColors.primary,
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
                          Icons.add,
                          color: AppColors.primary,
                          size: AppDimensions.iconMedium,
                        ),
                        onPressed: () => _showCreateCardOptions(context),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// 建立主體內容
  Widget _buildBody(
    BuildContext context,
    CardListState state,
    CardListViewModel viewModel,
  ) {
    // 移除搜尋欄區域，直接返回主要內容
    return _buildMainContent(context, state, viewModel);
  }

  /// 建立搜尋欄 Widget（在 AppBar title 位置）
  Widget _buildSearchBar(CardListViewModel viewModel) {
    return Container(
      key: const ValueKey('searchBar'),
      height: AppDimensions.searchBarHeight,
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: TextField(
        autofocus: true,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryText),
        decoration: InputDecoration(
          hintText: '搜尋姓名、公司、電話、Email',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.placeholder,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.secondaryText,
            size: AppDimensions.iconSmall,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space3,
            vertical: AppDimensions.space2,
          ),
          isDense: true,
        ),
        onChanged: (query) {
          // 使用 debouncer 防止頻繁觸發搜尋
          _searchDebouncer.run(() {
            viewModel.searchCards(query);
          });
        },
        onSubmitted: (query) {
          viewModel.searchCards(query);
        },
        textInputAction: TextInputAction.search,
      ),
    );
  }

  /// 建立主要內容
  Widget _buildMainContent(
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
    final state = ref.watch(cardListViewModelProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 添加淡入動畫效果
            AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isSearchResult ? Icons.search_off : Icons.credit_card_outlined,
                size: AppDimensions.iconExtraLarge,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppDimensions.space4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                isSearchResult ? '找不到「${state.searchQuery}」的相關名片' : '還沒有名片',
                key: ValueKey(isSearchResult),
                style: AppTextStyles.headline3.copyWith(
                  color: AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppDimensions.space2),
            Text(
              isSearchResult ? '試著搜尋其他關鍵字，或使用不同的搜尋條件' : '點擊右上角的 + 新增第一張名片',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),

            // 如果是搜尋結果為空，提供建議操作
            if (isSearchResult) ...[
              const SizedBox(height: AppDimensions.space6),
              ThemedButton(
                text: '清除搜尋',
                onPressed: () {
                  // 透過 ref 清除搜尋
                  ref.read(cardListViewModelProvider.notifier).searchCards('');
                },
                type: ThemedButtonType.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 建立名片列表
  Widget _buildCardList(List<BusinessCard> cards, CardListViewModel viewModel) {
    final state = ref.watch(cardListViewModelProvider);

    return Column(
      children: [
        // 如果正在搜尋且有查詢條件，顯示搜尋結果統計
        if (state.searchQuery.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space4,
              vertical: AppDimensions.space2,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  size: AppDimensions.iconSmall,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: AppDimensions.space2),
                Expanded(
                  child: Text(
                    '找到 ${cards.length} 個結果',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
                // 清除搜尋按鈕
                TextButton(
                  onPressed: () {
                    viewModel.searchCards('');
                  },
                  child: Text(
                    '清除',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.separator),
        ],

        // 名片列表
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              key: ValueKey(cards.length),
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04, // 4% 螢幕寬度
                vertical: AppDimensions.space2,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                // 為每個項目添加進場動畫
                return AnimatedContainer(
                  duration: Duration(milliseconds: 150 + (index * 50)),
                  curve: Curves.easeOut,
                  child: _buildCardItem(context, card, viewModel),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 建立名片項目
  Widget _buildCardItem(
    BuildContext context,
    BusinessCard card,
    CardListViewModel viewModel,
  ) {
    return CardListItem(
      card: card,
      onTap: () => _navigateToCardDetail(context, card),
      onLongPress: () => _showCardOptions(context, card, viewModel),
      onMoreActions: () => _showCardOptions(context, card, viewModel),
      onDelete: () => _handleSwipeToDelete(context, card, viewModel),
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
              () async => _navigateToPhotoLibrary(context),
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
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
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

  /// 導航到相簿選擇
  Future<void> _navigateToPhotoLibrary(BuildContext context) async {
    try {
      // 從相簿選擇圖片
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null && context.mounted) {
        // 導航到 OCR 處理頁面，使用路徑參數
        await context.push(
          '${AppRoutes.ocrProcessing}/${Uri.encodeComponent(image.path)}',
        );
      }
    } on Exception {
      if (context.mounted) {
        ToastHelper.showSnackBar(context, '選擇圖片失敗，請重試', type: ToastType.error);
      }
    }
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

  /// 處理滑動刪除
  Future<bool> _handleSwipeToDelete(
    BuildContext context,
    BusinessCard card,
    CardListViewModel viewModel,
  ) async {
    // 使用 iOS 風格的確認對話框
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('永久刪除名片'),
          content: Text('⚠️ 確定要永久刪除「${card.name}」的名片嗎？\n\n此操作無法復原。'),
          actions: [
            CupertinoDialogAction(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('永久刪除'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // 執行刪除操作
      final success = await viewModel.deleteCard(card.id);

      if (!context.mounted) {
        return success;
      }

      if (success) {
        // 顯示永久刪除成功提示
        ToastHelper.showSnackBar(context, '名片已永久刪除', type: ToastType.success);
      } else {
        // 顯示錯誤提示
        ToastHelper.showSnackBar(context, '刪除失敗，請稍後重試', type: ToastType.error);
      }

      return success;
    }

    return false; // 用戶取消
  }
}
