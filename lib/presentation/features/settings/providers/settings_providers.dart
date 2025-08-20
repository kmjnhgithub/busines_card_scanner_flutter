import 'package:busines_card_scanner_flutter/presentation/features/settings/view_models/ai_settings_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/view_models/export_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/view_models/settings_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/data_providers.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences provider must be overridden');
});

/// DeviceInfoPlugin Provider
final deviceInfoProvider = Provider<DeviceInfoPlugin>((ref) {
  return DeviceInfoPlugin();
});

/// SettingsViewModel Provider
final settingsViewModelProvider =
    StateNotifierProvider<SettingsViewModel, SettingsState>((ref) {
      final preferences = ref.watch(sharedPreferencesProvider);

      return SettingsViewModel(preferences: preferences);
    });

/// AISettingsViewModel Provider
/// 符合 Clean Architecture：透過 Provider 取得依賴，而不是直接注入
final aiSettingsViewModelProvider =
    StateNotifierProvider<AISettingsViewModel, AISettingsState>((ref) {
      final secureStorage = ref.watch(enhancedSecureStorageProvider);
      final openAIService = ref.watch(openAIServiceProvider);

      return AISettingsViewModel(
        secureStorage: secureStorage,
        openAIService: openAIService,
      );
    });

/// ExportViewModel Provider
final exportViewModelProvider =
    StateNotifierProvider<ExportViewModel, ExportState>((ref) {
      throw UnimplementedError('ExportViewModel provider must be overridden');
    });
