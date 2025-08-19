import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_detail_state.freezed.dart';

/// 名片詳情頁面狀態
@Freezed(toJson: false, fromJson: false)
class CardDetailState with _$CardDetailState {
  const factory CardDetailState({
    /// 當前模式
    required CardDetailMode mode,

    /// 是否正在載入
    @Default(false) bool isLoading,

    /// 是否正在儲存
    @Default(false) bool isSaving,

    /// 錯誤訊息
    String? error,

    /// 原始名片資料（編輯和檢視模式用）
    BusinessCard? originalCard,

    /// 當前編輯中的名片資料
    BusinessCard? currentCard,

    /// 表單驗證錯誤
    @Default({}) Map<String, String> validationErrors,

    /// 是否已修改
    @Default(false) bool hasChanges,

    /// OCR 解析的名片資料（新增模式用）
    BusinessCard? ocrParsedCard,

    /// OCR 信心度
    double? confidence,

    /// 是否來自 AI 解析
    @Default(false) bool fromAIParsing,
  }) = _CardDetailState;

  /// 初始狀態
  const factory CardDetailState.initial() = _Initial;

  /// 檢視模式狀態
  const factory CardDetailState.viewing({required BusinessCard card}) =
      _Viewing;

  /// 編輯模式狀態
  const factory CardDetailState.editing({
    required BusinessCard originalCard,
    required BusinessCard currentCard,
    @Default(false) bool hasChanges,
    @Default({}) Map<String, String> validationErrors,
  }) = _Editing;

  /// 新增模式狀態（來自 OCR）
  const factory CardDetailState.creating({
    required BusinessCard parsedCard,
    double? confidence,
    @Default(false) bool fromAIParsing,
    @Default({}) Map<String, String> validationErrors,
  }) = _Creating;

  /// 手動建立模式狀態
  const factory CardDetailState.manual({
    required BusinessCard emptyCard,
    @Default({}) Map<String, String> validationErrors,
  }) = _Manual;

  /// 載入中狀態
  const factory CardDetailState.loading() = _Loading;

  /// 錯誤狀態
  const factory CardDetailState.error({required String message}) = _Error;
}

/// 名片詳情模式
enum CardDetailMode {
  /// 檢視模式 - 唯讀顯示既有名片
  viewing,

  /// 編輯模式 - 修改既有名片資料
  editing,

  /// 新增模式 - OCR 結果預填，可編輯
  creating,

  /// 手動模式 - 空白表單建立
  manual,
}

/// 名片詳情頁面參數
@Freezed(toJson: false, fromJson: false)
class CardDetailParams with _$CardDetailParams {
  const factory CardDetailParams({
    /// 模式
    required CardDetailMode mode,

    /// 名片 ID（檢視和編輯模式必需）
    String? cardId,

    /// OCR 解析的名片資料（新增模式使用）
    BusinessCard? ocrParsedCard,

    /// OCR 信心度
    double? confidence,

    /// 是否來自 AI 解析
    @Default(false) bool fromAIParsing,

    /// 圖片路徑（可選）
    String? imagePath,
  }) = _CardDetailParams;

  /// 檢視模式參數
  const factory CardDetailParams.viewing({required String cardId}) =
      _ViewingParams;

  /// 編輯模式參數
  const factory CardDetailParams.editing({required String cardId}) =
      _EditingParams;

  /// 新增模式參數（來自 OCR）
  const factory CardDetailParams.creating({
    required BusinessCard parsedCard,
    double? confidence,
    @Default(false) bool fromAIParsing,
    String? imagePath,
  }) = _CreatingParams;

  /// 手動建立參數
  const factory CardDetailParams.manual() = _ManualParams;
}

/// 驗證結果
@Freezed(toJson: false, fromJson: false)
class ValidationResult with _$ValidationResult {
  const factory ValidationResult({
    @Default(true) bool isValid,
    @Default({}) Map<String, String> errors,
  }) = _ValidationResult;

  const factory ValidationResult.valid() = _Valid;

  const factory ValidationResult.invalid({
    required Map<String, String> errors,
  }) = _Invalid;
}
