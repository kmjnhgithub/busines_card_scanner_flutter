import 'dart:io';

import 'package:busines_card_scanner_flutter/data/datasources/local/local_card_parser.dart';
import 'package:busines_card_scanner_flutter/data/datasources/local/secure/enhanced_secure_storage.dart';
import 'package:busines_card_scanner_flutter/data/datasources/remote/openai_service.dart';
import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/process_image_usecase.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/loading_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/toast_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/data_providers.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/domain_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

part 'ocr_processing_view_model.freezed.dart';

/// OCR 處理步驟
enum OCRProcessingStep {
  /// 閒置狀態
  idle,

  /// 圖片已載入
  imageLoaded,

  /// OCR 處理中
  ocrProcessing,

  /// OCR 處理完成
  ocrCompleted,

  /// AI 解析中
  aiProcessing,

  /// 處理完成
  completed,
}

/// OCR 處理狀態
@Freezed(toJson: false, fromJson: false)
class OCRProcessingState with _$OCRProcessingState {
  const factory OCRProcessingState({
    /// 圖片資料
    Uint8List? imageData,

    /// OCR 結果
    OCRResult? ocrResult,

    /// 解析後的名片
    BusinessCard? parsedCard,

    /// 處理步驟
    @Default(OCRProcessingStep.idle) OCRProcessingStep processingStep,

    /// 是否正在載入
    @Default(false) bool isLoading,

    /// 錯誤訊息
    String? error,

    /// OCR 信心度
    double? confidence,

    /// 警告訊息
    @Default([]) List<String> warnings,

    /// 壓縮後的圖片路徑
    String? compressedImagePath,

    /// 解析來源（AI 或本地）
    ParseSource? parseSource,
  }) = _OCRProcessingState;

  const OCRProcessingState._();

  /// 根據處理步驟判斷是否正在載入
  bool get isLoadingFromStep =>
      processingStep == OCRProcessingStep.ocrProcessing ||
      processingStep == OCRProcessingStep.aiProcessing;
}

/// OCR 處理 ViewModel
///
/// 負責管理OCR處理流程，包括：
/// - 圖片載入和驗證
/// - OCR文字識別
/// - AI解析和結構化（含 fallback 機制）
/// - 圖片壓縮和儲存
/// - 編輯和重新解析功能
/// - 完整的錯誤處理
class OCRProcessingViewModel extends StateNotifier<OCRProcessingState> {
  OCRProcessingViewModel(
    this._processImageUseCase,
    this._loadingPresenter,
    this._toastPresenter,
    this._openAIService,
    this._secureStorage,
  ) : super(const OCRProcessingState()) {
    _localParser = LocalCardParser();
  }

  final ProcessImageUseCase _processImageUseCase;
  final LoadingPresenter _loadingPresenter;
  final ToastPresenter _toastPresenter;
  final OpenAIService _openAIService;
  final EnhancedSecureStorage _secureStorage;
  late final LocalCardParser _localParser;

  /// 載入圖片
  Future<void> loadImage(Uint8List imageData) async {
    if (imageData.isEmpty) {
      _updateError('圖片資料不能為空');
      _toastPresenter.showError('圖片資料不能為空');
      return;
    }

    state = state.copyWith(
      imageData: imageData,
      processingStep: OCRProcessingStep.imageLoaded,
      error: null,
    );
  }

  /// 執行 OCR 處理
  Future<void> processOCR() async {
    if (state.imageData == null) {
      _updateError('請先載入圖片');
      _toastPresenter.showError('請先載入圖片');
      return;
    }

    try {
      _loadingPresenter.show('正在處理圖片...');
      _updateProcessingStep(OCRProcessingStep.ocrProcessing);

      final params = ProcessImageParams(imageData: state.imageData!);
      final result = await _processImageUseCase.execute(params);

      state = state.copyWith(
        ocrResult: result.ocrResult,
        processingStep: OCRProcessingStep.ocrCompleted,
        confidence: result.ocrResult.confidence,
        warnings: result.warnings,
        error: null,
      );

      // 檢查信心度並顯示警告
      if (result.ocrResult.confidence < 0.7) {
        _toastPresenter.showWarning('OCR 信心度較低，建議重新拍攝');
      }

      _loadingPresenter.hide();
    } on Exception catch (e) {
      _loadingPresenter.hide();
      _updateError('OCR 處理失敗: $e');
      _toastPresenter.showError('OCR 處理失敗: $e');
      state = state.copyWith(processingStep: OCRProcessingStep.imageLoaded);
    }
  }

  /// 智慧解析 OCR 文字（AI 優先，自動 fallback）
  Future<void> parseWithAI() async {
    if (state.ocrResult == null) {
      _updateError('請先完成 OCR 處理');
      _toastPresenter.showError('請先完成 OCR 處理');
      return;
    }

    try {
      _loadingPresenter.show('正在解析名片資訊...');
      _updateProcessingStep(OCRProcessingStep.aiProcessing);

      BusinessCard? parsedCard;
      ParseSource source = ParseSource.local;

      // 首先嘗試使用 AI 服務
      bool aiAvailable = await _checkAIAvailability();

      if (aiAvailable) {
        try {
          _loadingPresenter.show('AI 正在解析名片資訊...');
          final aiResult = await _openAIService.parseCardFromText(
            state.ocrResult!.rawText,
          );

          // 將 ParsedCardData 轉換為 BusinessCard
          parsedCard = _convertToBusinessCard(aiResult);
          source = ParseSource.ai;

          debugPrint('AI 解析成功，信心度: ${aiResult.confidence}');
        } on Exception catch (aiError) {
          debugPrint('AI 解析失敗，切換到本地解析: $aiError');
          // AI 失敗，將使用本地解析（fallback）
        }
      }

      // 如果 AI 不可用或失敗，使用本地正則表達式解析
      if (parsedCard == null) {
        _loadingPresenter.show('正在使用本地解析...');
        final localResult = _localParser.parseCard(state.ocrResult!.rawText);

        // 只有當解析結果有意義時才使用（至少有姓名或公司）
        if (localResult.confidence > 0.3 &&
            (localResult.name != null || localResult.company != null)) {
          parsedCard = _convertToBusinessCard(localResult);
          source = ParseSource.local;
          debugPrint('本地解析完成，信心度: ${localResult.confidence}');
        } else {
          debugPrint('本地解析信心度過低或資料不足');
          // 不設置 parsedCard，保持為 null
        }

        // 如果是因為 AI 不可用而使用本地解析，提示用戶
        if (!aiAvailable && parsedCard != null) {
          _toastPresenter.showInfo('已切換至本地解析模式（AI 服務未啟用）');
          debugPrint('AI 服務不可用，建議在設定中配置 OpenAI API Key 以獲得更精確的解析結果');
        }
      }

      // 檢查是否成功解析
      if (parsedCard != null) {
        state = state.copyWith(
          parsedCard: parsedCard,
          processingStep: OCRProcessingStep.completed,
          parseSource: source,
          error: null,
        );

        _loadingPresenter.hide();

        // 顯示解析來源
        final sourceText = source == ParseSource.ai ? 'AI 智慧解析' : '本地解析';
        _toastPresenter.showSuccess('名片解析完成（$sourceText）');
      } else {
        // 解析失敗 - 設定狀態並提供手動輸入選項
        _loadingPresenter.hide();

        // 建立空白名片供手動輸入
        final emptyCard = BusinessCard(
          id: const Uuid().v4(),
          name: '手動輸入名片',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: const [],
          imagePath: state.compressedImagePath,
        );

        state = state.copyWith(
          parsedCard: emptyCard,
          processingStep: OCRProcessingStep.completed,
          parseSource: ParseSource.manual,
          error: null,
        );

        // 提示用戶需要手動輸入
        _toastPresenter.showWarning('無法自動解析名片，已切換至手動輸入模式');
        debugPrint('OCR 解析失敗：可能是圖片不夠清晰或光線不足，已提供空白表單供手動輸入');
      }
    } on Exception catch (e) {
      _loadingPresenter.hide();
      _updateError('名片解析失敗: $e');
      _toastPresenter.showError('名片解析失敗: $e');
      state = state.copyWith(processingStep: OCRProcessingStep.ocrCompleted);
    }
  }

  /// 完整的圖片到名片處理流程（包含圖片壓縮）
  Future<void> processImageToCard(Uint8List imageData) async {
    try {
      _loadingPresenter.show('正在處理名片...');
      state = state.copyWith(
        imageData: imageData,
        processingStep: OCRProcessingStep.ocrProcessing,
        error: null,
      );

      // 1. 壓縮並儲存圖片
      final compressedPath = await _compressAndSaveImage(imageData);
      state = state.copyWith(compressedImagePath: compressedPath);

      // 2. 執行 OCR
      _loadingPresenter.show('正在識別文字...');
      final ocrParams = ProcessImageParams(imageData: imageData);
      final ocrResult = await _processImageUseCase.execute(ocrParams);

      state = state.copyWith(
        ocrResult: ocrResult.ocrResult,
        confidence: ocrResult.ocrResult.confidence,
        warnings: ocrResult.warnings,
      );

      // 3. 智慧解析（AI + Fallback）
      await parseWithAI();

      // 4. 更新最終狀態，包含圖片路徑
      if (state.parsedCard != null && compressedPath != null) {
        final updatedCard = state.parsedCard!.copyWith(
          imagePath: compressedPath,
        );
        state = state.copyWith(parsedCard: updatedCard);
      }
    } on Exception catch (e) {
      _loadingPresenter.hide();
      _updateError('名片處理失敗: $e');
      _toastPresenter.showError('名片處理失敗: $e');
      state = state.copyWith(processingStep: OCRProcessingStep.idle);
    }
  }

  /// 設定 OCR 結果（用於測試或外部設定）
  void setOCRResult(OCRResult ocrResult) {
    state = state.copyWith(
      ocrResult: ocrResult,
      confidence: ocrResult.confidence,
      processingStep: OCRProcessingStep.ocrCompleted,
    );
  }

  /// 更新處理步驟
  void updateProcessingStep(OCRProcessingStep step) {
    state = state.copyWith(
      processingStep: step,
      isLoading:
          step == OCRProcessingStep.ocrProcessing ||
          step == OCRProcessingStep.aiProcessing,
    );
  }

  /// 手動編輯 OCR 文字
  void updateOCRText(String newText) {
    if (state.ocrResult == null) {
      return;
    }

    // 創建新的 OCR 結果，保持其他屬性不變
    final updatedOCRResult = OCRResult(
      id: state.ocrResult!.id,
      rawText: newText,
      confidence: state.ocrResult!.confidence,
      processedAt: state.ocrResult!.processedAt,
      detectedTexts: state.ocrResult!.detectedTexts,
      imageData: state.ocrResult!.imageData,
      imageWidth: state.ocrResult!.imageWidth,
      imageHeight: state.ocrResult!.imageHeight,
      processingTimeMs: state.ocrResult!.processingTimeMs,
      ocrEngine: state.ocrResult!.ocrEngine,
    );

    state = state.copyWith(ocrResult: updatedOCRResult);
  }

  /// 重新解析編輯過的文字
  Future<void> reparseText() async {
    if (state.ocrResult == null) {
      _toastPresenter.showError('沒有 OCR 文字可供解析');
      return;
    }

    await parseWithAI();
  }

  /// 重試處理
  Future<void> retryProcessing() async {
    if (state.imageData == null) {
      _toastPresenter.showError('沒有圖片可供重試');
      return;
    }

    await processOCR();
  }

  /// 重設狀態
  void resetState() {
    state = const OCRProcessingState();
  }

  /// 更新錯誤狀態
  void _updateError(String error) {
    state = state.copyWith(error: error);
  }

  /// 更新處理步驟（私有）
  void _updateProcessingStep(OCRProcessingStep step) {
    state = state.copyWith(
      processingStep: step,
      isLoading:
          step == OCRProcessingStep.ocrProcessing ||
          step == OCRProcessingStep.aiProcessing,
    );
  }

  /// 檢查 AI 服務是否可用
  Future<bool> _checkAIAvailability() async {
    try {
      // 檢查是否有 API Key
      final apiKeyResult = await _secureStorage.getApiKey('openai_api_key');
      final hasApiKey = apiKeyResult.fold(
        (failure) => false,
        (apiKey) => apiKey.isNotEmpty,
      );

      if (!hasApiKey) {
        debugPrint('AI 服務未設定 API Key');
        return false;
      }

      // 檢查服務狀態
      final status = await _openAIService.getServiceStatus();
      return status.isAvailable;
    } on Exception catch (e) {
      debugPrint('檢查 AI 服務狀態失敗: $e');
      return false;
    }
  }

  /// 將 ParsedCardData 轉換為 BusinessCard
  BusinessCard _convertToBusinessCard(ParsedCardData parsedData) {
    // 為空白或無效的名稱提供預設值
    String finalName = parsedData.name?.trim() ?? '';
    if (finalName.isEmpty) {
      // 嘗試使用公司名稱作為名稱
      if (parsedData.company?.trim().isNotEmpty == true) {
        finalName = '${parsedData.company} 名片';
      } else {
        // 使用時間戳記作為預設名稱
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
        finalName = '名片 #$timestamp';
      }
    }

    return BusinessCard(
      id: const Uuid().v4(),
      name: finalName,
      company: parsedData.company,
      jobTitle: parsedData.jobTitle,
      phone: parsedData.phone ?? parsedData.mobile,
      mobile: parsedData.mobile,
      email: parsedData.email,
      address: parsedData.address,
      website: parsedData.website,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: const [],
      imagePath: state.compressedImagePath,
    );
  }

  /// 壓縮並儲存圖片
  Future<String?> _compressAndSaveImage(Uint8List imageData) async {
    try {
      // 解碼圖片
      final image = img.decodeImage(imageData);
      if (image == null) {
        debugPrint('無法解碼圖片');
        return null;
      }

      // 計算新尺寸（最大 800x600）
      const maxWidth = 800;
      const maxHeight = 600;

      int newWidth = image.width;
      int newHeight = image.height;

      if (image.width > maxWidth || image.height > maxHeight) {
        final widthRatio = image.width / maxWidth;
        final heightRatio = image.height / maxHeight;
        final ratio = widthRatio > heightRatio ? widthRatio : heightRatio;

        newWidth = (image.width / ratio).round();
        newHeight = (image.height / ratio).round();
      }

      // 縮放圖片
      final resized = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // 壓縮為 JPEG（品質 85）
      final compressed = img.encodeJpg(resized, quality: 85);

      // 儲存到文件系統
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${const Uuid().v4()}.jpg';
      final file = File('${directory.path}/card_images/$fileName');

      // 確保目錄存在
      await file.parent.create(recursive: true);

      // 寫入文件
      await file.writeAsBytes(compressed);

      debugPrint('圖片已壓縮並儲存: ${file.path}');
      debugPrint('原始大小: ${imageData.length} bytes');
      debugPrint('壓縮後大小: ${compressed.length} bytes');

      return file.path;
    } on Exception catch (e) {
      debugPrint('壓縮圖片失敗: $e');
      return null;
    }
  }
}

/// OCR Processing ViewModel Provider
final ocrProcessingViewModelProvider =
    StateNotifierProvider<OCRProcessingViewModel, OCRProcessingState>((ref) {
      final processImageUseCase = ref.watch(processImageUseCaseProvider);
      final loadingPresenter = ref.watch(loadingPresenterProvider.notifier);
      final toastPresenter = ref.watch(toastPresenterProvider.notifier);

      // 需要從 data providers 獲取
      final openAIService = ref.watch(openAIServiceProvider);
      final secureStorage = ref.watch(enhancedSecureStorageProvider);

      return OCRProcessingViewModel(
        processImageUseCase,
        loadingPresenter,
        toastPresenter,
        openAIService,
        secureStorage,
      );
    });
