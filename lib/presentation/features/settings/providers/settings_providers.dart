import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../view_models/settings_view_model.dart';
import '../view_models/ai_settings_view_model.dart';
import '../view_models/export_view_model.dart';

/// SharedPreferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences provider must be overridden');
});

/// DeviceInfoPlugin Provider
final deviceInfoProvider = Provider<DeviceInfoPlugin>((ref) {
  return DeviceInfoPlugin();
});

/// SettingsViewModel Provider
final settingsViewModelProvider = StateNotifierProvider<SettingsViewModel, SettingsState>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  
  return SettingsViewModel(
    preferences: preferences,
  );
});

/// AISettingsViewModel Provider
final aiSettingsViewModelProvider = StateNotifierProvider<AISettingsViewModel, AISettingsState>((ref) {
  throw UnimplementedError('AISettingsViewModel provider must be overridden');
});

/// ExportViewModel Provider
final exportViewModelProvider = StateNotifierProvider<ExportViewModel, ExportState>((ref) {
  throw UnimplementedError('ExportViewModel provider must be overridden');
});