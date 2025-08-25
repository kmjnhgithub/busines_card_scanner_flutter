import 'dart:async';

import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

/// 動畫搜尋欄元件
///
/// 模擬 iOS 原生 UISearchController 的行為：
/// - 點擊搜尋圖示展開搜尋欄
/// - 300ms 展開/收縮動畫
/// - 300ms debounce 防止過度搜尋
/// - 展開時自動聚焦
/// - 與 Swift 版本完全對齊的體驗
class AnimatedSearchBar extends StatefulWidget {
  const AnimatedSearchBar({
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.hintText = '搜尋姓名、公司、電話、Email',
    this.animationDuration = const Duration(milliseconds: 300),
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  /// 搜尋內容變更回調（已套用 debounce）
  final ValueChanged<String>? onChanged;

  /// 搜尋提交回調
  final ValueChanged<String>? onSubmitted;

  /// 提示文字（與 Swift 版本對齊）
  final String hintText;

  /// 動畫持續時間（與 Swift 版本對齐：300ms）
  final Duration animationDuration;

  /// Debounce 延遲時間（與 Swift 版本對齊：300ms）
  final Duration debounceDuration;

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _fadeAnimation;

  late TextEditingController _textController;
  late FocusNode _focusNode;

  Timer? _debounceTimer;
  bool _isExpanded = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();

    // 初始化動畫控制器
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // 寬度動畫：從 0 到 1
    _widthAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 淡入動畫：延遲 150ms（模擬 iOS 行為）
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1, curve: Curves.easeIn),
      ),
    );

    // 初始化文字控制器和焦點節點
    _textController = TextEditingController();
    _focusNode = FocusNode();

    // 監聽文字變更
    _textController.addListener(_onTextChanged);

    // 監聽焦點變更
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    _textController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 文字變更處理（套用 debounce）
  void _onTextChanged() {
    final hasText = _textController.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }

    // 取消上次的 debounce timer
    _debounceTimer?.cancel();

    // 設定新的 debounce timer
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onChanged?.call(_textController.text);
    });
  }

  /// 焦點變更處理
  void _onFocusChanged() {
    // 如果失去焦點且沒有文字，自動收縮搜尋欄
    if (!_focusNode.hasFocus && !_hasText && _isExpanded) {
      _collapseSearchBar();
    }
  }

  /// 展開搜尋欄
  void _expandSearchBar() {
    setState(() {
      _isExpanded = true;
    });

    _animationController.forward().then((_) {
      // 動畫完成後自動聚焦（模擬 iOS 行為）
      _focusNode.requestFocus();
    });
  }

  /// 收縮搜尋欄
  void _collapseSearchBar() {
    // 清除搜尋內容
    _textController.clear();
    _focusNode.unfocus();

    setState(() {
      _isExpanded = false;
      _hasText = false;
    });

    _animationController.reverse();

    // 立即觸發清空搜尋
    widget.onChanged?.call('');
  }

  /// 切換搜尋欄狀態
  void _toggleSearchBar() {
    if (_isExpanded) {
      _collapseSearchBar();
    } else {
      _expandSearchBar();
    }
  }

  /// 清除搜尋內容
  void _clearSearch() {
    _textController.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 搜尋/返回圖示按鈕
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isExpanded ? Icons.arrow_back : Icons.search,
              key: ValueKey(_isExpanded),
              color: AppColors.primaryText,
              size: AppDimensions.iconMedium,
            ),
          ),
          onPressed: _toggleSearchBar,
        ),

        // 展開的搜尋輸入框
        Expanded(
          child: AnimatedBuilder(
            animation: _widthAnimation,
            builder: (context, child) {
              return Container(
                width:
                    MediaQuery.of(context).size.width *
                    0.7 *
                    _widthAnimation.value,
                height: _widthAnimation.value > 0 ? 40 : 0,
                margin: EdgeInsets.only(
                  right: AppDimensions.space2 * _widthAnimation.value,
                ),
                child: _widthAnimation.value > 0.1
                    ? FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildSearchField(),
                      )
                    : const SizedBox.shrink(),
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
              controller: _textController,
              focusNode: _focusNode,
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

          // 清除按鈕（當有文字時顯示）
          AnimatedOpacity(
            opacity: _hasText ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: _hasText
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppColors.secondaryText,
                      size: AppDimensions.iconSmall,
                    ),
                    onPressed: _clearSearch,
                    padding: const EdgeInsets.all(AppDimensions.space1),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  )
                : const SizedBox(width: 32, height: 32),
          ),
        ],
      ),
    );
  }
}

/// 搜尋結果高亮顯示工具類
class SearchHighlighter {
  /// 建立高亮文字 Widget
  ///
  /// 將搜尋關鍵字在文字中高亮顯示（黃色背景）
  static Widget highlightText(
    String text,
    String searchQuery, {
    TextStyle? style,
    TextStyle? highlightStyle,
  }) {
    if (searchQuery.isEmpty) {
      return Text(text, style: style);
    }

    final defaultStyle = style ?? AppTextStyles.bodyMedium;
    final defaultHighlightStyle =
        highlightStyle ??
        defaultStyle.copyWith(
          backgroundColor: Colors.yellow.withValues(alpha: 0.3),
          fontWeight: FontWeight.w600,
        );

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = searchQuery.toLowerCase();

    int start = 0;
    while (start < text.length) {
      final int index = lowerText.indexOf(lowerQuery, start);

      if (index == -1) {
        // 沒有找到更多匹配，添加剩餘文字
        spans.add(TextSpan(text: text.substring(start), style: defaultStyle));
        break;
      }

      // 添加匹配前的文字
      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: defaultStyle),
        );
      }

      // 添加高亮的匹配文字
      spans.add(
        TextSpan(
          text: text.substring(index, index + searchQuery.length),
          style: defaultHighlightStyle,
        ),
      );

      start = index + searchQuery.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
