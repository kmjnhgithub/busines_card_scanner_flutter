// lib/data/models/business_card_model.dart

import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'business_card_model.freezed.dart';
part 'business_card_model.g.dart';

/// Data Model for BusinessCard
///
/// 負責資料層的序列化、反序列化和與 Domain Entity 的轉換
/// 遵循 Clean Architecture 原則：Data Layer → Domain Layer
@freezed
class BusinessCardModel with _$BusinessCardModel {
  const factory BusinessCardModel({
    required String id,
    required String name,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'name_phonetic') String? namePhonetic,
    @JsonKey(name: 'job_title') String? jobTitle,
    String? company,
    String? department,
    String? email,
    String? phone,
    String? mobile,
    String? address,
    String? website,
    String? notes,
    @JsonKey(name: 'photo_path') String? photoPath,
  }) = _BusinessCardModel;

  /// JSON 反序列化工廠方法
  factory BusinessCardModel.fromJson(Map<String, dynamic> json) {
    // 驗證必要欄位
    if (!json.containsKey('id') ||
        json['id'] == null ||
        json['id'].toString().isEmpty) {
      throw const FormatException(
        'BusinessCardModel requires non-empty id field',
      );
    }
    if (!json.containsKey('name') ||
        json['name'] == null ||
        json['name'].toString().isEmpty) {
      throw const FormatException(
        'BusinessCardModel requires non-empty name field',
      );
    }

    // 驗證時間欄位
    try {
      if (json['created_at'] != null) {
        DateTime.parse(json['created_at'].toString());
      }
      if (json['updated_at'] != null) {
        DateTime.parse(json['updated_at'].toString());
      }
    } on FormatException catch (e) {
      throw FormatException(
        'BusinessCardModel requires valid date format for created_at and updated_at: ${e.message}',
      );
    }

    // 設定預設時間值
    final now = DateTime.now();
    json['created_at'] ??= now.toIso8601String();
    json['updated_at'] ??= now.toIso8601String();

    return _$BusinessCardModelFromJson(json);
  }

  /// 從 Domain Entity 創建 Model
  factory BusinessCardModel.fromEntity(BusinessCard entity) {
    return BusinessCardModel(
      id: entity.id,
      name: entity.name,
      jobTitle: entity.jobTitle,
      company: entity.company,
      email: entity.email,
      phone: entity.phone,
      address: entity.address,
      website: entity.website,
      notes: entity.notes,
      photoPath: entity.imagePath, // Domain 的 imagePath 對應到 Data 的 photoPath
      createdAt: entity.createdAt,
      updatedAt:
          entity.updatedAt ?? entity.createdAt, // 如果 updatedAt 為空，使用 createdAt
    );
  }
}

/// Extension for Domain Entity Conversion
extension BusinessCardModelExtension on BusinessCardModel {
  /// 轉換為 Domain Entity
  BusinessCard toEntity() {
    return BusinessCard(
      id: id,
      name: name,
      jobTitle: jobTitle,
      company: company,
      email: email,
      phone: phone,
      address: address,
      website: website,
      notes: notes,
      imagePath: photoPath, // photoPath 對應到 Domain 的 imagePath
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
