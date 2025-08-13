import 'package:busines_card_scanner_flutter/data/datasources/local/clean_app_database.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/ocr_cache_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/secure/enhanced_secure_storage.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/simple_ocr_cache_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/ocr_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/openai_service.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/simple_ocr_service.dart';
import 'package:busines_card_scanner_flutter/data/repositories/ai_repository_impl.dart';
import 'package:busines_card_scanner_flutter/data/repositories/card_repository_impl.dart';
import 'package:busines_card_scanner_flutter/data/repositories/ocr_repository_impl.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_repository.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// Data Sources Providers
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
  return OpenAIServiceImpl(
    dio: dio,
    secureStorage: secureStorage,
  );
});

/// Provider for OCRService instance
/// Provides OCR text recognition functionality using Simple OCR Service
final ocrServiceProvider = Provider<OCRService>((ref) {
  return SimpleOCRService();
});

/// Provider for OCRCacheService instance  
/// Provides OCR result caching and history management
final ocrCacheServiceProvider = Provider<OCRCacheService>((ref) {
  return SimpleOCRCacheService();
});

// =============================================================================
// Repository Providers (Data Layer Implementations)
// =============================================================================

/// Provider for CardRepository implementation
/// Connects Domain layer with Data layer for card operations
final cardRepositoryProvider = Provider<CardRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return CardRepositoryImpl(database);
});

/// Provider for OCRRepository implementation  
/// Connects Domain layer with Data layer for OCR operations
final ocrRepositoryProvider = Provider<OCRRepository>((ref) {
  final ocrService = ref.watch(ocrServiceProvider);
  final cacheService = ref.watch(ocrCacheServiceProvider);
  return OCRRepositoryImpl(
    ocrService: ocrService,
    cacheService: cacheService,
  );
});

/// Provider for AIRepository implementation
/// Connects Domain layer with Data layer for AI operations  
final aiRepositoryProvider = Provider<AIRepository>((ref) {
  final openAIService = ref.watch(openAIServiceProvider);
  return AIRepositoryImpl(
    openAIService: openAIService,
  );
});