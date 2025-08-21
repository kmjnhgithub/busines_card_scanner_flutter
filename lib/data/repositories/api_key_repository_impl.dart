import 'package:busines_card_scanner_flutter/data/datasources/local/secure/enhanced_secure_storage.dart';
import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/api_key_repository.dart';
import 'package:dartz/dartz.dart';

/// ApiKeyRepository 的實作
///
/// 使用 EnhancedSecureStorage 進行安全的 API Key 管理
/// 遵循 Clean Architecture 原則，實作 Domain 層定義的介面
class ApiKeyRepositoryImpl implements ApiKeyRepository {
  final EnhancedSecureStorage _secureStorage;

  const ApiKeyRepositoryImpl({required EnhancedSecureStorage secureStorage})
    : _secureStorage = secureStorage;

  @override
  Future<Either<DomainFailure, void>> storeApiKey(
    String service,
    String apiKey,
  ) async {
    try {
      if (service.isEmpty || apiKey.isEmpty) {
        return Left(
          DomainValidationFailure(
            userMessage: '服務名稱和 API Key 不能為空',
            internalMessage: 'Empty service or apiKey validation failed',
            field: service.isEmpty ? 'service' : 'apiKey',
          ),
        );
      }

      final result = await _secureStorage.storeApiKey(service, apiKey);
      return result.fold(
        (failure) => Left(
          DomainValidationFailure(
            userMessage: '儲存 API Key 失敗',
            internalMessage:
                'Failed to store API key: ${failure.internalMessage}',
          ),
        ),
        (_) => const Right(null),
      );
    } on Exception catch (e) {
      return Left(
        DomainValidationFailure(
          userMessage: '儲存 API Key 時發生錯誤',
          internalMessage: 'Exception during API key storage: $e',
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, String>> getApiKey(String service) async {
    try {
      if (service.isEmpty) {
        return const Left(
          DomainValidationFailure(
            userMessage: '服務名稱不能為空',
            internalMessage: 'Empty service name',
            field: 'service',
          ),
        );
      }

      final result = await _secureStorage.getApiKey(service);
      return result.fold(
        (failure) => Left(
          DomainValidationFailure(
            userMessage: '取得 API Key 失敗',
            internalMessage:
                'Failed to get API key: ${failure.internalMessage}',
          ),
        ),
        Right.new,
      );
    } on Exception catch (e) {
      return Left(
        DomainValidationFailure(
          userMessage: '取得 API Key 時發生錯誤',
          internalMessage: 'Exception during API key retrieval: $e',
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, void>> deleteApiKey(String service) async {
    try {
      if (service.isEmpty) {
        return const Left(
          DomainValidationFailure(
            userMessage: '服務名稱不能為空',
            internalMessage: 'Empty service name',
            field: 'service',
          ),
        );
      }

      final result = await _secureStorage.deleteApiKey(service);
      return result.fold(
        (failure) => Left(
          DomainValidationFailure(
            userMessage: '刪除 API Key 失敗',
            internalMessage:
                'Failed to delete API key: ${failure.internalMessage}',
          ),
        ),
        (_) => const Right(null),
      );
    } on Exception catch (e) {
      return Left(
        DomainValidationFailure(
          userMessage: '刪除 API Key 時發生錯誤',
          internalMessage: 'Exception during API key deletion: $e',
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, bool>> hasApiKey(String service) async {
    try {
      if (service.isEmpty) {
        return const Left(
          DomainValidationFailure(
            userMessage: '服務名稱不能為空',
            internalMessage: 'Empty service name',
            field: 'service',
          ),
        );
      }

      final result = await _secureStorage.hasApiKey(service);
      return result.fold(
        (failure) => Left(
          DomainValidationFailure(
            userMessage: '檢查 API Key 失敗',
            internalMessage:
                'Failed to check API key: ${failure.internalMessage}',
          ),
        ),
        Right.new,
      );
    } on Exception catch (e) {
      return Left(
        DomainValidationFailure(
          userMessage: '檢查 API Key 時發生錯誤',
          internalMessage: 'Exception during API key check: $e',
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, List<String>>> getStoredServices() async {
    try {
      final result = await _secureStorage.getStoredServices();
      return result.fold(
        (failure) => Left(
          DomainValidationFailure(
            userMessage: '取得服務列表失敗',
            internalMessage:
                'Failed to get services: ${failure.internalMessage}',
          ),
        ),
        Right.new,
      );
    } on Exception catch (e) {
      return Left(
        DomainValidationFailure(
          userMessage: '取得服務列表時發生錯誤',
          internalMessage: 'Exception during service list retrieval: $e',
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, void>> clearAllApiKeys() async {
    try {
      final result = await _secureStorage.clearAllApiKeys();
      return result.fold(
        (failure) => Left(
          DomainValidationFailure(
            userMessage: '清除所有 API Key 失敗',
            internalMessage:
                'Failed to clear API keys: ${failure.internalMessage}',
          ),
        ),
        (_) => const Right(null),
      );
    } on Exception catch (e) {
      return Left(
        DomainValidationFailure(
          userMessage: '清除 API Key 時發生錯誤',
          internalMessage: 'Exception during API key clearing: $e',
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, bool>> validateApiKeyFormat(
    String service,
    String apiKey,
  ) async {
    try {
      if (service.isEmpty || apiKey.isEmpty) {
        return Left(
          DomainValidationFailure(
            userMessage: '服務名稱和 API Key 不能為空',
            internalMessage: 'Empty service or apiKey for validation',
            field: service.isEmpty ? 'service' : 'apiKey',
          ),
        );
      }

      bool isValid = false;
      switch (service.toLowerCase()) {
        case 'openai':
          isValid = _validateOpenAIKeyFormat(apiKey);
          break;
        case 'anthropic':
          isValid = _validateAnthropicKeyFormat(apiKey);
          break;
        default:
          isValid =
              apiKey.length >= 8 &&
              RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(apiKey);
      }

      return Right(isValid);
    } on Exception catch (e) {
      return Left(
        DomainValidationFailure(
          userMessage: '驗證 API Key 格式時發生錯誤',
          internalMessage: 'Exception during API key validation: $e',
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, ApiKeySummary>> getApiKeySummary(
    String service,
  ) async {
    try {
      if (service.isEmpty) {
        return const Left(
          DomainValidationFailure(
            userMessage: '服務名稱不能為空',
            internalMessage: 'Empty service name for summary',
            field: 'service',
          ),
        );
      }

      final apiKeyResult = await getApiKey(service);
      return apiKeyResult.fold(Left.new, (apiKey) {
        final summary = ApiKeySummary(
          service: service,
          prefix: apiKey.length >= 4 ? apiKey.substring(0, 4) : apiKey,
          length: apiKey.length,
          storedAt: DateTime.now(),
          isValidFormat: _isValidFormat(service, apiKey),
        );
        return Right(summary);
      });
    } on Exception catch (e) {
      return Left(
        DomainValidationFailure(
          userMessage: '取得 API Key 摘要時發生錯誤',
          internalMessage: 'Exception during API key summary: $e',
        ),
      );
    }
  }

  /// 驗證 OpenAI API Key 格式
  bool _validateOpenAIKeyFormat(String apiKey) {
    return RegExp(r'^sk-[a-zA-Z0-9]{48}$').hasMatch(apiKey);
  }

  /// 驗證 Anthropic API Key 格式
  bool _validateAnthropicKeyFormat(String apiKey) {
    return RegExp(r'^sk-ant-[a-zA-Z0-9\-_]+$').hasMatch(apiKey);
  }

  /// 檢查格式是否有效
  bool _isValidFormat(String service, String apiKey) {
    switch (service.toLowerCase()) {
      case 'openai':
        return _validateOpenAIKeyFormat(apiKey);
      case 'anthropic':
        return _validateAnthropicKeyFormat(apiKey);
      default:
        return apiKey.length >= 8 &&
            RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(apiKey);
    }
  }
}
