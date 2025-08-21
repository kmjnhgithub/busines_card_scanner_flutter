import 'package:busines_card_scanner_flutter/domain/exceptions/repository_exceptions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

/// API Key 管理 Repository 介面
///
/// 負責安全地管理各種服務的 API Key
/// 遵循 Interface Segregation Principle，專注於 API Key 管理功能
///
/// 安全性設計考量：
/// - **加密儲存**：所有 API Key 都經過加密處理
/// - **輸入驗證**：驗證 API Key 格式和服務名稱有效性
/// - **錯誤處理**：不洩露敏感資訊到錯誤訊息中
/// - **存取控制**：確保只有授權操作可以存取 API Key
abstract class ApiKeyRepository {
  /// 儲存 API Key
  ///
  /// [service] 服務名稱（例如：'openai', 'anthropic'）
  /// [apiKey] 要儲存的 API Key
  ///
  /// Returns: Right(void) 成功，Left(DomainFailure) 失敗
  ///
  /// Throws:
  /// - [DomainValidationFailure] 當輸入格式無效
  /// - [InsufficientPermissionFailure] 當沒有儲存權限
  /// - [DataSourceFailure] 當儲存操作失敗
  Future<Either<DomainFailure, void>> storeApiKey(
    String service,
    String apiKey,
  );

  /// 取得 API Key
  ///
  /// [service] 服務名稱
  ///
  /// Returns: Right(String) API Key，Left(DomainFailure) 失敗或不存在
  ///
  /// Throws:
  /// - [DomainValidationFailure] 當服務名稱無效
  /// - [DataSourceFailure] 當 API Key 不存在或讀取失敗
  /// - [InsufficientPermissionFailure] 當沒有讀取權限
  Future<Either<DomainFailure, String>> getApiKey(String service);

  /// 刪除 API Key
  ///
  /// [service] 服務名稱
  ///
  /// Returns: Right(void) 成功，Left(DomainFailure) 失敗
  ///
  /// Throws:
  /// - [DomainValidationFailure] 當服務名稱無效
  /// - [DataSourceFailure] 當刪除操作失敗
  /// - [InsufficientPermissionFailure] 當沒有刪除權限
  Future<Either<DomainFailure, void>> deleteApiKey(String service);

  /// 檢查 API Key 是否存在
  ///
  /// [service] 服務名稱
  ///
  /// Returns: Right(bool) 是否存在，Left(DomainFailure) 檢查失敗
  ///
  /// 注意：此方法不會返回 API Key 本身，只檢查存在性
  Future<Either<DomainFailure, bool>> hasApiKey(String service);

  /// 取得所有已儲存的 API Key 服務列表
  ///
  /// Returns: Right(List&lt;String&gt;) 服務名稱列表，Left(DomainFailure) 失敗
  ///
  /// 注意：只返回服務名稱，不包含 API Key 內容
  Future<Either<DomainFailure, List<String>>> getStoredServices();

  /// 清除所有 API Key
  ///
  /// Returns: Right(void) 成功，Left(DomainFailure) 失敗
  ///
  /// 危險操作：會永久刪除所有儲存的 API Key
  /// 建議在執行前確認使用者意圖
  Future<Either<DomainFailure, void>> clearAllApiKeys();

  /// 驗證 API Key 格式
  ///
  /// [service] 服務名稱
  /// [apiKey] 要驗證的 API Key
  ///
  /// Returns: Right(bool) 格式是否有效，Left(DomainFailure) 驗證失敗
  ///
  /// 只進行格式驗證，不進行網路請求驗證
  Future<Either<DomainFailure, bool>> validateApiKeyFormat(
    String service,
    String apiKey,
  );

  /// 取得 API Key 安全摘要
  ///
  /// [service] 服務名稱
  ///
  /// Returns: Right(ApiKeySummary) 安全摘要，Left(DomainFailure) 失敗
  ///
  /// 返回不含敏感資訊的 API Key 摘要（如前幾個字符和長度）
  Future<Either<DomainFailure, ApiKeySummary>> getApiKeySummary(String service);
}

/// API Key 安全摘要
///
/// 提供 API Key 的基本資訊，不包含敏感內容
@immutable
class ApiKeySummary {
  /// 服務名稱
  final String service;

  /// API Key 前綴（通常是前幾個字符）
  final String prefix;

  /// API Key 長度
  final int length;

  /// 儲存時間
  final DateTime storedAt;

  /// 最後存取時間
  final DateTime? lastAccessedAt;

  /// 是否有效（格式檢查）
  final bool isValidFormat;

  const ApiKeySummary({
    required this.service,
    required this.prefix,
    required this.length,
    required this.storedAt,
    required this.isValidFormat,
    this.lastAccessedAt,
  });

  @override
  String toString() {
    return 'ApiKeySummary(service: $service, prefix: $prefix***, length: $length)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ApiKeySummary &&
        other.service == service &&
        other.prefix == prefix &&
        other.length == length &&
        other.storedAt == storedAt &&
        other.lastAccessedAt == lastAccessedAt &&
        other.isValidFormat == isValidFormat;
  }

  @override
  int get hashCode {
    return Object.hash(
      service,
      prefix,
      length,
      storedAt,
      lastAccessedAt,
      isValidFormat,
    );
  }
}
