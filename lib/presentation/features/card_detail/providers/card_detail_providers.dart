import 'package:busines_card_scanner_flutter/core/services/validation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Card Detail 相關 Providers

/// ValidationService Provider（如果還沒有的話）
final validationServiceProvider = Provider<ValidationService>((ref) {
  return ValidationService();
});

/// Card Detail ViewModel Provider
/// 使用 riverpod_generator 自動生成的 provider
/// 定義在 card_detail_view_model.dart 中
