import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/api_key_repository.dart';
import 'package:dartz/dartz.dart';

/// 管理 API Key 的業務用例
///
/// 封裝所有與 API Key 管理相關的業務邏輯
/// 遵循 Clean Architecture 和 Single Responsibility Principle
abstract class ManageApiKeyUseCase {
  /// 儲存 API Key
  Future<Either<DomainFailure, void>> storeApiKey(
    String service,
    String apiKey,
  );

  /// 取得 API Key
  Future<Either<DomainFailure, String>> getApiKey(String service);

  /// 刪除 API Key
  Future<Either<DomainFailure, void>> deleteApiKey(String service);

  /// 檢查 API Key 是否存在
  Future<Either<DomainFailure, bool>> hasApiKey(String service);

  /// 驗證 API Key 格式
  Future<Either<DomainFailure, bool>> validateApiKeyFormat(
    String service,
    String apiKey,
  );

  /// 取得 API Key 安全摘要
  Future<Either<DomainFailure, ApiKeySummary>> getApiKeySummary(String service);
}

/// ManageApiKeyUseCase 的實作
class ManageApiKeyUseCaseImpl implements ManageApiKeyUseCase {
  final ApiKeyRepository _repository;

  const ManageApiKeyUseCaseImpl({required ApiKeyRepository repository})
    : _repository = repository;

  @override
  Future<Either<DomainFailure, void>> storeApiKey(
    String service,
    String apiKey,
  ) async {
    // 先驗證格式
    final formatResult = await _repository.validateApiKeyFormat(
      service,
      apiKey,
    );
    return formatResult.fold(Left.new, (isValid) {
      if (!isValid) {
        return const Left(
          DomainValidationFailure(
            userMessage: '無效的 API Key 格式',
            internalMessage: 'API key format validation failed',
            field: 'apiKey',
          ),
        );
      }
      // 格式有效，進行儲存
      return _repository.storeApiKey(service, apiKey);
    });
  }

  @override
  Future<Either<DomainFailure, String>> getApiKey(String service) {
    return _repository.getApiKey(service);
  }

  @override
  Future<Either<DomainFailure, void>> deleteApiKey(String service) {
    return _repository.deleteApiKey(service);
  }

  @override
  Future<Either<DomainFailure, bool>> hasApiKey(String service) {
    return _repository.hasApiKey(service);
  }

  @override
  Future<Either<DomainFailure, bool>> validateApiKeyFormat(
    String service,
    String apiKey,
  ) {
    return _repository.validateApiKeyFormat(service, apiKey);
  }

  @override
  Future<Either<DomainFailure, ApiKeySummary>> getApiKeySummary(
    String service,
  ) {
    return _repository.getApiKeySummary(service);
  }
}
