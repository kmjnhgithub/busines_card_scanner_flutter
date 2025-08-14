import 'package:busines_card_scanner_flutter/presentation/features/settings/view_models/ai_settings_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_dimensions.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_button.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_card.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// AI 設定頁面
///
/// 提供以下功能：
/// - API Key 管理（儲存、刪除、顯示/隱藏）
/// - 連線測試
/// - 使用量統計查看
/// - OpenAI 平台說明和連結
class AISettingsPage extends ConsumerStatefulWidget {
  const AISettingsPage({super.key});

  @override
  ConsumerState<AISettingsPage> createState() => _AISettingsPageState();
}

class _AISettingsPageState extends ConsumerState<AISettingsPage> {
  late final TextEditingController _apiKeyController;
  bool _isApiKeyVisible = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(aiSettingsViewModelProvider.notifier);
    final state = ref.watch(aiSettingsViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 設定'),
        backgroundColor: AppColors.getBackgroundColor(theme.brightness),
        elevation: 0,
      ),
      backgroundColor: AppColors.getBackgroundColor(theme.brightness),
      body: SingleChildScrollView(
        padding: AppDimensions.paddingPage,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildApiKeySection(context, viewModel, state),
              const SizedBox(height: AppDimensions.space6),
              _buildConnectionTestSection(context, viewModel, state),
              const SizedBox(height: AppDimensions.space6),
              _buildUsageStatsSection(context, viewModel, state),
              const SizedBox(height: AppDimensions.space6),
              _buildInstructionsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 建立 API Key 管理區塊
  Widget _buildApiKeySection(
    BuildContext context,
    AISettingsViewModel viewModel,
    AISettingsState state,
  ) {
    return ThemedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.key,
                color: AppColors.primary,
                size: AppDimensions.iconMedium,
              ),
              const SizedBox(width: AppDimensions.space2),
              Text(
                'API Key 管理',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(Theme.of(context).brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space4),

          // API Key 輸入欄位
          ThemedTextField(
            controller: _apiKeyController,
            label: 'OpenAI API Key',
            hint: state.hasApiKey && !_isApiKeyVisible
                ? 'sk-...${_getMaskedApiKeySuffix()}'
                : '請輸入 OpenAI API Key',
            type: ThemedTextFieldType.password,
            obscureText: !_isApiKeyVisible,
            prefixIcon: Icons.vpn_key,
            suffixIcon: _isApiKeyVisible
                ? Icons.visibility_off
                : Icons.visibility,
            onSuffixIconPressed: () {
              setState(() {
                _isApiKeyVisible = !_isApiKeyVisible;
              });
            },
            validationState: state.error != null
                ? ThemedTextFieldValidationState.error
                : ThemedTextFieldValidationState.normal,
            errorText: state.error,
            enabled: !state.isLoading,
            semanticLabel: 'API Key 輸入欄位',
            onChanged: (value) {
              // 清除錯誤狀態
              if (state.error != null) {
                viewModel.clearError();
              }
            },
          ),
          const SizedBox(height: AppDimensions.space4),

          // 操作按鈕
          Row(
            children: [
              Expanded(
                child: ThemedButton(
                  text: '儲存',
                  onPressed: state.isLoading
                      ? null
                      : () => _saveApiKey(viewModel),
                  isLoading: state.isLoading,
                  semanticLabel: '儲存 API Key',
                ),
              ),
              const SizedBox(width: AppDimensions.space2),
              Expanded(
                child: DangerButton(
                  text: '刪除',
                  onPressed: state.hasApiKey && !state.isLoading
                      ? () => _showDeleteConfirmDialog(viewModel)
                      : null,
                  isLoading: state.isLoading,
                ),
              ),
            ],
          ),

          // API Key 狀態指示
          if (state.hasApiKey) ...[
            const SizedBox(height: AppDimensions.space3),
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: AppDimensions.iconSmall,
                ),
                const SizedBox(width: AppDimensions.space1),
                Text(
                  'API Key 已設定',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.success),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 建立連線測試區塊
  Widget _buildConnectionTestSection(
    BuildContext context,
    AISettingsViewModel viewModel,
    AISettingsState state,
  ) {
    return ThemedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.network_check,
                color: AppColors.primary,
                size: AppDimensions.iconMedium,
              ),
              const SizedBox(width: AppDimensions.space2),
              Text(
                '連線測試',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(Theme.of(context).brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space4),

          // 測試按鈕
          ThemedButton(
            text: '測試連線',
            type: ThemedButtonType.outline,
            icon: Icons.play_arrow,
            onPressed: state.hasApiKey && !state.isLoading
                ? () => viewModel.testConnection()
                : null,
            isLoading:
                state.isLoading &&
                state.connectionStatus == ConnectionStatus.connecting,
            expanded: true,
            semanticLabel: '測試連線',
          ),
          const SizedBox(height: AppDimensions.space3),

          // 連線狀態顯示
          _buildConnectionStatusDisplay(context, state),
        ],
      ),
    );
  }

  /// 建立連線狀態顯示
  Widget _buildConnectionStatusDisplay(
    BuildContext context,
    AISettingsState state,
  ) {
    IconData icon;
    Color color;
    String message;

    switch (state.connectionStatus) {
      case ConnectionStatus.connected:
        icon = Icons.check_circle;
        color = AppColors.success;
        message = '連線成功';
        break;
      case ConnectionStatus.failed:
        icon = Icons.error;
        color = AppColors.error;
        message = '連線失敗';
        break;
      case ConnectionStatus.connecting:
        icon = Icons.hourglass_empty;
        color = AppColors.warning;
        message = '連線中...';
        break;
      case ConnectionStatus.unknown:
        icon = Icons.help_outline;
        color = AppColors.placeholder;
        message = '尚未測試';
        break;
    }

    return Container(
      padding: AppDimensions.paddingSmall,
      decoration: BoxDecoration(
        color: AppColors.withOpacity(color, 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.withOpacity(color, 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: AppDimensions.iconMedium),
          const SizedBox(width: AppDimensions.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (state.error != null &&
                    state.connectionStatus == ConnectionStatus.failed)
                  Text(
                    state.error!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 建立使用量統計區塊
  Widget _buildUsageStatsSection(
    BuildContext context,
    AISettingsViewModel viewModel,
    AISettingsState state,
  ) {
    return ThemedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart,
                    color: AppColors.primary,
                    size: AppDimensions.iconMedium,
                  ),
                  const SizedBox(width: AppDimensions.space2),
                  Text(
                    '使用量統計',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextColor(
                        Theme.of(context).brightness,
                      ),
                    ),
                  ),
                ],
              ),
              ThemedButton(
                text: '重新整理',
                type: ThemedButtonType.text,
                size: ThemedButtonSize.small,
                icon: Icons.refresh,
                onPressed: state.hasApiKey && !state.isLoading
                    ? () => viewModel.loadUsageStats()
                    : null,
                isLoading: state.isLoading,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space4),

          // 使用量統計內容
          _buildUsageStatsContent(context, state),
        ],
      ),
    );
  }

  /// 建立使用量統計內容
  Widget _buildUsageStatsContent(BuildContext context, AISettingsState state) {
    if (state.usageStats == null) {
      return Container(
        padding: AppDimensions.paddingMedium,
        child: Column(
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: AppDimensions.iconExtraLarge,
              color: AppColors.placeholder,
            ),
            const SizedBox(height: AppDimensions.space2),
            Text(
              '暫無使用量統計',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.placeholder),
            ),
            if (!state.hasApiKey)
              Text(
                '請先設定 API Key',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.placeholder),
              ),
          ],
        ),
      );
    }

    final stats = state.usageStats!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: '總請求數',
                value: _formatNumber(stats.totalRequests),
                icon: Icons.send,
                iconColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.space2),
            Expanded(
              child: StatsCard(
                title: '總代幣數',
                value: _formatNumber(stats.totalTokens),
                icon: Icons.token,
                iconColor: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space3),
        Container(
          padding: AppDimensions.paddingSmall,
          decoration: BoxDecoration(
            color: AppColors.getCardBackgroundColor(
              Theme.of(context).brightness,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(
              color: AppColors.getBorderColor(Theme.of(context).brightness),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: AppDimensions.iconSmall,
                color: AppColors.getTextColor(
                  Theme.of(context).brightness,
                ).withValues(alpha: 0.7),
              ),
              const SizedBox(width: AppDimensions.space1),
              Text(
                '統計月份：${_formatDate(stats.currentMonth)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.getTextColor(
                    Theme.of(context).brightness,
                  ).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 建立說明區塊
  Widget _buildInstructionsSection(BuildContext context) {
    return ThemedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.help_outline,
                color: AppColors.primary,
                size: AppDimensions.iconMedium,
              ),
              const SizedBox(width: AppDimensions.space2),
              Text(
                '如何取得 API Key',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(Theme.of(context).brightness),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space4),

          Text(
            '1. 前往 OpenAI 官方網站\n'
            '2. 登入或註冊帳號\n'
            '3. 進入 API Keys 頁面\n'
            '4. 點擊「Create new secret key」\n'
            '5. 複製產生的 API Key 並貼上',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.getTextColor(Theme.of(context).brightness),
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppDimensions.space4),

          ThemedButton(
            text: '前往 OpenAI 平台',
            type: ThemedButtonType.outline,
            icon: Icons.open_in_new,
            onPressed: _launchOpenAIWebsite,
            expanded: true,
          ),
          const SizedBox(height: AppDimensions.space2),

          Center(
            child: InkWell(
              onTap: _launchOpenAIWebsite,
              child: Padding(
                padding: AppDimensions.paddingSmall,
                child: Text(
                  'https://platform.openai.com/api-keys',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 儲存 API Key
  void _saveApiKey(AISettingsViewModel viewModel) {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請輸入 API Key')));
      return;
    }

    viewModel.saveApiKey(apiKey);
  }

  /// 顯示刪除確認對話框
  void _showDeleteConfirmDialog(AISettingsViewModel viewModel) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: const Text('確定要刪除 API Key 嗎？此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          DangerButton(
            text: '刪除',
            size: ThemedButtonSize.small,
            onPressed: () {
              Navigator.of(context).pop(true);
              viewModel.deleteApiKey();
              _apiKeyController.clear();
            },
          ),
        ],
      ),
    );
  }

  /// 啟動 OpenAI 網站
  Future<void> _launchOpenAIWebsite() async {
    const url = 'https://platform.openai.com/api-keys';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) {
          return;
        }
        // 複製到剪貼簿
        await Clipboard.setData(const ClipboardData(text: url));
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('網址已複製到剪貼簿')));
      }
    } on Exception catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('無法開啟網頁：$e')));
    }
  }

  /// 獲取遮罩後的 API Key 後綴
  String _getMaskedApiKeySuffix() {
    // 這裡應該從安全儲存中取得真實的 API Key 後綴
    // 現在先返回範例
    return 'abc123';
  }

  /// 格式化數字
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}';
  }
}
