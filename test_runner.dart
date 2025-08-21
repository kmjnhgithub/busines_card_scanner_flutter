import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'lib/data/datasources/local/secure/enhanced_secure_storage.dart';
import 'lib/data/datasources/remote/openai_service.dart';
import 'lib/presentation/features/settings/pages/ai_settings_page.dart';
import 'lib/presentation/features/settings/providers/settings_providers.dart';
import 'lib/presentation/features/settings/view_models/ai_settings_view_model.dart';

/// Mock 類別
class MockEnhancedSecureStorage extends Mock implements EnhancedSecureStorage {}
class MockOpenAIService extends Mock implements OpenAIService {}

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mockStorage = MockEnhancedSecureStorage();
    final mockOpenAIService = MockOpenAIService();
    
    final viewModel = AISettingsViewModel(
      secureStorage: mockStorage,
      openAIService: mockOpenAIService,
    );

    return ProviderScope(
      overrides: [
        aiSettingsViewModelProvider.overrideWith((ref) => viewModel),
      ],
      child: MaterialApp(
        title: 'AI Settings Test',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const AISettingsPage(),
      ),
    );
  }
}