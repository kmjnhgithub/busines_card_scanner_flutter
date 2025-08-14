import 'package:busines_card_scanner_flutter/core/constants/app_constants.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/providers/settings_providers.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/view_models/settings_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/dialog_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/widgets/shared/themed_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 設定頁面
///
/// 提供應用程式的各種設定選項：
/// - 語言設定
/// - 主題設定
/// - 通知設定
/// - AI 設定
/// - 匯出資料
/// - 關於
/// - 重置設定
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // 載入版本資訊
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsViewModelProvider.notifier).loadAppVersion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('設定'), centerTitle: true),
      body: settingsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (settingsState.error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      settingsState.error!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildLanguageSection(context, settingsState),
                      const SizedBox(height: 8),
                      _buildThemeSection(context, settingsState),
                      const SizedBox(height: 8),
                      _buildNotificationSection(context, settingsState),
                      const SizedBox(height: 24),
                      _buildNavigationSection(context),
                      const SizedBox(height: 24),
                      _buildInfoSection(context, settingsState),
                      const SizedBox(height: 8),
                      _buildResetSection(context),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// 建立語言設定區塊
  Widget _buildLanguageSection(BuildContext context, SettingsState state) {
    return ThemedCard(
      child: ListTile(
        leading: const Icon(Icons.language),
        title: const Text('語言設定'),
        subtitle: Text(_getLanguageDisplayName(state.language)),
        trailing: DropdownButton<SettingsLanguage>(
          key: const Key('language_dropdown'),
          value: state.language,
          underline: const SizedBox(),
          items: SettingsLanguage.values.map((language) {
            return DropdownMenuItem<SettingsLanguage>(
              value: language,
              child: Text(_getLanguageDisplayName(language)),
            );
          }).toList(),
          onChanged: (language) {
            if (language != null) {
              ref
                  .read(settingsViewModelProvider.notifier)
                  .changeLanguage(language);
            }
          },
        ),
      ),
    );
  }

  /// 建立主題設定區塊
  Widget _buildThemeSection(BuildContext context, SettingsState state) {
    return ThemedCard(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主題設定'),
            subtitle: Text(_getThemeDisplayName(state.theme)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: SegmentedButton<SettingsTheme>(
              segments: SettingsTheme.values.map((theme) {
                return ButtonSegment<SettingsTheme>(
                  value: theme,
                  label: Text(_getThemeDisplayName(theme)),
                  icon: Icon(_getThemeIcon(theme)),
                );
              }).toList(),
              selected: {state.theme},
              onSelectionChanged: (Set<SettingsTheme> themes) {
                if (themes.isNotEmpty) {
                  ref
                      .read(settingsViewModelProvider.notifier)
                      .changeTheme(themes.first);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 建立通知設定區塊
  Widget _buildNotificationSection(BuildContext context, SettingsState state) {
    return ThemedCard(
      child: SwitchListTile(
        secondary: const Icon(Icons.notifications),
        title: const Text('通知'),
        subtitle: Text(state.notificationsEnabled ? '已開啟' : '已關閉'),
        value: state.notificationsEnabled,
        onChanged: (value) {
          ref
              .read(settingsViewModelProvider.notifier)
              .toggleNotifications(enabled: value);
        },
      ),
    );
  }

  /// 建立導航設定區塊
  Widget _buildNavigationSection(BuildContext context) {
    return Column(
      children: [
        ThemedCard(
          child: ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text('AI 設定'),
            subtitle: const Text('配置 OpenAI API 金鑰'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToAISettings(context),
          ),
        ),
        const SizedBox(height: 8),
        ThemedCard(
          child: ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('匯出資料'),
            subtitle: const Text('備份名片資料'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToExport(context),
          ),
        ),
      ],
    );
  }

  /// 建立資訊區塊
  Widget _buildInfoSection(BuildContext context, SettingsState state) {
    return ThemedCard(
      child: ListTile(
        leading: const Icon(Icons.info),
        title: const Text('關於'),
        subtitle: Text(_getVersionText(state)),
        onTap: () => _showAboutDialog(context, state),
      ),
    );
  }

  /// 建立重置設定區塊
  Widget _buildResetSection(BuildContext context) {
    return ThemedCard(
      child: ListTile(
        leading: const Icon(Icons.restore, color: Colors.red),
        title: const Text('重置設定', style: TextStyle(color: Colors.red)),
        subtitle: const Text('恢復所有設定為預設值'),
        onTap: () => _showResetConfirmation(context),
      ),
    );
  }

  /// 獲取語言顯示名稱
  String _getLanguageDisplayName(SettingsLanguage language) {
    switch (language) {
      case SettingsLanguage.system:
        return '跟隨系統';
      case SettingsLanguage.zhTw:
        return '繁體中文';
      case SettingsLanguage.enUs:
        return 'English';
    }
  }

  /// 獲取主題顯示名稱
  String _getThemeDisplayName(SettingsTheme theme) {
    switch (theme) {
      case SettingsTheme.system:
        return '系統';
      case SettingsTheme.light:
        return '淺色';
      case SettingsTheme.dark:
        return '深色';
    }
  }

  /// 獲取主題圖示
  IconData _getThemeIcon(SettingsTheme theme) {
    switch (theme) {
      case SettingsTheme.system:
        return Icons.auto_mode;
      case SettingsTheme.light:
        return Icons.light_mode;
      case SettingsTheme.dark:
        return Icons.dark_mode;
    }
  }

  /// 獲取版本文字
  String _getVersionText(SettingsState state) {
    if (state.appVersion.isEmpty) {
      return '載入中...';
    }
    return '版本 ${state.appVersion} (${state.buildNumber})';
  }

  /// 導航到 AI 設定頁面
  void _navigateToAISettings(BuildContext context) {
    Navigator.of(context).pushNamed('/ai_settings');
  }

  /// 導航到匯出頁面
  void _navigateToExport(BuildContext context) {
    Navigator.of(context).pushNamed('/export');
  }

  /// 顯示關於對話框
  void _showAboutDialog(BuildContext context, SettingsState state) {
    DialogPresenter.showInfo(
      context,
      title: '關於應用程式',
      content:
          '''
${AppConstants.appName}

版本：${state.appVersion.isEmpty ? '載入中...' : state.appVersion}
Build：${state.buildNumber.isEmpty ? '載入中...' : state.buildNumber}

這是一個智能名片掃描應用程式，使用 Flutter 開發。

功能特色：
• 快速掃描名片
• AI 智能識別文字
• 支援多種匯出格式
• 本地安全儲存

© 2024 ${AppConstants.appName}
      ''',
      confirmText: '關閉',
    );
  }

  /// 顯示重置確認對話框
  void _showResetConfirmation(BuildContext context) {
    DialogPresenter.showConfirmation(
      context,
      title: '重置設定',
      content: '確定要重置所有設定嗎？此操作無法復原。',
      confirmText: '重置',
      cancelText: '取消',
      onConfirm: () {
        ref.read(settingsViewModelProvider.notifier).resetSettings();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('設定已重置'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }
}
