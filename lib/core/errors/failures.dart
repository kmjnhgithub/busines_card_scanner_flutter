import 'package:equatable/equatable.dart';

/// 抽象基類別，定義所有錯誤的基本結構
abstract class Failure extends Equatable {
  const Failure({required this.userMessage, required this.internalMessage});

  /// 使用者友善的錯誤訊息，不包含敏感資訊
  final String userMessage;

  /// 內部錯誤訊息，用於日誌記錄和偵錯
  final String internalMessage;

  @override
  String toString() {
    return '$runtimeType(userMessage: <hidden>, internalMessage: <hidden>)';
  }
}

/// 網路連線錯誤
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.userMessage,
    required super.internalMessage,
    this.statusCode,
  });

  /// HTTP 狀態碼
  final int? statusCode;

  /// 建立常見的網路連線失敗錯誤
  factory NetworkFailure.connectionTimeout() {
    return const NetworkFailure(
      userMessage: '網路連線逾時，請檢查網路連線後重試',
      internalMessage: 'Network connection timeout occurred',
      statusCode: 408,
    );
  }

  /// 建立常見的無網路連線錯誤
  factory NetworkFailure.noConnection() {
    return const NetworkFailure(
      userMessage: '無法連線至網路，請檢查網路設定',
      internalMessage: 'No internet connection available',
    );
  }

  @override
  List<Object?> get props => [userMessage, internalMessage, statusCode];

  @override
  String toString() {
    return 'NetworkFailure(statusCode: $statusCode)';
  }
}

/// 伺服器錯誤
class ServerFailure extends Failure {
  const ServerFailure({
    required super.userMessage,
    required super.internalMessage,
    this.statusCode,
  });

  /// HTTP 狀態碼
  final int? statusCode;

  @override
  List<Object?> get props => [userMessage, internalMessage, statusCode];

  @override
  String toString() {
    return 'ServerFailure(statusCode: $statusCode)';
  }
}

/// 輸入驗證錯誤
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.userMessage,
    required super.internalMessage,
    this.field,
  });

  /// 驗證失敗的欄位名稱
  final String? field;

  /// 建立電子信箱格式錯誤
  factory ValidationFailure.invalidEmail(String email) {
    return ValidationFailure(
      userMessage: '請輸入有效的電子信箱格式',
      internalMessage: 'Invalid email format: $email',
      field: 'email',
    );
  }

  /// 建立電話號碼格式錯誤
  factory ValidationFailure.invalidPhone(String phone) {
    return ValidationFailure(
      userMessage: '請輸入有效的電話號碼',
      internalMessage: 'Invalid phone format: $phone',
      field: 'phone',
    );
  }

  /// 建立必填欄位錯誤
  factory ValidationFailure.requiredField(String fieldName) {
    return ValidationFailure(
      userMessage: '此欄位為必填',
      internalMessage: 'Required field is empty: $fieldName',
      field: fieldName,
    );
  }

  @override
  List<Object?> get props => [userMessage, internalMessage, field];

  @override
  String toString() {
    return 'ValidationFailure(field: $field)';
  }
}

/// 安全驗證失敗
class SecurityFailure extends Failure {
  const SecurityFailure({
    required super.userMessage,
    required super.internalMessage,
    this.securityCode,
  });

  /// 安全錯誤代碼
  final String? securityCode;

  @override
  List<Object?> get props => [userMessage, internalMessage, securityCode];

  @override
  String toString() {
    // 不在 toString 中顯示任何敏感資訊
    return 'SecurityFailure(securityCode: ${securityCode != null ? '<hidden>' : 'null'})';
  }
}

/// 未預期的錯誤
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required super.userMessage,
    required super.internalMessage,
    this.cause,
  });

  /// 導致此錯誤的原始異常或錯誤
  final Object? cause;

  @override
  List<Object?> get props => [userMessage, internalMessage, cause];

  @override
  String toString() {
    return 'UnexpectedFailure(hasCause: ${cause != null})';
  }
}

/// 快取存取錯誤
class CacheFailure extends Failure {
  const CacheFailure({
    required super.userMessage,
    required super.internalMessage,
    this.operation,
  });

  /// 失敗的快取操作類型
  final String? operation;

  @override
  List<Object?> get props => [userMessage, internalMessage, operation];

  @override
  String toString() {
    return 'CacheFailure(operation: $operation)';
  }
}

/// 權限不足錯誤
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.userMessage,
    required super.internalMessage,
    this.permission,
  });

  /// 缺少的權限名稱
  final String? permission;

  @override
  List<Object?> get props => [userMessage, internalMessage, permission];

  @override
  String toString() {
    return 'PermissionFailure(permission: $permission)';
  }
}
