import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// 名片列表搜尋列
///
/// 提供名片搜尋功能，支援：
/// - 展開/收縮動畫
/// - 即時搜尋回調
/// - 清除搜尋功能
/// - 自訂樣式和提示文字
class CardListSearchBar extends StatefulWidget {
  const CardListSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onExpansionChanged,
    this.hintText = '搜尋姓名、公司、電話...',
    this.isExpanded = false,
    this.showClearButton = true,
    this.autofocus = false,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  /// 文字控制器
  final TextEditingController? controller;

  /// 搜尋內容變更回調
  final ValueChanged<String>? onChanged;

  /// 搜尋提交回調
  final ValueChanged<String>? onSubmitted;

  /// 展開狀態變更回調
  final ValueChanged<bool>? onExpansionChanged;

  /// 提示文字
  final String hintText;

  /// 是否展開
  final bool isExpanded;

  /// 是否顯示清除按鈕
  final bool showClearButton;

  /// 是否自動聚焦
  final bool autofocus;

  /// 動畫持續時間
  final Duration animationDuration;

  @override
  State<CardListSearchBar> createState() => _CardListSearchBarState();
}

class _CardListSearchBarState extends State<CardListSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;

    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _expandAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1, curve: Curves.easeIn),
      ),
    );

    _controller.addListener(_onTextChanged);

    if (widget.isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CardListSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged?.call(_controller.text);
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  void _toggleExpansion() {
    final newExpanded = !widget.isExpanded;
    widget.onExpansionChanged?.call(newExpanded);

    if (!newExpanded) {
      _clearSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 搜尋圖示按鈕
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              widget.isExpanded ? Icons.arrow_back : Icons.search,
              key: ValueKey(widget.isExpanded),
              color: AppColors.primaryText,
              size: AppDimensions.iconMedium,
            ),
          ),
          onPressed: _toggleExpansion,
        ),

        // 展開的搜尋輸入框
        Expanded(
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return SizeTransition(
                sizeFactor: _expandAnimation,
                axisAlignment: -1,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildSearchField(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 建立搜尋輸入框
  Widget _buildSearchField() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(right: AppDimensions.space2),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.separator),
      ),
      child: Row(
        children: [
          // 搜尋輸入框
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: widget.autofocus,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primaryText,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.placeholder,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space3,
                  vertical: AppDimensions.space2,
                ),
                isDense: true,
              ),
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.search,
            ),
          ),

          // 清除按鈕
          if (widget.showClearButton && _hasText) _buildClearButton(),
        ],
      ),
    );
  }

  /// 建立清除按鈕
  Widget _buildClearButton() {
    return IconButton(
      icon: const Icon(
        Icons.clear,
        color: AppColors.secondaryText,
        size: AppDimensions.iconSmall,
      ),
      onPressed: _clearSearch,
      padding: const EdgeInsets.all(AppDimensions.space1),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}

/// 搜尋建議元件
///
/// 顯示搜尋建議列表
class SearchSuggestions extends StatelessWidget {
  const SearchSuggestions({
    required this.suggestions,
    super.key,
    this.onSuggestionTap,
    this.maxHeight = 200,
    this.showNoResults = true,
    this.noResultsText = '無搜尋結果',
  });

  /// 建議列表
  final List<String> suggestions;

  /// 建議點擊回調
  final ValueChanged<String>? onSuggestionTap;

  /// 最大高度
  final double maxHeight;

  /// 是否顯示無結果提示
  final bool showNoResults;

  /// 無結果提示文字
  final String noResultsText;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty && !showNoResults) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.separator),
        boxShadow: AppDimensions.shadowMedium,
      ),
      child: suggestions.isEmpty ? _buildNoResults() : _buildSuggestionsList(),
    );
  }

  /// 建立無結果提示
  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.space4),
      child: Center(
        child: Text(
          noResultsText,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  /// 建立建議列表
  Widget _buildSuggestionsList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space1),
      itemCount: suggestions.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: AppColors.separator),
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return ListTile(
          leading: const Icon(
            Icons.search,
            color: AppColors.secondaryText,
            size: AppDimensions.iconSmall,
          ),
          title: Text(
            suggestion,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryText,
            ),
          ),
          onTap: () => onSuggestionTap?.call(suggestion),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space4,
            vertical: AppDimensions.space1,
          ),
        );
      },
    );
  }
}

/// 搜尋過濾器元件
///
/// 提供搜尋過濾選項
class SearchFilters extends StatelessWidget {
  const SearchFilters({
    required this.filters,
    required this.selectedFilters,
    super.key,
    this.onFilterChanged,
    this.showTitle = true,
    this.title = '篩選條件',
  });

  /// 可用過濾器
  final Map<String, String> filters;

  /// 已選擇的過濾器
  final Set<String> selectedFilters;

  /// 過濾器變更回調
  final ValueChanged<Set<String>>? onFilterChanged;

  /// 是否顯示標題
  final bool showTitle;

  /// 標題文字
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space4),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTitle) ...[
            Text(
              title,
              style: AppTextStyles.headline6.copyWith(
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppDimensions.space3),
          ],
          Wrap(
            spacing: AppDimensions.space2,
            runSpacing: AppDimensions.space2,
            children: filters.entries.map((entry) {
              final isSelected = selectedFilters.contains(entry.key);
              return FilterChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (selected) {
                  final newFilters = Set<String>.from(selectedFilters);
                  if (selected) {
                    newFilters.add(entry.key);
                  } else {
                    newFilters.remove(entry.key);
                  }
                  onFilterChanged?.call(newFilters);
                },
                backgroundColor: AppColors.background,
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.primaryText,
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.separator,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
