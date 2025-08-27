import 'package:busines_card_scanner_flutter/core/services/security_service.dart';
import 'package:busines_card_scanner_flutter/core/services/validation_service.dart';
import 'package:equatable/equatable.dart';

/// 名片業務實體
///
/// 代表一張名片的完整資訊，包含基本聯絡資訊、公司資訊和元資料。
/// 遵循 Clean Architecture 原則，此實體：
/// - 包含業務規則和驗證邏輯
/// - 不依賴外部框架或基礎設施
/// - 提供不可變的資料結構
/// - 包含安全性驗證以防止注入攻擊
class BusinessCard extends Equatable {
  final String id;
  final String name;
  final String? jobTitle;
  final String? company;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? address;
  final String? website;
  final String? notes;
  final String? imagePath; // 本地圖片路徑
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // 靜態服務實例（用於驗證）
  static final ValidationService _validationService = ValidationService();
  static final SecurityService _securityService = SecurityService();

  /// 建立 BusinessCard 實例
  ///
  /// [id] 唯一識別碼（必填且非空）
  /// [name] 姓名（必填且非空）
  /// [createdAt] 建立時間（必填）
  /// 其他欄位皆為選填
  ///
  /// 會自動驗證和清理輸入資料，確保安全性
  BusinessCard({
    required this.id,
    required String name,
    required this.createdAt,
    String? jobTitle,
    String? company,
    String? email,
    String? phone,
    String? mobile,
    String? address,
    String? website,
    String? notes,
    this.imagePath,
    List<String>? tags,
    this.isFavorite = false,
    this.updatedAt,
  }) : name = _cleanString(name) ?? '',
       jobTitle = _cleanString(jobTitle),
       company = _cleanString(company),
       email = _cleanString(email),
       phone = _cleanString(phone),
       mobile = _cleanString(mobile),
       address = _cleanString(address),
       website = _cleanAndValidateWebsite(website),
       notes = _cleanString(notes),
       tags = tags ?? const [] {
    _validateAndSanitize();
  }

  /// 私有建構函式，用於 copyWith 方法避免重複驗證
  const BusinessCard._internal({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.tags,
    required this.isFavorite,
    this.jobTitle,
    this.company,
    this.email,
    this.phone,
    this.mobile,
    this.address,
    this.website,
    this.notes,
    this.imagePath,
    this.updatedAt,
  });

  /// 驗證和清理輸入資料
  void _validateAndSanitize() {
    // 驗證必填欄位
    if (id.trim().isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }
    if (name.isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }

    // 安全性檢查：防止腳本注入
    final fieldsToCheck = [name, jobTitle, company, address, notes];
    for (final field in fieldsToCheck) {
      if (field != null && field.isNotEmpty) {
        final securityResult = _securityService.sanitizeInput(field);
        securityResult.fold(
          (failure) => throw ArgumentError(
            'Security validation failed for field: ${failure.userMessage}',
          ),
          (sanitized) {
            // 檢查是否包含惡意腳本（如 <script> 標籤）
            if (field.contains('<script')) {
              throw ArgumentError(
                'Field contains potentially malicious content',
              );
            }
          },
        );
      }
    }

    // Email 格式驗證
    if (email != null && email!.isNotEmpty) {
      final emailResult = _validationService.validateEmail(email!);
      emailResult.fold(
        (failure) => throw ArgumentError('Invalid email format'),
        (validEmail) {}, // Email is valid
      );
    }

    // 電話號碼格式驗證（允許國際格式）
    if (phone != null && phone!.isNotEmpty) {
      // 更寬鬆的電話號碼驗證，允許各種國際格式
      final phonePattern = RegExp(r'^[\+]?[0-9\-\(\)\s]{7,}$');
      if (!phonePattern.hasMatch(phone!)) {
        throw ArgumentError('Invalid phone number format');
      }
    }

    // 網址驗證已在建構子階段透過 _cleanAndValidateWebsite 完成
    // 這裡不需要額外的驗證邏輯
  }

  /// 清理字串欄位（移除多餘空白）
  static String? _cleanString(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 清理和驗證網址
  static String? _cleanAndValidateWebsite(String? website) {
    final cleaned = _cleanString(website);
    if (cleaned == null || cleaned.isEmpty) {
      return null;
    }

    // 使用驗證服務檢查網址格式
    final urlResult = _validationService.validateUrl(cleaned);
    return urlResult.fold(
      (failure) {
        // 如果驗證失敗，記錄警告並返回 null
        return null;
      },
      (validUrl) => validUrl, // 返回有效的網址
    );
  }

  /// 檢查名片資訊是否完整
  ///
  /// 完整的定義：包含姓名、職稱、公司、以及至少一種聯絡方式
  bool isComplete() {
    return name.isNotEmpty &&
        jobTitle != null &&
        jobTitle!.isNotEmpty &&
        company != null &&
        company!.isNotEmpty &&
        hasContactInfo();
  }

  /// 檢查是否包含聯絡資訊
  ///
  /// 聯絡資訊包括：email、電話、地址或網站
  bool hasContactInfo() {
    return (email != null && email!.isNotEmpty) ||
        (phone != null && phone!.isNotEmpty) ||
        (address != null && address!.isNotEmpty) ||
        (website != null && website!.isNotEmpty);
  }

  /// 取得顯示用的名稱
  ///
  /// 優先顯示姓名，如果姓名為空則使用email或其他識別資訊
  String getDisplayName() {
    if (name.isNotEmpty) {
      return name;
    }
    if (email != null && email!.isNotEmpty) {
      return email!;
    }
    if (company != null && company!.isNotEmpty) {
      return company!;
    }
    return 'Unknown Contact';
  }

  /// 建立一個新的 BusinessCard 實例，並更新指定的欄位
  ///
  /// 使用 copyWith 模式提供不可變的更新操作
  BusinessCard copyWith({
    String? id,
    String? name,
    String? jobTitle,
    String? company,
    String? email,
    String? phone,
    String? mobile,
    String? address,
    String? website,
    String? notes,
    String? imagePath,
    List<String>? tags,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessCard._internal(
      id: id ?? this.id,
      name: name ?? this.name,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      email: _cleanString(email ?? this.email),
      phone: _cleanString(phone ?? this.phone),
      mobile: _cleanString(mobile ?? this.mobile),
      address: address ?? this.address,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    jobTitle,
    company,
    email,
    phone,
    mobile,
    address,
    website,
    notes,
    imagePath,
    tags,
    isFavorite,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    // 基於安全考量，不在 toString 中包含 notes 等敏感資訊
    return 'BusinessCard('
        'id: $id, '
        'name: $name, '
        'jobTitle: $jobTitle, '
        'company: $company, '
        'email: ${email != null ? '***' : null}, '
        'phone: ${phone != null ? '***' : null}, '
        'createdAt: $createdAt'
        ')';
  }
}
