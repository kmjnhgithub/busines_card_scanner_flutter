import 'dart:typed_data';

import 'package:busines_card_scanner_flutter/core/services/security_service.dart';
import 'package:busines_card_scanner_flutter/core/utils/string_utils.dart';
import 'package:equatable/equatable.dart';

/// OCR 處理結果實體
///
/// 代表 OCR 處理的完整結果，包含識別的文字、信心度、圖片資料等。
/// 遵循 Clean Architecture 原則，此實體：
/// - 包含 OCR 相關的業務規則和驗證邏輯
/// - 不依賴外部框架或基礎設施
/// - 提供不可變的資料結構
/// - 包含安全性驗證以防止惡意內容
class OCRResult extends Equatable {
  final String id;
  final String rawText;
  final List<String>? detectedTexts;
  final double confidence;
  final Uint8List? imageData;
  final int? imageWidth;
  final int? imageHeight;
  final DateTime processedAt;
  final int? processingTimeMs;
  final String? ocrEngine;

  // 靜態服務實例（用於安全驗證）
  static final SecurityService _securityService = SecurityService();

  // 高信心度閾值
  static const double _highConfidenceThreshold = 0.9;

  /// 建立 OCRResult 實例
  ///
  /// [id] 唯一識別碼（必填且非空）
  /// [rawText] OCR 識別的原始文字（必填）
  /// [confidence] 信心度，範圍 0.0-1.0（必填）
  /// [processedAt] 處理時間（必填）
  /// 其他欄位皆為選填
  ///
  /// 會自動驗證輸入資料，確保安全性和格式正確性
  OCRResult({
    required this.id,
    required this.rawText,
    required this.confidence,
    required this.processedAt,
    this.detectedTexts,
    this.imageData,
    this.imageWidth,
    this.imageHeight,
    this.processingTimeMs,
    this.ocrEngine,
  }) {
    _validateInput();
  }

  /// 私有建構函式，用於 copyWith 方法避免重複驗證
  const OCRResult._internal({
    required this.id,
    required this.rawText,
    required this.confidence,
    required this.processedAt,
    this.detectedTexts,
    this.imageData,
    this.imageWidth,
    this.imageHeight,
    this.processingTimeMs,
    this.ocrEngine,
  });

  /// 驗證輸入資料
  void _validateInput() {
    // 驗證必填欄位
    if (id.trim().isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }

    // 驗證信心度範圍
    if (confidence < 0.0 || confidence > 1.0) {
      throw ArgumentError(
        'Confidence must be between 0.0 and 1.0, got: $confidence',
      );
    }

    // 驗證圖片尺寸
    if (imageWidth != null && imageWidth! <= 0) {
      throw ArgumentError('Image width must be positive, got: $imageWidth');
    }
    if (imageHeight != null && imageHeight! <= 0) {
      throw ArgumentError('Image height must be positive, got: $imageHeight');
    }

    // 驗證處理時間
    if (processingTimeMs != null && processingTimeMs! < 0) {
      throw ArgumentError(
        'Processing time cannot be negative, got: $processingTimeMs',
      );
    }

    // 安全性檢查：防止腳本注入
    final fieldsToCheck = [rawText, ocrEngine];
    for (final field in fieldsToCheck) {
      if (field != null && field.isNotEmpty) {
        final securityResult = _securityService.sanitizeInput(field);
        securityResult.fold(
          (failure) => throw ArgumentError(
            'Security validation failed: ${failure.userMessage}',
          ),
          (sanitized) {
            // 檢查是否包含惡意腳本
            if (field.contains('<script')) {
              throw ArgumentError(
                'Field contains potentially malicious content',
              );
            }
          },
        );
      }
    }

    // 檢查 detectedTexts 中的安全性
    if (detectedTexts != null) {
      for (final text in detectedTexts!) {
        if (text.contains('<script')) {
          throw ArgumentError(
            'Detected text contains potentially malicious content',
          );
        }
      }
    }
  }

  /// 檢查是否為高信心度結果
  ///
  /// 高信心度定義為 confidence >= 0.9
  bool isHighConfidence() {
    return confidence >= _highConfidenceThreshold;
  }

  /// 檢查是否有偵測到的文字列表
  bool hasDetectedTexts() {
    return detectedTexts != null && detectedTexts!.isNotEmpty;
  }

  /// 取得效能資訊
  ///
  /// 回傳包含處理時間、信心度、文字長度等效能相關資料的 Map
  Map<String, dynamic> getPerformanceInfo() {
    return {
      'processingTimeMs': processingTimeMs,
      'confidence': confidence,
      'textLength': rawText.length,
      'detectedTextCount': detectedTexts?.length ?? 0,
      'hasImageData': imageData != null,
      'imageSize': (imageWidth != null && imageHeight != null)
          ? '${imageWidth}x$imageHeight'
          : null,
    };
  }

  /// 從偵測到的文字中提取 Email 地址
  ///
  /// 使用 StringUtils 的 extractEmails 方法
  List<String> extractEmails() {
    if (!hasDetectedTexts()) {
      return [];
    }

    final allEmails = <String>[];
    for (final text in detectedTexts!) {
      final emails = StringUtils.extractEmails(text);
      allEmails.addAll(emails);
    }

    // 也檢查原始文字
    allEmails.addAll(StringUtils.extractEmails(rawText));

    // 去重並排序
    return allEmails.toSet().toList()..sort();
  }

  /// 從偵測到的文字中提取電話號碼
  ///
  /// 使用 StringUtils 的 extractPhoneNumbers 方法
  List<String> extractPhoneNumbers() {
    if (!hasDetectedTexts()) {
      return [];
    }

    final allPhones = <String>[];
    for (final text in detectedTexts!) {
      final phones = StringUtils.extractPhoneNumbers(text);
      allPhones.addAll(phones);
    }

    // 也檢查原始文字
    allPhones.addAll(StringUtils.extractPhoneNumbers(rawText));

    // 去重並排序
    return allPhones.toSet().toList()..sort();
  }

  /// 建立一個新的 OCRResult 實例，並更新指定的欄位
  ///
  /// 使用 copyWith 模式提供不可變的更新操作
  OCRResult copyWith({
    String? id,
    String? rawText,
    List<String>? detectedTexts,
    double? confidence,
    Uint8List? imageData,
    int? imageWidth,
    int? imageHeight,
    DateTime? processedAt,
    int? processingTimeMs,
    String? ocrEngine,
  }) {
    return OCRResult._internal(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      detectedTexts: detectedTexts ?? this.detectedTexts,
      confidence: confidence ?? this.confidence,
      imageData: imageData ?? this.imageData,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      processedAt: processedAt ?? this.processedAt,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      ocrEngine: ocrEngine ?? this.ocrEngine,
    );
  }

  @override
  List<Object?> get props => [
    id,
    rawText,
    detectedTexts,
    confidence,
    imageData,
    imageWidth,
    imageHeight,
    processedAt,
    processingTimeMs,
    ocrEngine,
  ];

  @override
  String toString() {
    // 基於安全考量，不在 toString 中包含完整的原始文字和圖片資料
    return 'OCRResult('
        'id: $id, '
        'confidence: ${confidence.toStringAsFixed(2)}, '
        'textLength: ${rawText.length}, '
        'ocrEngine: $ocrEngine, '
        'processedAt: $processedAt'
        ')';
  }
}
