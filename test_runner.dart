import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'lib/domain/usecases/ai/manage_api_key_usecase.dart';
import 'lib/domain/usecases/ai/validate_ai_service_usecase.dart';
import 'lib/presentation/features/settings/pages/ai_settings_page.dart';
import 'lib/presentation/features/settings/providers/settings_providers.dart';
import 'lib/presentation/features/settings/view_models/ai_settings_view_model.dart';

/// Mock 類別
class MockManageApiKeyUseCase extends Mock implements ManageApiKeyUseCase {}
class MockValidateAIServiceUseCase extends Mock implements ValidateAIServiceUseCase {}

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mockManageApiKeyUseCase = MockManageApiKeyUseCase();
    final mockValidateAIServiceUseCase = MockValidateAIServiceUseCase();
    
    final viewModel = AISettingsViewModel(
      manageApiKeyUseCase: mockManageApiKeyUseCase,
      validateAIServiceUseCase: mockValidateAIServiceUseCase,
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