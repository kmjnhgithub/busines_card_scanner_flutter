import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/create_card_from_image_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/create_card_from_ocr_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/process_image_usecase.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/loading_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/toast_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/domain_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
/// - AI解析和結構化
/// - 編輯和重新解析功能
/// - 完整的錯誤處理
class OCRProcessingViewModel extends StateNotifier<OCRProcessingState> {
  OCRProcessingViewModel(
    this._processImageUseCase,
    this._createCardFromImageUseCase,
    this._createCardFromOCRUseCase,
    this._loadingPresenter,
    this._toastPresenter,
  ) : super(const OCRProcessingState());

  final ProcessImageUseCase _processImageUseCase;
  final CreateCardFromImageUseCase _createCardFromImageUseCase;
  final CreateCardFromOCRUseCase _createCardFromOCRUseCase;
  final LoadingPresenter _loadingPresenter;
  final ToastPresenter _toastPresenter;

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

  /// AI 解析 OCR 文字
  Future<void> parseWithAI() async {
    if (state.ocrResult == null) {
      _updateError('請先完成 OCR 處理');
      _toastPresenter.showError('請先完成 OCR 處理');
      return;
    }

    try {
      _loadingPresenter.show('AI 正在解析名片資訊...');
      _updateProcessingStep(OCRProcessingStep.aiProcessing);

      final params = CreateCardFromOCRParams(ocrResult: state.ocrResult!);
      final result = await _createCardFromOCRUseCase.execute(params);

      state = state.copyWith(
        parsedCard: result.card,
        processingStep: OCRProcessingStep.completed,
        warnings: [...state.warnings, ...result.warnings],
        error: null,
      );

      _loadingPresenter.hide();
    } on Exception catch (e) {
      _loadingPresenter.hide();
      _updateError('AI 解析失敗: $e');
      _toastPresenter.showError('AI 解析失敗: $e');
      state = state.copyWith(processingStep: OCRProcessingStep.ocrCompleted);
    }
  }

  /// 完整的圖片到名片處理流程
  Future<void> processImageToCard(Uint8List imageData) async {
    try {
      _loadingPresenter.show('正在處理名片...');
      state = state.copyWith(
        imageData: imageData,
        processingStep: OCRProcessingStep.ocrProcessing,
        error: null,
      );

      final params = CreateCardFromImageParams(imageData: imageData);
      final result = await _createCardFromImageUseCase.execute(params);

      state = state.copyWith(
        ocrResult: result.ocrResult,
        parsedCard: result.card,
        processingStep: OCRProcessingStep.completed,
        confidence: result.ocrResult.confidence,
        warnings: result.warnings,
        error: null,
      );

      _loadingPresenter.hide();
      _toastPresenter.showSuccess('名片處理完成！');
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
}

/// OCR Processing ViewModel Provider
final ocrProcessingViewModelProvider =
    StateNotifierProvider<OCRProcessingViewModel, OCRProcessingState>((ref) {
      final processImageUseCase = ref.watch(processImageUseCaseProvider);
      final createCardFromImageUseCase = ref.watch(
        createCardFromImageUseCaseProvider,
      );
      final createCardFromOCRUseCase = ref.watch(
        createCardFromOCRUseCaseProvider,
      );
      final loadingPresenter = ref.watch(loadingPresenterProvider.notifier);
      final toastPresenter = ref.watch(toastPresenterProvider.notifier);

      return OCRProcessingViewModel(
        processImageUseCase,
        createCardFromImageUseCase,
        createCardFromOCRUseCase,
        loadingPresenter,
        toastPresenter,
      );
    });
