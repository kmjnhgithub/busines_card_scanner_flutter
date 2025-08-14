import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:busines_card_scanner_flutter/presentation/features/settings/view_models/settings_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/providers/settings_providers.dart';

// Mock classes
class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockDeviceInfoPlugin extends Mock implements DeviceInfoPlugin {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('SettingsViewModel Tests', () {
    late MockSharedPreferences mockPrefs;
    late MockDeviceInfoPlugin mockDeviceInfo;
    late ProviderContainer container;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      mockDeviceInfo = MockDeviceInfoPlugin();

      // 設定 Mock 的預設回傳值
      when(() => mockPrefs.getString(any())).thenReturn(null);
      when(() => mockPrefs.getBool(any())).thenReturn(null);
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

      container = ProviderContainer(
        overrides: [
          settingsViewModelProvider.overrideWith(
            (ref) => SettingsViewModel(
              preferences: mockPrefs,
              deviceInfo: mockDeviceInfo,
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('初始狀態', () {
      test('應該有正確的初始狀態', () {
        final state = container.read(settingsViewModelProvider);

        expect(state.isLoading, false);
        expect(state.language, SettingsLanguage.system);
        expect(state.theme, SettingsTheme.system);
        expect(state.notificationsEnabled, true);
        expect(state.appVersion, isEmpty);
        expect(state.buildNumber, isEmpty);
        expect(state.error, isNull);
      });

      test('應該載入儲存的設定值', () {
        // Arrange
        when(() => mockPrefs.getString('app_language'))
            .thenReturn('zh_TW');
        when(() => mockPrefs.getString('app_theme'))
            .thenReturn('dark');
        when(() => mockPrefs.getBool('notifications_enabled'))
            .thenReturn(false);

        // 重新建立 container 以觸發初始化
        container.dispose();
        container = ProviderContainer(
          overrides: [
            settingsViewModelProvider.overrideWith(
              (ref) => SettingsViewModel(
                preferences: mockPrefs,
                deviceInfo: mockDeviceInfo,
              ),
            ),
          ],
        );

        // Act & Assert
        final state = container.read(settingsViewModelProvider);

        expect(state.language, SettingsLanguage.zh_TW);
        expect(state.theme, SettingsTheme.dark);
        expect(state.notificationsEnabled, false);
      });
    });

    group('語言設定', () {
      test('應該成功切換語言為中文', () async {
        // Arrange
        final viewModel = container.read(settingsViewModelProvider.notifier);

        // Act
        await viewModel.changeLanguage(SettingsLanguage.zh_TW);

        // Assert
        final state = viewModel.state;
        expect(state.language, SettingsLanguage.zh_TW);
        expect(state.isLoading, false);
        expect(state.error, isNull);

        verify(() => mockPrefs.setString('app_language', 'zh_TW')).called(1);
      });

      test('應該成功切換語言為英文', () async {
        // Arrange
        final viewModel = container.read(settingsViewModelProvider.notifier);

        // Act
        await viewModel.changeLanguage(SettingsLanguage.en_US);

        // Assert
        final state = viewModel.state;
        expect(state.language, SettingsLanguage.en_US);
        
        verify(() => mockPrefs.setString('app_language', 'en_US')).called(1);
      });

      test('應該成功切換語言為系統預設', () async {
        // Arrange
        final viewModel = container.read(settingsViewModelProvider.notifier);

        // Act
        await viewModel.changeLanguage(SettingsLanguage.system);

        // Assert
        final state = viewModel.state;
        expect(state.language, SettingsLanguage.system);
        
        verify(() => mockPrefs.setString('app_language', 'system')).called(1);
      });

      test('語言切換失敗時應該顯示錯誤', () async {
        // Arrange
        when(() => mockPrefs.setString('app_language', any()))
            .thenThrow(Exception('儲存失敗'));
        final viewModel = container.read(settingsViewModelProvider.notifier);

        // Act
        await viewModel.changeLanguage(SettingsLanguage.zh_TW);

        // Assert
        final state = viewModel.state;
        expect(state.error, isNotNull);
        expect(state.error, contains('儲存語言設定失敗'));
        expect(state.isLoading, false);
      });

      test('語言切換期間應該顯示載入狀態', () async {
        // Arrange
        final viewModel = container.read(settingsViewModelProvider.notifier);
        bool loadingStateObserved = false;
        
        // 監聽狀態變化
        container.listen(settingsViewModelProvider, (previous, next) {
          if (next.isLoading) {
            loadingStateObserved = true;
          }
        });

        // Act
        await viewModel.changeLanguage(SettingsLanguage.zh_TW);

        // Assert
        expect(loadingStateObserved, true);
      });
    });

    group('主題設定', () {
      test('應該成功切換為深色主題', () async {
        // Arrange
        final viewModel = container.read(settingsViewModelProvider.notifier);

        // Act
        await viewModel.changeTheme(SettingsTheme.dark);

        // Assert
        final state = viewModel.state;
        expect(state.theme, SettingsTheme.dark);
        expect(state.error, isNull);
        
        verify(() => mockPrefs.setString('app_theme', 'dark')).called(1);
      });

      test('應該成功切換為淺色主題', () async {
        // Arrange
        final viewModel = container.read(settingsViewModelProvider.notifier);

        // Act
        await viewModel.changeTheme(SettingsTheme.light);

        // Assert
        final state = viewModel.state;
        expect(state.theme, SettingsTheme.light);
        
        verify(() => mockPrefs.setString('app_theme', 'light')).called(1);
      });

      test('應該成功切換為系統跟隨主題', () async {
        // Arrange
        final viewModel = container.read(settingsViewModelProvider.notifier);

        // Act
        await viewModel.changeTheme(SettingsTheme.system);

        // Assert
        final state = viewModel.state;
        expect(state.theme, SettingsTheme.system);
        
        verify(() => mockPrefs.setString('app_theme', 'system')).called(1);
      });

      test('主題切換失敗時應該顯示錯誤', () async {
        // Arrange
        when(() => mockPrefs.setString('app_theme', any()))
            .thenThrow(Exception('儲存失敗'));
        final viewModel = container.read(settingsViewModelProvider.notifier);

        // Act
        await viewModel.changeTheme(SettingsTheme.dark);

        // Assert
        final state = viewModel.state;
        expect(state.error, isNotNull);
        expect(state.error, contains('儲存主題設定失敗'));
      });
    });

    group('通知設定', () {
      test('應該成功開啟通知', () async {
        // Arrange
        final viewModel = container.read(settingsViewModelProvider.notifier);

        // Act
        await viewModel.toggleNotifications(true);

        // Assert
        final state = viewModel.state;
        expect(state.notificationsEnabled, true);
        expect(state.error, isNull);
        
        verify(() => mockPrefs.setBool('notifications_enabled', true)).called(1);
      });

      test('應該成功關閉通知', () async {
        // Arrange
        final viewModel = container.read(settingsViewModelProvider.notifier);

        // Act
        await viewModel.toggleNotifications(false);

        // Assert
        final state = viewModel.state;
        expect(state.notificationsEnabled, false);
        
        verify(() => mockPrefs.setBool('notifications_enabled', false)).called(1);
      });

      test('通知設定失敗時應該顯示錯誤', () async {
        // Arrange
        when(() => mockPrefs.setBool('notifications_enabled', any()))
            .thenThrow(Exception('儲存失敗'));
        final viewModel = container.read(settingsViewModelProvider.notifier);

        // Act
        await viewModel.toggleNotifications(true);

        // Assert
        final state = viewModel.state;
        expect(state.error, isNotNull);
        expect(state.error, contains('儲存通知設定失敗'));
      });
    });

    group('版本資訊', () {
      test('應該成功載入應用版本資訊', () async {
        // 此測試跳過，因為 PackageInfo 是插件，需要平台支持
      }, skip: true);

      test('載入版本資訊失敗時應該顯示錯誤', () async {
        // 此測試暫時跳過，因為 PackageInfo 是靜態方法，難以 Mock
        // 在實際專案中應該使用依賴注入模式來處理這種情況
      }, skip: true);

      test('載入版本資訊期間應該顯示載入狀態', () async {
        // Arrange
        final viewModel = container.read(settingsViewModelProvider.notifier);
        bool loadingStateObserved = false;
        
        container.listen(settingsViewModelProvider, (previous, next) {
          if (next.isLoading) {
            loadingStateObserved = true;
          }
        });

        // Act
        await viewModel.loadAppVersion();

        // Assert
        expect(loadingStateObserved, true);
      });
    });

    group('設定重置', () {
      test('應該成功重置所有設定到預設值', () async {
        // Arrange
        final viewModel = container.read(settingsViewModelProvider.notifier);

        // Act
        await viewModel.resetSettings();

        // Assert
        final state = viewModel.state;
        expect(state.language, SettingsLanguage.system);
        expect(state.theme, SettingsTheme.system);
        expect(state.notificationsEnabled, true);
        expect(state.error, isNull);

        // 驗證 SharedPreferences 被呼叫
        verify(() => mockPrefs.remove('app_language')).called(1);
        verify(() => mockPrefs.remove('app_theme')).called(1);
        verify(() => mockPrefs.remove('notifications_enabled')).called(1);
      });

      test('重置設定失敗時應該顯示錯誤', () async {
        // Arrange
        when(() => mockPrefs.remove(any()))
            .thenThrow(Exception('清除失敗'));
        final viewModel = container.read(settingsViewModelProvider.notifier);

        // Act
        await viewModel.resetSettings();

        // Assert
        final state = viewModel.state;
        expect(state.error, isNotNull);
        expect(state.error, contains('重置設定失敗'));
      });
    });

    group('錯誤處理', () {
      test('應該能清除錯誤狀態', () async {
        // Arrange
        when(() => mockPrefs.setString('app_language', any()))
            .thenThrow(Exception('測試錯誤'));
        final viewModel = container.read(settingsViewModelProvider.notifier);
        
        // 產生錯誤
        await viewModel.changeLanguage(SettingsLanguage.zh_TW);
        expect(viewModel.state.error, isNotNull);

        // Act
        viewModel.clearError();

        // Assert
        final state = viewModel.state;
        expect(state.error, isNull);
      });
    });

    group('邊界條件測試', () {
      test('應該處理空的 SharedPreferences 值', () {
        // Arrange
        when(() => mockPrefs.getString(any())).thenReturn('');
        when(() => mockPrefs.getBool(any())).thenReturn(null);

        // 重新建立 container
        container.dispose();
        container = ProviderContainer(
          overrides: [
            settingsViewModelProvider.overrideWith(
              (ref) => SettingsViewModel(
                preferences: mockPrefs,
                deviceInfo: mockDeviceInfo,
              ),
            ),
          ],
        );

        // Act & Assert
        final state = container.read(settingsViewModelProvider);

        // 應該使用預設值
        expect(state.language, SettingsLanguage.system);
        expect(state.theme, SettingsTheme.system);
        expect(state.notificationsEnabled, true);
      });

      test('應該處理無效的設定值', () {
        // Arrange
        when(() => mockPrefs.getString('app_language')).thenReturn('invalid_lang');
        when(() => mockPrefs.getString('app_theme')).thenReturn('invalid_theme');

        // 重新建立 container
        container.dispose();
        container = ProviderContainer(
          overrides: [
            settingsViewModelProvider.overrideWith(
              (ref) => SettingsViewModel(
                preferences: mockPrefs,
                deviceInfo: mockDeviceInfo,
              ),
            ),
          ],
        );

        // Act & Assert
        final state = container.read(settingsViewModelProvider);

        // 應該使用預設值
        expect(state.language, SettingsLanguage.system);
        expect(state.theme, SettingsTheme.system);
      });

      test('同時進行多個設定變更時應該正確處理', () async {
        // Arrange
        final viewModel = container.read(settingsViewModelProvider.notifier);

        // Act - 同時變更多個設定
        final futures = [
          viewModel.changeLanguage(SettingsLanguage.zh_TW),
          viewModel.changeTheme(SettingsTheme.dark),
          viewModel.toggleNotifications(false),
        ];
        
        await Future.wait(futures);

        // Assert
        final state = viewModel.state;
        expect(state.language, SettingsLanguage.zh_TW);
        expect(state.theme, SettingsTheme.dark);
        expect(state.notificationsEnabled, false);
        expect(state.error, isNull);
      });
    });

    group('狀態一致性', () {
      test('ViewModel 狀態應該與 SharedPreferences 保持一致', () async {
        // Arrange
        final viewModel = container.read(settingsViewModelProvider.notifier);

        // Act
        await viewModel.changeLanguage(SettingsLanguage.zh_TW);
        await viewModel.changeTheme(SettingsTheme.dark);
        await viewModel.toggleNotifications(false);

        // Assert - 檢查所有儲存呼叫是否正確
        verify(() => mockPrefs.setString('app_language', 'zh_TW')).called(1);
        verify(() => mockPrefs.setString('app_theme', 'dark')).called(1);
        verify(() => mockPrefs.setBool('notifications_enabled', false)).called(1);

        // 檢查狀態
        final state = viewModel.state;
        expect(state.language, SettingsLanguage.zh_TW);
        expect(state.theme, SettingsTheme.dark);
        expect(state.notificationsEnabled, false);
      });
    });
  });
}

