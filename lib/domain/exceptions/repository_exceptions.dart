import 'package:equatable/equatable.dart';

/// Domain層獨立的錯誤基底類別
/// 繼承 Exception 以符合 Dart 最佳實踐和靜態分析要求
abstract class DomainFailure extends Equatable implements Exception {
  const DomainFailure({
    required this.userMessage,
    required this.internalMessage,
  });

  /// 使用者友善的錯誤訊息
  final String userMessage;

  /// 內部錯誤訊息，用於日誌記錄
  final String internalMessage;

  @override
  String toString() {
    return '$runtimeType(userMessage: <hidden>, internalMessage: <hidden>)';
  }
}

/// Repository 相關的異常基底類別
abstract class RepositoryException extends DomainFailure {
  const RepositoryException({
    required super.userMessage,
    required super.internalMessage,
  });
}

// ========== Card Repository 異常 ==========

/// 名片未找到異常
class CardNotFoundException extends RepositoryException {
  final String cardId;

  const CardNotFoundException(this.cardId, {String? userMessage})
    : super(
        userMessage: userMessage ?? '找不到指定的名片',
        internalMessage: 'Card not found: $cardId',
      );

  @override
  List<Object?> get props => [cardId, userMessage, internalMessage];
}

/// 名片正在使用異常
class CardInUseFailure extends RepositoryException {
  final String cardId;
  final String operation;

  const CardInUseFailure(this.cardId, this.operation, {String? userMessage})
    : super(
        userMessage: userMessage ?? '名片正在被其他操作使用，請稍後再試',
        internalMessage: 'Card $cardId is in use by operation: $operation',
      );

  @override
  List<Object?> get props => [cardId, operation, userMessage, internalMessage];
}

/// 儲存空間不足異常
class StorageSpaceFailure extends RepositoryException {
  final int availableSpaceBytes;
  final int requiredSpaceBytes;

  const StorageSpaceFailure({
    required this.availableSpaceBytes,
    required this.requiredSpaceBytes,
    String? userMessage,
  }) : super(
         userMessage: userMessage ?? '儲存空間不足，無法儲存名片',
         internalMessage:
             'Insufficient storage space. Available: $availableSpaceBytes, Required: $requiredSpaceBytes',
       );

  @override
  List<Object?> get props => [
    availableSpaceBytes,
    requiredSpaceBytes,
    userMessage,
    internalMessage,
  ];
}

// ========== OCR Repository 異常 ==========

/// OCR 處理失敗異常
class OCRProcessingFailure extends RepositoryException {
  final String? engineId;

  const OCRProcessingFailure({
    this.engineId,
    String? userMessage,
    String? internalMessage,
  }) : super(
         userMessage: userMessage ?? '文字識別處理失敗',
         internalMessage:
             internalMessage ??
             'OCR processing failed${engineId != null ? ' with engine: $engineId' : ''}',
       );

  @override
  List<Object?> get props => [engineId, userMessage, internalMessage];
}

/// 不支援的圖片格式異常
class UnsupportedImageFormatFailure extends RepositoryException {
  final String? mimeType;

  const UnsupportedImageFormatFailure({this.mimeType, String? userMessage})
    : super(
        userMessage: userMessage ?? '不支援的圖片格式',
        internalMessage:
            'Unsupported image format${mimeType != null ? ': $mimeType' : ''}',
      );

  @override
  List<Object?> get props => [mimeType, userMessage, internalMessage];
}

/// 圖片尺寸過大異常
class ImageTooLargeFailure extends RepositoryException {
  final int imageSize;
  final int maxSize;

  const ImageTooLargeFailure({
    required this.imageSize,
    required this.maxSize,
    String? userMessage,
  }) : super(
         userMessage: userMessage ?? '圖片尺寸過大，請選擇較小的圖片',
         internalMessage:
             'Image size too large: $imageSize bytes, max allowed: $maxSize bytes',
       );

  @override
  List<Object?> get props => [imageSize, maxSize, userMessage, internalMessage];
}

/// OCR 服務無法使用異常
class OCRServiceUnavailableFailure extends RepositoryException {
  final String? reason;

  const OCRServiceUnavailableFailure({this.reason, String? userMessage})
    : super(
        userMessage: userMessage ?? 'OCR 服務暫時無法使用',
        internalMessage:
            'OCR service unavailable${reason != null ? ': $reason' : ''}',
      );

  @override
  List<Object?> get props => [reason, userMessage, internalMessage];
}

/// OCR 結果未找到異常
class OCRResultNotFoundException extends RepositoryException {
  final String resultId;

  const OCRResultNotFoundException(this.resultId, {String? userMessage})
    : super(
        userMessage: userMessage ?? '找不到指定的 OCR 結果',
        internalMessage: 'OCR result not found: $resultId',
      );

  @override
  List<Object?> get props => [resultId, userMessage, internalMessage];
}

// ========== AI Repository 異常 ==========

/// AI 服務無法使用異常
class AIServiceUnavailableFailure extends RepositoryException {
  final String? serviceId;
  final String? reason;

  const AIServiceUnavailableFailure({
    this.serviceId,
    this.reason,
    String? userMessage,
  }) : super(
         userMessage: userMessage ?? 'AI 服務暫時無法使用',
         internalMessage:
             'AI service unavailable${serviceId != null ? ' ($serviceId)' : ''}${reason != null ? ': $reason' : ''}',
       );

  @override
  List<Object?> get props => [serviceId, reason, userMessage, internalMessage];
}

/// 無效輸入異常
class InvalidInputFailure extends RepositoryException {
  final String field;
  final String? value;

  const InvalidInputFailure({
    required this.field,
    this.value,
    String? userMessage,
  }) : super(
         userMessage: userMessage ?? '輸入內容無效',
         internalMessage:
             'Invalid input for field: $field${value != null ? ', value: $value' : ''}',
       );

  @override
  List<Object?> get props => [field, value, userMessage, internalMessage];
}

/// AI 配額用盡異常
class AIQuotaExceededFailure extends RepositoryException {
  final DateTime resetTime;

  const AIQuotaExceededFailure({required this.resetTime, String? userMessage})
    : super(
        userMessage: userMessage ?? 'AI 服務使用量已達上限，請稍後再試',
        internalMessage: 'AI quota exceeded, resets at: $resetTime',
      );

  @override
  List<Object?> get props => [resetTime, userMessage, internalMessage];
}

/// AI 頻率限制異常
class AIRateLimitFailure extends RepositoryException {
  final Duration retryAfter;

  AIRateLimitFailure({required this.retryAfter, String? userMessage})
    : super(
        userMessage: userMessage ?? '請求過於頻繁，請稍後再試',
        internalMessage:
            'Rate limit exceeded, retry after: ${retryAfter.inSeconds} seconds',
      );

  @override
  List<Object?> get props => [retryAfter, userMessage, internalMessage];
}

// ========== 資料源相關異常 ==========

/// 資料來源失敗異常
class DataSourceFailure extends RepositoryException {
  final String? dataSource;
  final String? operation;

  const DataSourceFailure({
    this.dataSource,
    this.operation,
    String? userMessage,
    String? internalMessage,
  }) : super(
         userMessage: userMessage ?? '資料存取發生錯誤',
         internalMessage:
             internalMessage ??
             'Data source failure${dataSource != null ? ' in $dataSource' : ''}${operation != null ? ' during $operation' : ''}',
       );

  @override
  List<Object?> get props => [
    dataSource,
    operation,
    userMessage,
    internalMessage,
  ];
}

/// 資料庫連線失敗異常
class DatabaseConnectionFailure extends DataSourceFailure {
  const DatabaseConnectionFailure({
    String? userMessage,
    String? internalMessage,
  }) : super(
         dataSource: 'database',
         userMessage: userMessage ?? '資料庫連線失敗',
         internalMessage: internalMessage ?? 'Failed to connect to database',
       );

  @override
  List<Object?> get props => [
    dataSource,
    operation,
    userMessage,
    internalMessage,
  ];
}

/// 網路連線失敗異常
class NetworkConnectionFailure extends DataSourceFailure {
  final String? endpoint;

  const NetworkConnectionFailure({this.endpoint, String? userMessage})
    : super(
        dataSource: 'network',
        userMessage: userMessage ?? '網路連線失敗',
        internalMessage:
            'Network connection failed${endpoint != null ? ' to $endpoint' : ''}',
      );

  @override
  List<Object?> get props => [
    endpoint,
    dataSource,
    operation,
    userMessage,
    internalMessage,
  ];
}

/// 檔案系統異常
class FileSystemFailure extends DataSourceFailure {
  final String? filePath;

  const FileSystemFailure({this.filePath, super.operation, String? userMessage})
    : super(
        dataSource: 'filesystem',
        userMessage: userMessage ?? '檔案操作失敗',
        internalMessage:
            'File system operation failed${filePath != null ? ' for file: $filePath' : ''}',
      );

  @override
  List<Object?> get props => [
    filePath,
    dataSource,
    operation,
    userMessage,
    internalMessage,
  ];
}

// ========== 權限相關異常 ==========

/// 權限不足異常
class InsufficientPermissionFailure extends RepositoryException {
  final String permission;
  final String operation;

  const InsufficientPermissionFailure({
    required this.permission,
    required this.operation,
    String? userMessage,
  }) : super(
         userMessage: userMessage ?? '沒有執行此操作的權限',
         internalMessage:
             'Insufficient permission: $permission for operation: $operation',
       );

  @override
  List<Object?> get props => [
    permission,
    operation,
    userMessage,
    internalMessage,
  ];
}

// ========== 驗證相關異常 ==========

/// Domain層輸入驗證錯誤
class DomainValidationFailure extends RepositoryException {
  const DomainValidationFailure({
    required super.userMessage,
    required super.internalMessage,
    this.field,
  });

  /// 驗證失敗的欄位名稱
  final String? field;

  @override
  List<Object?> get props => [userMessage, internalMessage, field];
}

/// 資料驗證失敗異常
class DataValidationFailure extends RepositoryException {
  final Map<String, List<String>> validationErrors;

  const DataValidationFailure({
    required this.validationErrors,
    String? userMessage,
  }) : super(
         userMessage: userMessage ?? '資料驗證失敗',
         internalMessage: 'Data validation failed: $validationErrors',
       );

  @override
  List<Object?> get props => [validationErrors, userMessage, internalMessage];

  /// 取得第一個驗證錯誤訊息
  String get firstError {
    if (validationErrors.isEmpty) {
      return '';
    }
    final firstEntry = validationErrors.entries.first;
    if (firstEntry.value.isEmpty) {
      return '';
    }
    return '${firstEntry.key}: ${firstEntry.value.first}';
  }

  /// 取得所有驗證錯誤訊息
  List<String> get allErrors {
    final errors = <String>[];
    for (final entry in validationErrors.entries) {
      for (final error in entry.value) {
        errors.add('${entry.key}: $error');
      }
    }
    return errors;
  }
}

// ========== 並發控制異常 ==========

/// 資料衝突異常（樂觀鎖）
class DataConflictFailure extends RepositoryException {
  final String resourceId;
  final String resourceType;

  const DataConflictFailure({
    required this.resourceId,
    required this.resourceType,
    String? userMessage,
  }) : super(
         userMessage: userMessage ?? '資料已被其他用戶修改，請重新載入後再試',
         internalMessage: 'Data conflict for $resourceType: $resourceId',
       );

  @override
  List<Object?> get props => [
    resourceId,
    resourceType,
    userMessage,
    internalMessage,
  ];
}

/// 資源鎖定異常
class ResourceLockFailure extends RepositoryException {
  final String resourceId;
  final Duration lockDuration;

  ResourceLockFailure({
    required this.resourceId,
    required this.lockDuration,
    String? userMessage,
  }) : super(
         userMessage: userMessage ?? '資源正在被使用中，請稍後再試',
         internalMessage:
             'Resource locked: $resourceId, duration: ${lockDuration.inSeconds}s',
       );

  @override
  List<Object?> get props => [
    resourceId,
    lockDuration,
    userMessage,
    internalMessage,
  ];
}
