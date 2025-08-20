// Re-export repository providers from data layer
import 'package:busines_card_scanner_flutter/data/datasources/local/ml_kit_ocr_service.dart';
import 'package:busines_card_scanner_flutter/platform/ios/vision_service_bridge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:busines_card_scanner_flutter/data/providers/repository_providers.dart';

// =============================================================================
// Presentation Layer Providers
// =============================================================================
// 這個檔案專門處理 Presentation 層的 Providers
// Data 層的服務 Providers 已經移動到 data/providers/repository_providers.dart
// 以避免循環依賴並遵循 Clean Architecture 分層原則
// =============================================================================

/// Provider for MLKitOCRService instance (僅供特殊用途)
/// 一般情況下應該使用 ocrServiceProvider 來取得平台自動選擇的 OCR 服務
final mlKitOCRServiceProvider = Provider<MLKitOCRService>((ref) {
  return MLKitOCRService();
});

/// Provider for IOSVisionServiceBridge instance (僅供特殊用途)
/// 一般情況下應該使用 ocrServiceProvider 來取得平台自動選擇的 OCR 服務
final iosVisionServiceProvider = Provider<IOSVisionServiceBridge>((ref) {
  return IOSVisionServiceBridge();
});
