import 'dart:typed_data';

import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/create_card_from_image_usecase.dart';

/// CreateCardFromImageParams 的 Builder 類別
///
/// 使用 Builder Pattern 來建立複雜的參數物件，
/// 確保圖片資料來源的一致性和參數配置的靈活性
class CreateCardFromImageParamsBuilder {
  // 圖片資料（二選一）
  Uint8List? _imageData;
  String? _imagePath;

  // OCR 和處理選項
  OCROptions? _ocrOptions;
  ImagePreprocessOptions? _preprocessOptions;
  ParseHints? _parseHints;
  double? _confidenceThreshold;

  // 行為設定
  bool _saveOCRResult = false;
  bool _validateResults = true;
  bool _dryRun = false;
  bool _trackMetrics = false;
  bool _autoCleanup = true;
  Duration? _timeout;

  /// 從圖片資料建立
  CreateCardFromImageParamsBuilder fromImageData(Uint8List imageData) {
    _imageData = imageData;
    _imagePath = null;
    return this;
  }

  /// 從圖片路徑建立
  CreateCardFromImageParamsBuilder fromImagePath(String imagePath) {
    _imagePath = imagePath;
    _imageData = null;
    return this;
  }

  /// 同時設定圖片資料和儲存路徑
  /// 用於拍照後的情況：有資料也有儲存位置
  CreateCardFromImageParamsBuilder fromCameraCapture(
    Uint8List imageData,
    String savedPath,
  ) {
    _imageData = imageData;
    _imagePath = savedPath;
    return this;
  }

  /// 設定 OCR 選項
  CreateCardFromImageParamsBuilder withOCROptions(OCROptions options) {
    _ocrOptions = options;
    return this;
  }

  /// 設定圖片預處理選項
  CreateCardFromImageParamsBuilder withPreprocessOptions(
    ImagePreprocessOptions options,
  ) {
    _preprocessOptions = options;
    return this;
  }

  /// 設定解析提示
  CreateCardFromImageParamsBuilder withParseHints(ParseHints hints) {
    _parseHints = hints;
    return this;
  }

  /// 設定信心度閾值
  CreateCardFromImageParamsBuilder withConfidenceThreshold(double threshold) {
    _confidenceThreshold = threshold;
    return this;
  }

  /// 是否儲存 OCR 結果
  CreateCardFromImageParamsBuilder saveOCRResult({required bool save}) {
    _saveOCRResult = save;
    return this;
  }

  /// 是否驗證結果
  CreateCardFromImageParamsBuilder validateResults({required bool validate}) {
    _validateResults = validate;
    return this;
  }

  /// 是否為乾執行（不實際儲存）
  CreateCardFromImageParamsBuilder dryRun({required bool dry}) {
    _dryRun = dry;
    return this;
  }

  /// 是否追蹤指標
  CreateCardFromImageParamsBuilder trackMetrics({required bool track}) {
    _trackMetrics = track;
    return this;
  }

  /// 是否自動清理
  CreateCardFromImageParamsBuilder autoCleanup({required bool cleanup}) {
    _autoCleanup = cleanup;
    return this;
  }

  /// 設定逾時
  CreateCardFromImageParamsBuilder withTimeout(Duration timeout) {
    _timeout = timeout;
    return this;
  }

  /// 建立參數物件
  CreateCardFromImageParams build() {
    // 驗證必要參數
    if (_imageData == null && _imagePath == null) {
      throw ArgumentError('必須提供圖片資料或圖片路徑');
    }

    // 如果只有路徑，需要確保可以讀取
    if (_imageData == null && _imagePath != null) {
      // 這裡可以加入路徑驗證邏輯
      // 實際使用時，UseCase 會負責從路徑讀取資料
    }

    return CreateCardFromImageParams(
      imageData: _imageData ?? Uint8List(0), // 提供空資料作為預設
      imagePath: _imagePath,
      ocrOptions: _ocrOptions,
      preprocessOptions: _preprocessOptions,
      parseHints: _parseHints,
      confidenceThreshold: _confidenceThreshold,
      saveOCRResult: _saveOCRResult,
      validateResults: _validateResults,
      dryRun: _dryRun,
      trackMetrics: _trackMetrics,
      autoCleanup: _autoCleanup,
      timeout: _timeout,
    );
  }

  /// 建立預設的參數配置
  static CreateCardFromImageParams buildDefault(Uint8List imageData) {
    return CreateCardFromImageParamsBuilder()
        .fromImageData(imageData)
        .validateResults(validate: true)
        .autoCleanup(cleanup: true)
        .build();
  }

  /// 建立用於測試的參數配置
  static CreateCardFromImageParams buildForTesting(Uint8List imageData) {
    return CreateCardFromImageParamsBuilder()
        .fromImageData(imageData)
        .dryRun(dry: true)
        .validateResults(validate: false)
        .trackMetrics(track: true)
        .build();
  }
}
