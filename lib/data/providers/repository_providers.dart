import 'package:busines_card_scanner_flutter/data/datasources/local/clean_app_database.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/ocr_cache_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/platform_ocr_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/secure/enhanced_secure_storage.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/simple_ocr_cache_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/ocr_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/openai_service.dart';
import 'package:busines_card_scanner_flutter/data/repositories/ai_repository_impl.dart';
import 'package:busines_card_scanner_flutter/data/repositories/api_key_repository_impl.dart';
import 'package:busines_card_scanner_flutter/data/repositories/card_repository_impl.dart';
import 'package:busines_card_scanner_flutter/data/repositories/ocr_repository_impl.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/api_key_repository.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_repository.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// Service Providers - 符合 Clean Architecture 的依賴組裝層
// =============================================================================
// 這些 Providers 在 Data 層定義服務實例，避免循環依賴問題
// Repository Providers 可以直接引用這些服務，實現依賴反轉
// =============================================================================

/// Provider for platform-specific OCR service
/// 根據平台自動選擇最佳的 OCR 引擎（iOS Vision / Android ML Kit）
final ocrServiceProvider = Provider<OCRService>((ref) {
  return PlatformOCRService();
});

/// Provider for OCR cache service
/// 提供 OCR 結果快取和歷史記錄管理
final ocrCacheServiceProvider = Provider<OCRCacheService>((ref) {
  return SimpleOCRCacheService();
});

// =============================================================================
// Data Layer Repository Providers
// =============================================================================

/// Provider for CleanAppDatabase instance
/// Provides singleton access to the local Drift database
final appDatabaseProvider = Provider<CleanAppDatabase>((ref) {
  return CleanAppDatabase.defaultInstance();
});

/// Provider for EnhancedSecureStorage instance
/// Provides secure storage for API keys and sensitive data
final enhancedSecureStorageProvider = Provider<EnhancedSecureStorage>((ref) {
  return EnhancedSecureStorage.defaultInstance();
});

/// Provider for Dio HTTP client
/// Provides HTTP client for API calls
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  return dio;
});

/// Provider for OpenAIService instance
/// Provides AI card parsing functionality
final openAIServiceProvider = Provider<OpenAIService>((ref) {
  final secureStorage = ref.watch(enhancedSecureStorageProvider);
  final dio = ref.watch(dioProvider);
  return OpenAIServiceImpl(dio: dio, secureStorage: secureStorage);
});

/// Provider for ApiKeyRepository implementation
/// Provides secure API key management functionality
final apiKeyRepositoryProvider = Provider<ApiKeyRepository>((ref) {
  final secureStorage = ref.watch(enhancedSecureStorageProvider);
  return ApiKeyRepositoryImpl(secureStorage: secureStorage);
});

/// Provider for CardRepository implementation
/// Connects Domain layer with Data layer for card operations
final cardRepositoryProvider = Provider<CardRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return CardRepositoryImpl(database);
});

/// Provider for OCRRepository implementation
/// Provides OCR functionality through platform-specific services
///
/// 此 Provider 遵循 Clean Architecture 原則：
/// - 依賴抽象介面而非具體實作
/// - 透過依賴注入取得服務實例
/// - Data 層不負責依賴組裝，只專注於資料存取邏輯
final ocrRepositoryProvider = Provider<OCRRepository>((ref) {
  // 透過 ref.watch 從外層取得服務實例
  // 這符合依賴反轉原則：高層模組不依賴低層模組，都依賴抽象
  final ocrService = ref.watch(ocrServiceProvider);
  final cacheService = ref.watch(ocrCacheServiceProvider);

  return OCRRepositoryImpl(ocrService: ocrService, cacheService: cacheService);
});

/// Provider for AIRepository implementation
/// Provides AI-powered card parsing functionality
final aiRepositoryProvider = Provider<AIRepository>((ref) {
  final openAIService = ref.watch(openAIServiceProvider);
  return AIRepositoryImpl(openAIService: openAIService);
});
