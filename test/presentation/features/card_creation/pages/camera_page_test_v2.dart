import 'package:busines_card_scanner_flutter/domain/usecases/card/process_image_usecase.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_creation/pages/camera_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_creation/view_models/camera_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/loading_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/toast_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/domain_providers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_helpers.dart';

// Mock 類別
class MockCameraViewModel extends Mock implements CameraViewModel {}

class MockLoadingPresenter extends Mock implements LoadingPresenter {}

class MockToastPresenter extends Mock implements ToastPresenter {}

class MockProcessImageUseCase extends Mock implements ProcessImageUseCase {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    suppressDatabaseWarnings();
    registerCommonFallbackValues();
  });

  group('CameraPage Widget Tests - Clean Architecture Strategy', () {
    late MockCameraViewModel mockCameraViewModel;
    late MockLoadingPresenter mockLoadingPresenter;
    late MockToastPresenter mockToastPresenter;
    late ProviderContainer container;

    setUp(() {
      mockCameraViewModel = MockCameraViewModel();
      mockLoadingPresenter = MockLoadingPresenter();
      mockToastPresenter = MockToastPresenter();

      container = TestHelpers.createTestContainer(
        overrides: [
          // 直接覆寫 ViewModel，避免 CameraController 依賴
          cameraViewModelProvider.overrideWith((ref) => mockCameraViewModel),
          loadingPresenterProvider.overrideWith((ref) => mockLoadingPresenter),
          toastPresenterProvider.overrideWith((ref) => mockToastPresenter),
          processImageUseCaseProvider.overrideWith(
            (ref) => MockProcessImageUseCase(),
          ),
        ],
      );
    });

    tearDown(() {
      TestHelpers.disposeContainer(container);
    });

    Widget createTestWidget({CameraState? state}) {
      if (state != null) {
        mockCameraViewModel.state = state;
      }

      return TestHelpers.createTestWidget(
        container: container,
        child: const CameraPage(),
        routes: {
          '/ocr-processing': (context) =>
              const Scaffold(body: Text('OCR Page')),
          '/card-edit': (context) => const Scaffold(body: Text('Edit Page')),
        },
      );
    }

    group('UI 狀態顯示測試', () {
      testWidgets('初始載入狀態應該顯示載入指示器', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = const CameraState(isLoading: true);

        // Act
        await tester.pumpWidget(createTestWidget());
        await TestHelpers.testLoadingState(tester);

        // Assert - 測試載入狀態 UI
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
        expect(find.text('相機初始化中...'), findsOneWidget);
      });

      testWidgets('相機初始化後應該顯示相機控制按鈕', (WidgetTester tester) async {
        // Arrange - 模擬相機已初始化狀態
        mockCameraViewModel.state = const CameraState(isInitialized: true);

        // Act
        await tester.pumpWidget(createTestWidget());
        await TestHelpers.testLoadingState(tester);

        // Assert - 檢查相機控制按鈕是否存在
        expect(find.byKey(const Key('camera_shutter_button')), findsOneWidget);
        expect(find.byKey(const Key('flash_toggle_button')), findsOneWidget);
        expect(find.byKey(const Key('photo_library_button')), findsOneWidget);
        expect(find.byKey(const Key('close_camera_button')), findsOneWidget);
      });

      testWidgets('錯誤狀態應該顯示錯誤訊息和重試按鈕', (WidgetTester tester) async {
        // Arrange
        const errorMessage = '相機初始化失敗';
        mockCameraViewModel.state = const CameraState(error: errorMessage);

        // Act
        await tester.pumpWidget(createTestWidget());
        await TestHelpers.testLoadingState(tester);

        // Assert
        expect(find.text('相機錯誤'), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.text('重試'), findsOneWidget);
      });

      testWidgets('應該顯示相機掃描框架和提示文字', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = const CameraState(isInitialized: true);

        // Act
        await tester.pumpWidget(createTestWidget());
        await TestHelpers.testLoadingState(tester);

        // Assert - 檢查掃描相關 UI 元素
        expect(find.byKey(const Key('camera_overlay')), findsOneWidget);
        expect(find.text('將名片放入框內'), findsOneWidget);
      });
    });

    group('使用者互動測試', () {
      testWidgets('點擊拍照按鈕應該調用 ViewModel takePicture', (
        WidgetTester tester,
      ) async {
        // Arrange
        mockCameraViewModel.state = const CameraState(isInitialized: true);

        // Act
        await tester.pumpWidget(createTestWidget());
        await TestHelpers.testLoadingState(tester);

        await tester.tap(find.byKey(const Key('camera_shutter_button')));
        await tester.pump();

        // Assert
        verify(() => mockCameraViewModel.takePicture()).called(1);
      });

      testWidgets('點擊閃光燈按鈕應該調用 ViewModel toggleFlashMode', (
        WidgetTester tester,
      ) async {
        // Arrange
        mockCameraViewModel.state = const CameraState(isInitialized: true);

        // Act
        await tester.pumpWidget(createTestWidget());
        await TestHelpers.testLoadingState(tester);

        await tester.tap(find.byKey(const Key('flash_toggle_button')));
        await tester.pump();

        // Assert
        verify(() => mockCameraViewModel.toggleFlashMode()).called(1);
      });

      testWidgets('錯誤狀態下點擊重試按鈕應該重新初始化相機', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = const CameraState(error: '相機錯誤');

        // Act
        await tester.pumpWidget(createTestWidget());
        await TestHelpers.testLoadingState(tester);

        await tester.tap(find.text('重試'));
        await tester.pump();

        // Assert
        verify(() => mockCameraViewModel.initializeCamera(any())).called(1);
      });
    });

    group('閃光燈狀態測試', () {
      testWidgets('閃光燈模式變化應該更新圖示', (WidgetTester tester) async {
        // Arrange - auto 模式
        mockCameraViewModel.state = const CameraState(isInitialized: true);

        // Act
        await tester.pumpWidget(createTestWidget());
        await TestHelpers.testLoadingState(tester);

        // Assert - 應該顯示 auto 圖示
        expect(find.byIcon(Icons.flash_auto), findsOneWidget);

        // Arrange - 更新為 torch 模式
        mockCameraViewModel.state = const CameraState(
          isInitialized: true,
          flashMode: FlashMode.torch,
        );

        // Act
        await tester.pump();

        // Assert - 應該顯示 torch 圖示
        expect(find.byIcon(Icons.flash_on), findsOneWidget);

        // Arrange - 更新為 off 模式
        mockCameraViewModel.state = const CameraState(
          isInitialized: true,
          flashMode: FlashMode.off,
        );

        // Act
        await tester.pump();

        // Assert - 應該顯示 off 圖示
        expect(find.byIcon(Icons.flash_off), findsOneWidget);
      });
    });

    group('狀態變化測試', () {
      testWidgets('載入狀態變化應該正確更新 UI', (WidgetTester tester) async {
        // Arrange - 初始載入狀態
        mockCameraViewModel.state = const CameraState(isLoading: true);

        // Act
        await tester.pumpWidget(createTestWidget());
        await TestHelpers.testLoadingState(tester);

        // Assert - 應該顯示載入中
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

        // Arrange - 更新為已初始化狀態
        mockCameraViewModel.state = const CameraState(isInitialized: true);

        // Act - 觸發重建
        await tester.pump();

        // Assert - 應該顯示相機控制按鈕
        expect(find.byKey(const Key('camera_shutter_button')), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('拍照成功後狀態更新', (WidgetTester tester) async {
        // Arrange
        const imagePath = '/test/path/image.jpg';
        mockCameraViewModel.state = const CameraState(
          isInitialized: true,
          capturedImagePath: imagePath,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await TestHelpers.testLoadingState(tester);

        // Assert - 驗證狀態包含圖片路徑
        final state = container.read(cameraViewModelProvider);
        expect(state.capturedImagePath, equals(imagePath));
      });
    });

    group('無障礙測試', () {
      testWidgets('按鈕應該有正確的語義標籤', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = const CameraState(isInitialized: true);

        // Act
        await tester.pumpWidget(createTestWidget());
        await TestHelpers.testLoadingState(tester);

        // Assert
        expect(find.bySemanticsLabel('拍照'), findsOneWidget);
        expect(find.bySemanticsLabel('切換閃光燈'), findsOneWidget);
        expect(find.bySemanticsLabel('從相簿選擇'), findsOneWidget);
        expect(find.bySemanticsLabel('關閉相機'), findsOneWidget);
      });

      testWidgets('應該提供適當的語音提示', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = const CameraState(isInitialized: true);

        // Act
        await tester.pumpWidget(createTestWidget());
        await TestHelpers.testLoadingState(tester);

        // Assert
        expect(find.text('將名片放入框內'), findsOneWidget);
      });
    });

    group('Provider 狀態同步測試', () {
      testWidgets('ViewModel 狀態應該與 Provider 同步', (WidgetTester tester) async {
        // Arrange
        const testState = CameraState(
          isInitialized: true,
          flashMode: FlashMode.torch,
        );
        mockCameraViewModel.state = testState;

        // Act
        await tester.pumpWidget(createTestWidget());
        await TestHelpers.testLoadingState(tester);

        // Assert - 驗證 Provider 狀態
        final providerState = container.read(cameraViewModelProvider);
        expect(providerState.isInitialized, equals(testState.isInitialized));
        expect(providerState.isLoading, equals(testState.isLoading));
        expect(providerState.flashMode, equals(testState.flashMode));
      });
    });
  });
}
