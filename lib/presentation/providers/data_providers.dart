// Re-export repository providers from data layer
import 'package:busines_card_scanner_flutter/data/datasources/local/ml_kit_ocr_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/ocr_cache_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/platform_ocr_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/simple_ocr_cache_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/ocr_service.dart';
import 'package:busines_card_scanner_flutter/platform/ios/vision_service_bridge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:busines_card_scanner_flutter/data/providers/repository_providers.dart';

// =============================================================================
// Service Layer Providers (Non-Repository Services)
// =============================================================================

/// Provider for MLKitOCRService instance
/// Provides Google ML Kit OCR functionality
final mlKitOCRServiceProvider = Provider<MLKitOCRService>((ref) {
  return MLKitOCRService();
});

/// Provider for IOSVisionServiceBridge instance
/// Provides iOS Vision Framework OCR functionality
final iosVisionServiceProvider = Provider<IOSVisionServiceBridge>((ref) {
  return IOSVisionServiceBridge();
});

/// Provider for PlatformOCRService instance
/// Provides platform-specific OCR functionality (iOS Vision / Android ML Kit)
final platformOCRServiceProvider = Provider<PlatformOCRService>((ref) {
  return PlatformOCRService();
});

/// Provider for OCRService instance
/// Provides OCR text recognition functionality using Platform-specific service
final ocrServiceProvider = Provider<OCRService>((ref) {
  return ref.watch(platformOCRServiceProvider);
});

/// Provider for OCRCacheService instance
/// Provides OCR result caching and history management
final ocrCacheServiceProvider = Provider<OCRCacheService>((ref) {
  return SimpleOCRCacheService();
});
