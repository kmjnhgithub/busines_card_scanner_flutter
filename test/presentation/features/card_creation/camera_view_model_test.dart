
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/process_image_usecase.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_creation/view_models/camera_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/loading_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/toast_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/domain_providers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock 類別
class MockProcessImageUseCase extends Mock implements ProcessImageUseCase {}

class MockLoadingPresenter extends Mock implements LoadingPresenter {}

class MockToastPresenter extends Mock implements ToastPresenter {}

class MockCameraController extends Mock implements CameraController {}

class MockXFile extends Mock implements XFile {}

void main() {
  group('CameraViewModel Tests', () {
    late MockProcessImageUseCase mockProcessImageUseCase;
    late MockLoadingPresenter mockLoadingPresenter;
    late MockToastPresenter mockToastPresenter;
    late MockCameraController mockCameraController;
    late ProviderContainer container;

    // 測試資料
    final testImageData = Uint8List.fromList([1, 2, 3, 4, 5]);
    const testImagePath = '/test/path/image.jpg';
    const mockCameraDescription = CameraDescription(
      name: 'mock_camera',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 0,
    );

    setUp(() {
      mockProcessImageUseCase = MockProcessImageUseCase();
      mockLoadingPresenter = MockLoadingPresenter();
      mockToastPresenter = MockToastPresenter();
      mockCameraController = MockCameraController();

      // 設定 fallback values
      registerFallbackValue(
        ProcessImageParams(imageData: Uint8List.fromList([1, 2, 3])),
      );

      container = ProviderContainer(
        overrides: [
          processImageUseCaseProvider.overrideWithValue(
            mockProcessImageUseCase,
          ),
          loadingPresenterProvider.overrideWith((ref) => mockLoadingPresenter),
          toastPresenterProvider.overrideWith((ref) => mockToastPresenter),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('相機初始化', () {
      test('初始狀態應該正確設定', () {
        final state = container.read(cameraViewModelProvider);

        expect(state.cameraController, isNull);
        expect(state.isInitialized, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
        expect(state.capturedImagePath, isNull);
      });

      test('初始化相機成功時應該更新狀態', () async {
        // Arrange
        when(
          () => mockCameraController.initialize(),
        ).thenAnswer((_) async => Future.value());
        when(() => mockCameraController.value).thenReturn(
          const CameraValue(
            isInitialized: true,
            isRecordingVideo: false,
            isRecordingPaused: false,
            isTakingPicture: false,
            isStreamingImages: false,
            flashMode: FlashMode.auto,
            exposureMode: ExposureMode.auto,
            focusMode: FocusMode.auto,
            exposurePointSupported: false,
            focusPointSupported: false,
            deviceOrientation: DeviceOrientation.portraitUp,
            description: mockCameraDescription,
          ),
        );

        // Act
        final viewModel = container.read(cameraViewModelProvider.notifier);
        await viewModel.initializeCamera([]);

        // Assert
        final state = container.read(cameraViewModelProvider);
        expect(state.isInitialized, isTrue);
        expect(state.error, isNull);
      });

      test('初始化相機失敗時應該設定錯誤狀態', () async {
        // Arrange
        const errorMessage = '相機初始化失敗';
        when(
          () => mockCameraController.initialize(),
        ).thenThrow(CameraException('camera_error', errorMessage));

        // Act
        final viewModel = container.read(cameraViewModelProvider.notifier);
        await viewModel.initializeCamera([]);

        // Assert
        final state = container.read(cameraViewModelProvider);
        expect(state.isInitialized, isFalse);
        expect(state.error, contains('相機初始化失敗'));
        verify(() => mockToastPresenter.showError('相機初始化失敗')).called(1);
      });

      test('沒有可用相機時應該設定錯誤', () async {
        // Act
        final viewModel = container.read(cameraViewModelProvider.notifier);
        await viewModel.initializeCamera([]);

        // Assert
        final state = container.read(cameraViewModelProvider);
        expect(state.error, contains('沒有可用的相機'));
        verify(() => mockToastPresenter.showError('沒有可用的相機')).called(1);
      });
    });

    group('拍照功能', () {
      test('拍照成功時應該更新狀態', () async {
        // Arrange
        final mockXFile = MockXFile();
        when(() => mockXFile.path).thenReturn(testImagePath);
        when(
          mockXFile.readAsBytes,
        ).thenAnswer((_) async => testImageData);
        when(
          () => mockCameraController.takePicture(),
        ).thenAnswer((_) async => mockXFile);
        when(() => mockCameraController.value).thenReturn(
          const CameraValue(
            isInitialized: true,
            isRecordingVideo: false,
            isRecordingPaused: false,
            isTakingPicture: false,
            isStreamingImages: false,
            flashMode: FlashMode.auto,
            exposureMode: ExposureMode.auto,
            focusMode: FocusMode.auto,
            exposurePointSupported: false,
            focusPointSupported: false,
            deviceOrientation: DeviceOrientation.portraitUp,
            description: mockCameraDescription,
          ),
        );

        // Act
        final viewModel = container.read(cameraViewModelProvider.notifier);
        await viewModel.takePicture();

        // Assert
        final state = container.read(cameraViewModelProvider);
        expect(state.capturedImagePath, equals(testImagePath));
        expect(state.error, isNull);
        verify(() => mockLoadingPresenter.show('拍攝中...')).called(1);
        verify(() => mockLoadingPresenter.hide()).called(1);
      });

      test('相機未初始化時拍照應該顯示錯誤', () async {
        // Act
        final viewModel = container.read(cameraViewModelProvider.notifier);
        await viewModel.takePicture();

        // Assert
        final state = container.read(cameraViewModelProvider);
        expect(state.capturedImagePath, isNull);
        expect(state.error, contains('相機尚未初始化'));
        verify(() => mockToastPresenter.showError('相機尚未初始化，無法拍照')).called(1);
      });

      test('拍照失敗時應該設定錯誤狀態', () async {
        // Arrange
        when(() => mockCameraController.value).thenReturn(
          const CameraValue(
            isInitialized: true,
            isRecordingVideo: false,
            isRecordingPaused: false,
            isTakingPicture: false,
            isStreamingImages: false,
            flashMode: FlashMode.auto,
            exposureMode: ExposureMode.auto,
            focusMode: FocusMode.auto,
            exposurePointSupported: false,
            focusPointSupported: false,
            deviceOrientation: DeviceOrientation.portraitUp,
            description: mockCameraDescription,
          ),
        );
        when(
          () => mockCameraController.takePicture(),
        ).thenThrow(CameraException('take_picture_error', '拍照失敗'));

        // Act
        final viewModel = container.read(cameraViewModelProvider.notifier);
        await viewModel.takePicture();

        // Assert
        final state = container.read(cameraViewModelProvider);
        expect(state.capturedImagePath, isNull);
        expect(state.error, contains('拍照失敗'));
        verify(() => mockLoadingPresenter.hide()).called(1);
        verify(
          () => mockToastPresenter.showError(any(that: contains('拍照失敗'))),
        ).called(1);
      });
    });

    group('圖片處理', () {
      test('處理圖片成功時應該回傳結果', () async {
        // Arrange
        // 需要先創建一個 mock OCRResult
        final mockOCRResult = OCRResult(
          id: 'test-id',
          rawText: 'test text',
          confidence: 0.9,
          processedAt: DateTime.now(),
        );

        final mockResult = ProcessImageResult(
          isSuccess: true,
          ocrResult: mockOCRResult,
          processingSteps: ['OCR 處理完成'],
          warnings: [],
        );
        when(
          () => mockProcessImageUseCase.execute(any()),
        ).thenAnswer((_) async => mockResult);

        // Act
        final viewModel = container.read(cameraViewModelProvider.notifier);
        final result = await viewModel.processImage(testImageData);

        // Assert
        expect(result, equals(mockResult));
        verify(() => mockLoadingPresenter.show('處理圖片中...')).called(1);
        verify(() => mockLoadingPresenter.hide()).called(1);
        verify(() => mockProcessImageUseCase.execute(any())).called(1);
      });

      test('處理圖片失敗時應該拋出例外並顯示錯誤', () async {
        // Arrange
        const errorMessage = 'OCR 處理失敗';
        when(
          () => mockProcessImageUseCase.execute(any()),
        ).thenThrow(Exception(errorMessage));

        // Act & Assert
        final viewModel = container.read(cameraViewModelProvider.notifier);
        await expectLater(
          () => viewModel.processImage(testImageData),
          throwsException,
        );

        verify(() => mockLoadingPresenter.hide()).called(1);
        verify(
          () => mockToastPresenter.showError(any(that: contains('圖片處理失敗'))),
        ).called(1);
      });
    });

    group('閃光燈控制', () {
      test('切換閃光燈模式應該更新狀態', () async {
        // Arrange
        when(() => mockCameraController.value).thenReturn(
          const CameraValue(
            isInitialized: true,
            isRecordingVideo: false,
            isRecordingPaused: false,
            isTakingPicture: false,
            isStreamingImages: false,
            flashMode: FlashMode.auto,
            exposureMode: ExposureMode.auto,
            focusMode: FocusMode.auto,
            exposurePointSupported: false,
            focusPointSupported: false,
            deviceOrientation: DeviceOrientation.portraitUp,
            description: mockCameraDescription,
          ),
        );
        when(
          () => mockCameraController.setFlashMode(any()),
        ).thenAnswer((_) async => Future.value());

        // Act
        final viewModel = container.read(cameraViewModelProvider.notifier);
        await viewModel.toggleFlashMode();

        // Assert
        verify(
          () => mockCameraController.setFlashMode(FlashMode.torch),
        ).called(1);
      });

      test('相機未初始化時切換閃光燈應該顯示錯誤', () async {
        // Act
        final viewModel = container.read(cameraViewModelProvider.notifier);
        await viewModel.toggleFlashMode();

        // Assert
        verify(() => mockToastPresenter.showError('相機尚未初始化')).called(1);
      });
    });

    group('資源清理', () {
      test('dispose 時應該清理相機控制器', () {
        // Arrange
        when(
          () => mockCameraController.dispose(),
        ).thenAnswer((_) async => Future.value());

        // Act
        final viewModel = container.read(cameraViewModelProvider.notifier);
        viewModel.dispose();

        // Assert
        verify(() => mockCameraController.dispose()).called(1);
      });

      test('重設狀態應該清除所有資料', () {
        // Act
        final viewModel = container.read(cameraViewModelProvider.notifier);
        viewModel.resetState();

        // Assert
        final state = container.read(cameraViewModelProvider);
        expect(state.capturedImagePath, isNull);
        expect(state.error, isNull);
        expect(state.isLoading, isFalse);
      });
    });

    group('焦點控制', () {
      test('設定焦點應該更新相機控制器', () async {
        // Arrange
        const offset = Offset(0.5, 0.5);
        when(() => mockCameraController.value).thenReturn(
          const CameraValue(
            isInitialized: true,
            isRecordingVideo: false,
            isRecordingPaused: false,
            isTakingPicture: false,
            isStreamingImages: false,
            flashMode: FlashMode.auto,
            exposureMode: ExposureMode.auto,
            focusMode: FocusMode.auto,
            exposurePointSupported: true,
            focusPointSupported: true,
            deviceOrientation: DeviceOrientation.portraitUp,
            description: mockCameraDescription,
          ),
        );
        when(
          () => mockCameraController.setFocusPoint(any()),
        ).thenAnswer((_) async => Future.value());

        // Act
        final viewModel = container.read(cameraViewModelProvider.notifier);
        await viewModel.setFocusPoint(offset);

        // Assert
        verify(() => mockCameraController.setFocusPoint(offset)).called(1);
      });
    });
  });
}
