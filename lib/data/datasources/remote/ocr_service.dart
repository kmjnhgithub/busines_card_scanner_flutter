import 'dart:typed_data';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';

/// OCR 服務抽象類別
///
/// 定義 OCR 處理服務的介面，支援多種 OCR 引擎：
/// - Google ML Kit (跨平台)
/// - iOS Vision Framework (iOS 專用)
/// - 其他第三方 OCR 服務
///
/// 遵循依賴反轉原則，Repository 依賴此抽象介面而非具體實作
abstract class OCRService {
  /// 執行圖片文字識別
  ///
  /// [imageData] 要識別的圖片資料
  /// [options] 識別選項配置
  ///
  /// 回傳 OCR 識別結果
  Future<OCRResult> recognizeText(Uint8List imageData, {OCROptions? options});

  /// 取得可用的 OCR 引擎列表
  Future<List<OCREngineInfo>> getAvailableEngines();

  /// 設定偏好的 OCR 引擎
  Future<void> setPreferredEngine(String engineId);

  /// 取得當前使用的 OCR 引擎
  Future<OCREngineInfo> getCurrentEngine();

  /// 測試 OCR 引擎狀態
  Future<OCREngineHealth> testEngine({String? engineId});

  /// 預處理圖片以提升 OCR 準確度
  Future<Uint8List> preprocessImage(
    Uint8List imageData, {
    ImagePreprocessOptions? options,
  });
}
