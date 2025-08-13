import 'package:busines_card_scanner_flutter/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

/// 驗證服務，提供各種輸入驗證功能
class ValidationService {
  // 編譯一次的正規表達式，提升效能  
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z0-9]{1,}$',
  );


  static final RegExp _urlRegex = RegExp(
    r'^(https?|ftp)://[^\s/$.?#].[^\s]*$',
    caseSensitive: false,
  );

  static final RegExp _nameRegex = RegExp(
    r"^[\p{L}\s'-]+$",
    unicode: true,
  );

  static final RegExp _companyNameRegex = RegExp(
    r"^[\p{L}\p{N}\s.,()&'-]+$",
    unicode: true,
  );

  /// 驗證電子信箱格式
  Either<ValidationFailure, String> validateEmail(String email) {
    if (email.isEmpty) {
      return Left(ValidationFailure.invalidEmail(email));
    }

    // 檢查長度限制（RFC 5321）
    if (email.length > 254) {
      return const Left(ValidationFailure(
        userMessage: '電子信箱長度不能超過 254 個字元',
        internalMessage: 'Email too long',
        field: 'email',
      ));
    }

    // 檢查是否有前後空白
    if (email.trim() != email) {
      return Left(ValidationFailure.invalidEmail(email));
    }

    // 基本格式驗證
    if (!_emailRegex.hasMatch(email)) {
      return Left(ValidationFailure.invalidEmail(email));
    }

    // 檢查本地部分長度（@符號前）
    final parts = email.split('@');
    if (parts.length != 2) {
      return Left(ValidationFailure.invalidEmail(email));
    }

    final localPart = parts[0];
    final domainPart = parts[1];

    if (localPart.length > 64) {
      return const Left(ValidationFailure(
        userMessage: '電子信箱本地部分過長',
        internalMessage: 'Email local part too long',
        field: 'email',
      ));
    }

    // 檢查域名部分
    if (domainPart.isEmpty || domainPart.startsWith('.') || domainPart.endsWith('.')) {
      return Left(ValidationFailure.invalidEmail(email));
    }

    // 檢查是否有連續的點號
    if (domainPart.contains('..')) {
      return Left(ValidationFailure.invalidEmail(email));
    }

    return Right(email);
  }

  /// 驗證台灣電話號碼格式
  Either<ValidationFailure, String> validatePhoneNumber(String phone) {
    if (phone.isEmpty) {
      return Left(ValidationFailure.invalidPhone(phone));
    }

    // 移除所有空白和特殊符號進行基本驗證
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    
    // 檢查是否只包含數字
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      return Left(ValidationFailure.invalidPhone(phone));
    }

    // 檢查長度和格式
    bool isValid = false;

    // 國際格式 886xxxxxxxxx
    if (cleanPhone.startsWith('886') && cleanPhone.length >= 12 && cleanPhone.length <= 13) {
      isValid = true;
    }
    // 手機格式 09xxxxxxxx
    else if (cleanPhone.startsWith('09') && cleanPhone.length == 10) {
      isValid = true;
    }
    // 市話格式 0xxxxxxxxx
    else if (cleanPhone.startsWith('0') && cleanPhone.length >= 9 && cleanPhone.length <= 10) {
      final areaCode = cleanPhone.substring(0, 2);
      final validAreaCodes = ['02', '03', '04', '05', '06', '07', '08'];
      if (validAreaCodes.contains(areaCode)) {
        isValid = true;
      }
    }

    if (!isValid) {
      return Left(ValidationFailure.invalidPhone(phone));
    }

    return Right(phone);
  }

  /// 驗證網址格式
  Either<ValidationFailure, String> validateUrl(String url) {
    if (url.isEmpty) {
      return const Left(ValidationFailure(
        userMessage: '請輸入有效的網址',
        internalMessage: 'Empty URL provided',
        field: 'url',
      ));
    }

    // 檢查是否包含空格
    if (url.contains(' ')) {
      return Left(ValidationFailure(
        userMessage: '網址不能包含空格',
        internalMessage: 'URL contains spaces: $url',
        field: 'url',
      ));
    }

    // 基本格式驗證
    if (!_urlRegex.hasMatch(url)) {
      return Left(ValidationFailure(
        userMessage: '請輸入有效的網址格式',
        internalMessage: 'Invalid URL format: $url',
        field: 'url',
      ));
    }

    // 檢查危險協議
    final lowerUrl = url.toLowerCase();
    final dangerousProtocols = ['javascript:', 'data:', 'vbscript:', 'file:'];
    for (final protocol in dangerousProtocols) {
      if (lowerUrl.startsWith(protocol)) {
        return Left(ValidationFailure(
          userMessage: '不支援的網址協議',
          internalMessage: 'Dangerous protocol detected: $protocol',
          field: 'url',
        ));
      }
    }

    return Right(url);
  }

  /// 驗證姓名格式（支援中英文）
  Either<ValidationFailure, String> validateName(String name) {
    if (name.isEmpty) {
      return Left(ValidationFailure.requiredField('name'));
    }

    // 移除前後空白進行驗證
    final trimmedName = name.trim();
    if (trimmedName != name) {
      return Left(ValidationFailure(
        userMessage: '姓名不能有前後空白',
        internalMessage: 'Name has leading/trailing spaces: "$name"',
        field: 'name',
      ));
    }

    // 檢查長度
    if (trimmedName.length > 100) {
      return const Left(ValidationFailure(
        userMessage: '姓名長度不能超過 100 個字元',
        internalMessage: 'Name too long',
        field: 'name',
      ));
    }

    // 檢查是否只包含數字
    if (RegExp(r'^[0-9]+$').hasMatch(trimmedName)) {
      return Left(ValidationFailure(
        userMessage: '姓名不能只包含數字',
        internalMessage: 'Name contains only numbers: $trimmedName',
        field: 'name',
      ));
    }

    // 檢查是否包含不允許的特殊字元（允許中文、英文、空格、連字號、撇號）
    if (!_nameRegex.hasMatch(trimmedName)) {
      return Left(ValidationFailure(
        userMessage: '姓名只能包含中英文字母、空格、連字號和撇號',
        internalMessage: 'Name contains invalid characters: $trimmedName',
        field: 'name',
      ));
    }

    // 檢查是否包含控制字元
    if (trimmedName.contains(RegExp(r'[\n\r\t]'))) {
      return const Left(ValidationFailure(
        userMessage: '姓名不能包含換行符號',
        internalMessage: 'Name contains control characters',
        field: 'name',
      ));
    }

    return Right(trimmedName);
  }

  /// 驗證公司名稱
  Either<ValidationFailure, String> validateCompanyName(String companyName) {
    if (companyName.isEmpty) {
      return Left(ValidationFailure.requiredField('companyName'));
    }

    final trimmedName = companyName.trim();

    // 檢查最小長度
    if (trimmedName.length < 2) {
      return Left(ValidationFailure(
        userMessage: '公司名稱至少需要 2 個字元',
        internalMessage: 'Company name too short: ${trimmedName.length}',
        field: 'companyName',
      ));
    }

    // 檢查最大長度
    if (trimmedName.length > 200) {
      return const Left(ValidationFailure(
        userMessage: '公司名稱不能超過 200 個字元',
        internalMessage: 'Company name too long',
        field: 'companyName',
      ));
    }

    // 檢查是否只包含數字
    if (RegExp(r'^[0-9]+$').hasMatch(trimmedName)) {
      return Left(ValidationFailure(
        userMessage: '公司名稱不能只包含數字',
        internalMessage: 'Company name is only numbers: $trimmedName',
        field: 'companyName',
      ));
    }

    // 檢查格式（允許中英文、數字、常見標點符號）
    if (!_companyNameRegex.hasMatch(trimmedName)) {
      return Left(ValidationFailure(
        userMessage: '公司名稱包含不允許的字元',
        internalMessage: 'Company name contains invalid characters: $trimmedName',
        field: 'companyName',
      ));
    }

    // 檢查是否包含控制字元
    if (trimmedName.contains(RegExp(r'[\n\r\t]'))) {
      return const Left(ValidationFailure(
        userMessage: '公司名稱不能包含控制字元',
        internalMessage: 'Company name contains control characters',
        field: 'companyName',
      ));
    }

    return Right(trimmedName);
  }

  /// 驗證最小長度
  Either<ValidationFailure, String> validateMinLength(String text, int minLength) {
    if (text.length < minLength) {
      return Left(ValidationFailure(
        userMessage: '至少需要 $minLength 個字元',
        internalMessage: 'Text too short: ${text.length} < $minLength',
        field: 'text',
      ));
    }
    return Right(text);
  }

  /// 驗證最大長度
  Either<ValidationFailure, String> validateMaxLength(String text, int maxLength) {
    if (text.length > maxLength) {
      return Left(ValidationFailure(
        userMessage: '不能超過 $maxLength 個字元',
        internalMessage: 'Text too long: ${text.length} > $maxLength',
        field: 'text',
      ));
    }
    return Right(text);
  }

  /// 驗證長度範圍
  Either<ValidationFailure, String> validateLengthRange(String text, int minLength, int maxLength) {
    if (text.length < minLength) {
      return Left(ValidationFailure(
        userMessage: '至少需要 $minLength 個字元',
        internalMessage: 'Text too short: ${text.length} < $minLength',
        field: 'text',
      ));
    }
    if (text.length > maxLength) {
      return Left(ValidationFailure(
        userMessage: '不能超過 $maxLength 個字元',
        internalMessage: 'Text too long: ${text.length} > $maxLength',
        field: 'text',
      ));
    }
    return Right(text);
  }

  /// 驗證必填欄位
  Either<ValidationFailure, String> validateRequired(String text, String fieldName) {
    if (text.trim().isEmpty) {
      return Left(ValidationFailure.requiredField(fieldName));
    }
    return Right(text);
  }
}