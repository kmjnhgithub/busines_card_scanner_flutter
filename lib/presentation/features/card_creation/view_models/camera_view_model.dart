import 'package:busines_card_scanner_flutter/domain/usecases/card/process_image_usecase.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/loading_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/toast_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/domain_providers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
    debugPrint('CameraViewModel: 開始初始化相機，相機數量: ${cameras.length}');

    if (cameras.isEmpty) {
      _updateError('沒有可用的相機');
      _toastPresenter.showError('沒有可用的相機');
      return;
    }

    try {
      debugPrint('CameraViewModel: 設定載入狀態');
      state = state.copyWith(isLoading: true, error: null);

      debugPrint('CameraViewModel: 創建 CameraController');
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      debugPrint('CameraViewModel: 初始化 CameraController');
      await controller.initialize();

      debugPrint(
        'CameraViewModel: 控制器初始化狀態: ${controller.value.isInitialized}',
      );

      if (controller.value.isInitialized) {
        debugPrint('CameraViewModel: 更新狀態 - 相機已初始化');

        // 設定初始對焦模式為連續自動對焦
        // iOS 原生相機預設就是連續自動對焦模式
        await controller.setFocusMode(FocusMode.auto);
        debugPrint('CameraViewModel: 設定對焦模式為自動（iOS 原生連續對焦）');

        state = state.copyWith(
          cameraController: controller,
          isInitialized: true,
          isLoading: false,
        );
        debugPrint(
          'CameraViewModel: 狀態更新完成 - isInitialized: ${state.isInitialized}, hasController: ${state.cameraController != null}',
        );

        debugPrint('CameraViewModel: 使用原生連續自動對焦模式');
      } else {
        debugPrint('CameraViewModel: 控制器初始化失敗 - isInitialized 為 false');
        _updateError('相機控制器初始化失敗');
      }
    } on CameraException catch (e) {
      debugPrint(
        'CameraViewModel: CameraException - ${e.code}: ${e.description}',
      );
      _updateError('相機初始化失敗: ${e.description}');
      _toastPresenter.showError('相機初始化失敗');
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      debugPrint('CameraViewModel: Exception - $e');
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

      debugPrint('手動對焦點設定: $point');

      // iOS 會自動在幾秒後恢復連續自動對焦
      // 不需要手動管理計時器
    } on CameraException catch (e) {
      debugPrint('相機對焦錯誤 - ${e.code}: ${e.description}');
      // 如果 setFocusPoint 不支援，回退到原生自動對焦
      if (e.code == 'setFocusPointFailed') {
        debugPrint('此設備不支援手動對焦點設定，使用原生自動對焦');
      }
    } on Exception catch (e) {
      debugPrint('設定焦點失敗: $e');
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
    } on Exception catch (e) {
      debugPrint('Camera controller dispose error: $e');
    }
  }

  /// 更新錯誤狀態
  void _updateError(String error) {
    state = state.copyWith(error: error);
  }
}

/// Camera ViewModel Provider
/// 使用 autoDispose 確保頁面離開時釋放資源
final cameraViewModelProvider =
    StateNotifierProvider.autoDispose<CameraViewModel, CameraState>((ref) {
      debugPrint('Creating new CameraViewModel instance');

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
      ref.onDispose(() {
        debugPrint('CameraViewModel provider being disposed');
      });

      return viewModel;
    });
