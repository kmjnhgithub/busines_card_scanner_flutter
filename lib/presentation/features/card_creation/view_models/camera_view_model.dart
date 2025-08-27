import 'package:busines_card_scanner_flutter/core/utils/scan_frame_utils.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/process_image_usecase.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/loading_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/toast_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/domain_providers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image/image.dart' as img;

part 'camera_view_model.freezed.dart';

/// 相機狀態
@Freezed(toJson: false, fromJson: false)
class CameraState with _$CameraState {
  const factory CameraState({
    /// 相機控制器
    CameraController? cameraController,

    /// 相機是否已初始化
    @Default(false) bool isInitialized,

    /// 是否正在載入
    @Default(false) bool isLoading,

    /// 錯誤訊息
    String? error,

    /// 拍攝的圖片路徑
    String? capturedImagePath,

    /// 當前閃光燈模式
    @Default(FlashMode.auto) FlashMode flashMode,
  }) = _CameraState;
}

/// 相機ViewModel
///
/// 負責管理相機功能，包括：
/// - 相機初始化和控制
/// - 拍照功能
/// - 閃光燈控制
/// - 焦點控制
/// - 圖片處理
class CameraViewModel extends StateNotifier<CameraState> {
  CameraViewModel(
    this._processImageUseCase,
    this._loadingPresenter,
    this._toastPresenter,
  ) : super(const CameraState());

  final ProcessImageUseCase _processImageUseCase;
  final LoadingPresenter _loadingPresenter;
  final ToastPresenter _toastPresenter;

  /// 初始化相機
  Future<void> initializeCamera(List<CameraDescription> cameras) async {
    if (cameras.isEmpty) {
      _updateError('沒有可用的相機');
      _toastPresenter.showError('沒有可用的相機');
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (controller.value.isInitialized) {
        // 設定初始對焦模式為連續自動對焦
        // iOS 原生相機預設就是連續自動對焦模式
        await controller.setFocusMode(FocusMode.auto);

        state = state.copyWith(
          cameraController: controller,
          isInitialized: true,
          isLoading: false,
        );
      } else {
        _updateError('相機控制器初始化失敗');
      }
    } on CameraException catch (e) {
      _updateError('相機初始化失敗: ${e.description}');
      _toastPresenter.showError('相機初始化失敗');
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      _updateError('相機初始化失敗: $e');
      _toastPresenter.showError('相機初始化失敗');
      state = state.copyWith(isLoading: false);
    }
  }

  /// 拍照
  Future<void> takePicture() async {
    final controller = state.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _updateError('相機尚未初始化，無法拍照');
      _toastPresenter.showError('相機尚未初始化，無法拍照');
      return;
    }

    try {
      _loadingPresenter.show('拍攝中...');

      final image = await controller.takePicture();

      state = state.copyWith(capturedImagePath: image.path, error: null);

      _loadingPresenter.hide();
    } on CameraException catch (e) {
      _loadingPresenter.hide();
      _updateError('拍照失敗: ${e.description}');
      _toastPresenter.showError('拍照失敗: ${e.description}');
    } on Exception catch (e) {
      _loadingPresenter.hide();
      _updateError('拍照失敗: $e');
      _toastPresenter.showError('拍照失敗: $e');
    }
  }

  /// 拍照並自動裁剪（基於掃描框架位置）
  Future<Uint8List?> takePictureWithCrop({
    required Size screenSize,
    required Size previewSize,
  }) async {
    final controller = state.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _updateError('相機尚未初始化，無法拍照');
      _toastPresenter.showError('相機尚未初始化，無法拍照');
      return null;
    }

    try {
      _loadingPresenter.show('拍攝並處理中...');

      // 1. 拍攝照片
      final image = await controller.takePicture();
      final imageBytes = await image.readAsBytes();

      // 2. 執行智慧裁剪
      final croppedImage = await _cropImageWithScanFrame(
        imageBytes,
        screenSize,
        previewSize,
      );

      state = state.copyWith(capturedImagePath: image.path, error: null);
      _loadingPresenter.hide();

      return croppedImage;
    } on CameraException catch (e) {
      _loadingPresenter.hide();
      _updateError('拍照失敗: ${e.description}');
      _toastPresenter.showError('拍照失敗: ${e.description}');
      return null;
    } on Exception catch (e) {
      _loadingPresenter.hide();
      _updateError('拍照失敗: $e');
      _toastPresenter.showError('拍照失敗: $e');
      return null;
    }
  }

  /// 處理圖片
  Future<ProcessImageResult> processImage(Uint8List imageData) async {
    try {
      _loadingPresenter.show('處理圖片中...');

      final params = ProcessImageParams(imageData: imageData);
      final result = await _processImageUseCase.execute(params);

      _loadingPresenter.hide();
      return result;
    } on Exception catch (e) {
      _loadingPresenter.hide();
      _toastPresenter.showError('圖片處理失敗: $e');
      rethrow;
    }
  }

  /// 切換閃光燈模式
  Future<void> toggleFlashMode() async {
    final controller = state.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _toastPresenter.showError('相機尚未初始化');
      return;
    }

    try {
      FlashMode newMode;
      switch (state.flashMode) {
        case FlashMode.auto:
          newMode = FlashMode.torch;
          break;
        case FlashMode.torch:
          newMode = FlashMode.off;
          break;
        case FlashMode.off:
          newMode = FlashMode.auto;
          break;
        default:
          newMode = FlashMode.auto;
      }

      await controller.setFlashMode(newMode);
      state = state.copyWith(flashMode: newMode);
    } on Exception catch (e) {
      _toastPresenter.showError('切換閃光燈失敗: $e');
    }
  }

  /// 設定焦點點（使用者手動點擊時）
  Future<void> setFocusPoint(Offset point) async {
    final controller = state.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      // 設定焦點和曝光點
      await controller.setFocusPoint(point);
      await controller.setExposurePoint(point);

      // iOS 會自動在幾秒後恢復連續自動對焦
      // 不需要手動管理計時器
    } on CameraException catch (e) {
      // 如果 setFocusPoint 不支援，回退到原生自動對焦
      if (e.code == 'setFocusPointFailed') {}
    } on Exception {
      // Camera disposal failed - continue silently
    }
  }

  /// 重設狀態
  void resetState() {
    state = state.copyWith(
      capturedImagePath: null,
      error: null,
      isLoading: false,
    );
  }

  /// 清理資源
  @override
  void dispose() {
    // 先儲存相機控制器的參考
    final controller = state.cameraController;

    // 先呼叫父類別的 dispose（這會讓 state 無法存取）
    super.dispose();

    // 然後安全地清理相機控制器
    // 這時不會再存取 state，只使用之前儲存的參考
    try {
      controller?.dispose();
    } on Exception {
      // Camera disposal failed - continue silently
    }
  }

  /// 更新錯誤狀態
  void _updateError(String error) {
    state = state.copyWith(error: error);
  }

  /// 根據掃描框架自動裁剪圖片
  Future<Uint8List> _cropImageWithScanFrame(
    Uint8List imageData,
    Size screenSize,
    Size previewSize,
  ) async {
    try {
      // 1. 解碼圖片
      final image = img.decodeImage(imageData);
      if (image == null) {
        return imageData; // 返回原圖
      }

      // 2. 使用統一的掃描框計算邏輯
      final scanFrame = ScanFrameUtils.calculateScanFrame(screenSize);

      // 3. 將螢幕座標轉換為圖片座標
      final cropRect = _convertScreenCropToImageCrop(
        screenFrame: scanFrame,
        screenSize: screenSize,
        imageSize: Size(image.width.toDouble(), image.height.toDouble()),
      );

      // 4. 執行裁剪
      final cropped = img.copyCrop(
        image,
        x: cropRect.left.toInt(),
        y: cropRect.top.toInt(),
        width: cropRect.width.toInt(),
        height: cropRect.height.toInt(),
      );

      // 5. 編碼為 JPEG
      final croppedBytes = Uint8List.fromList(
        img.encodeJpg(cropped, quality: 90),
      );

      return croppedBytes;
    } on Exception {
      return imageData; // 裁剪失敗時返回原圖
    }
  }

  /// 直接映射：螢幕掃描框位置 → 照片裁剪位置
  Rect _convertScreenCropToImageCrop({
    required Rect screenFrame,
    required Size screenSize,
    required Size imageSize,
  }) {
    // 計算縮放比例
    final scaleX = imageSize.width / screenSize.width;
    final scaleY = imageSize.height / screenSize.height;

    // 直接按比例映射
    final imageLeft = screenFrame.left * scaleX;
    final imageTop = screenFrame.top * scaleY;
    final imageWidth = screenFrame.width * scaleX;
    final imageHeight = screenFrame.height * scaleY;

    return Rect.fromLTWH(imageLeft, imageTop, imageWidth, imageHeight);
  }
}

/// Camera ViewModel Provider
/// 使用 autoDispose 確保頁面離開時釋放資源
final cameraViewModelProvider =
    StateNotifierProvider.autoDispose<CameraViewModel, CameraState>((ref) {
      final processImageUseCase = ref.watch(processImageUseCaseProvider);
      final loadingPresenter = ref.watch(loadingPresenterProvider.notifier);
      final toastPresenter = ref.watch(toastPresenterProvider.notifier);

      final viewModel = CameraViewModel(
        processImageUseCase,
        loadingPresenter,
        toastPresenter,
      );

      // Riverpod 會自動呼叫 StateNotifier 的 dispose
      // 不需要手動呼叫
      ref.onDispose(() {});

      return viewModel;
    });
