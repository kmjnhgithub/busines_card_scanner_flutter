import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:dartz/dartz.dart';

/// 驗證 AI 服務的業務用例
///
/// 負責檢查 AI 服務的可用性、狀態和使用統計
/// 遵循 Clean Architecture 和 Single Responsibility Principle
abstract class ValidateAIServiceUseCase {
  /// 取得 AI 服務狀態
  Future<Either<DomainFailure, AIServiceStatus>> getServiceStatus();

  /// 取得使用統計
  Future<Either<DomainFailure, AIUsageStatistics>> getUsageStatistics();

  /// 取得可用的 AI 模型列表
  Future<Either<DomainFailure, List<AIModelInfo>>> getAvailableModels();

  /// 取得當前使用的 AI 模型
  Future<Either<DomainFailure, AIModelInfo>> getCurrentModel();
}

/// ValidateAIServiceUseCase 的實作
class ValidateAIServiceUseCaseImpl implements ValidateAIServiceUseCase {
  final AIRepository _repository;

  const ValidateAIServiceUseCaseImpl({required AIRepository repository})
    : _repository = repository;

  @override
  Future<Either<DomainFailure, AIServiceStatus>> getServiceStatus() async {
    try {
      final status = await _repository.getServiceStatus();
      return Right(status);
    } on Exception catch (e) {
      return Left(
        DataSourceFailure(
          userMessage: '取得 AI 服務狀態失敗',
          internalMessage: 'Exception during service status retrieval: $e',
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, AIUsageStatistics>> getUsageStatistics() async {
    try {
      final stats = await _repository.getUsageStatistics();
      return Right(stats);
    } on Exception catch (e) {
      return Left(
        DataSourceFailure(
          userMessage: '取得使用統計失敗',
          internalMessage: 'Exception during usage statistics retrieval: $e',
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, List<AIModelInfo>>> getAvailableModels() async {
    try {
      final models = await _repository.getAvailableModels();
      return Right(models);
    } on Exception catch (e) {
      return Left(
        DataSourceFailure(
          userMessage: '取得可用模型列表失敗',
          internalMessage: 'Exception during available models retrieval: $e',
        ),
      );
    }
  }

  @override
  Future<Either<DomainFailure, AIModelInfo>> getCurrentModel() async {
    try {
      final model = await _repository.getCurrentModel();
      return Right(model);
    } on Exception catch (e) {
      return Left(
        DataSourceFailure(
          userMessage: '取得當前模型失敗',
          internalMessage: 'Exception during current model retrieval: $e',
        ),
      );
    }
  }
}
