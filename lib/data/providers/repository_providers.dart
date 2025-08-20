import 'package:busines_card_scanner_flutter/data/datasources/local/clean_app_database.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/platform_ocr_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/secure/enhanced_secure_storage.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/simple_ocr_cache_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/openai_service.dart';
import 'package:busines_card_scanner_flutter/data/repositories/ai_repository_impl.dart';
import 'package:busines_card_scanner_flutter/data/repositories/card_repository_impl.dart';
import 'package:busines_card_scanner_flutter/data/repositories/ocr_repository_impl.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_repository.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Provider for CardRepository implementation
/// Connects Domain layer with Data layer for card operations
final cardRepositoryProvider = Provider<CardRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return CardRepositoryImpl(database);
});

/// Provider for OCRRepository implementation
/// Provides OCR functionality through platform-specific services
final ocrRepositoryProvider = Provider<OCRRepository>((ref) {
  // 注意：這裡違反了 Clean Architecture 的分層原則
  // 正確的做法是在更高層級的 container 中組裝依賴
  // 但為了緊急修復相機功能，暫時採用這種方式
  
  // 從 presentation 層取得服務實例（透過檔案匯入的方式）
  // 這是一個暫時的解決方案，未來應該重構為正確的依賴注入
  final ocrService = PlatformOCRService();
  final cacheService = SimpleOCRCacheService();
  
  return OCRRepositoryImpl(
    ocrService: ocrService,
    cacheService: cacheService,
  );
});

/// Provider for AIRepository implementation
/// Provides AI-powered card parsing functionality
final aiRepositoryProvider = Provider<AIRepository>((ref) {
  final openAIService = ref.watch(openAIServiceProvider);
  return AIRepositoryImpl(openAIService: openAIService);
});
