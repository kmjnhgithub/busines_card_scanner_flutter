import 'package:busines_card_scanner_flutter/domain/usecases/ai/manage_api_key_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/ai/validate_ai_service_usecase.dart';
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

/// ManageApiKeyUseCase Provider
final manageApiKeyUseCaseProvider = Provider<ManageApiKeyUseCase>((ref) {
  final repository = ref.watch(apiKeyRepositoryProvider);
  return ManageApiKeyUseCaseImpl(repository: repository);
});

/// ValidateAIServiceUseCase Provider
final validateAIServiceUseCaseProvider = Provider<ValidateAIServiceUseCase>((
  ref,
) {
  final repository = ref.watch(aiRepositoryProvider);
  return ValidateAIServiceUseCaseImpl(repository: repository);
});

/// AISettingsViewModel Provider
/// 符合 Clean Architecture：只依賴 Domain 層的 UseCase
final aiSettingsViewModelProvider =
    StateNotifierProvider<AISettingsViewModel, AISettingsState>((ref) {
      final manageApiKeyUseCase = ref.watch(manageApiKeyUseCaseProvider);
      final validateAIServiceUseCase = ref.watch(
        validateAIServiceUseCaseProvider,
      );

      return AISettingsViewModel(
        manageApiKeyUseCase: manageApiKeyUseCase,
        validateAIServiceUseCase: validateAIServiceUseCase,
      );
    });

/// ExportViewModel Provider
final exportViewModelProvider =
    StateNotifierProvider<ExportViewModel, ExportState>((ref) {
      throw UnimplementedError('ExportViewModel provider must be overridden');
    });
