
import 'package:busines_card_scanner_flutter/presentation/features/card_creation/pages/camera_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_creation/view_models/camera_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/loading_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/toast_presenter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock 類別
class MockCameraViewModel extends StateNotifier<CameraState>
    with Mock
    implements CameraViewModel {
  MockCameraViewModel() : super(const CameraState());
}

class MockLoadingPresenter extends Mock implements LoadingPresenter {}

class MockToastPresenter extends Mock implements ToastPresenter {}

class MockCameraController extends Mock implements CameraController {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  group('CameraPage Widget Tests', () {
    late MockCameraViewModel mockCameraViewModel;
    late MockLoadingPresenter mockLoadingPresenter;
    late MockToastPresenter mockToastPresenter;
    late MockCameraController mockCameraController;
    late MockNavigatorObserver mockNavigatorObserver;

    // 測試資料
    const mockCameraDescription = CameraDescription(
      name: 'test_camera',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 0,
    );

    setUp(() {
      mockCameraViewModel = MockCameraViewModel();
      mockLoadingPresenter = MockLoadingPresenter();
      mockToastPresenter = MockToastPresenter();
      mockCameraController = MockCameraController();
      mockNavigatorObserver = MockNavigatorObserver();

      // 設定基本的相機控制器 value
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
    });

    Widget createTestWidget({CameraState? state}) {
      return ProviderScope(
        overrides: [
          cameraViewModelProvider.overrideWith((ref) => mockCameraViewModel),
          loadingPresenterProvider.overrideWith((ref) => mockLoadingPresenter),
          toastPresenterProvider.overrideWith((ref) => mockToastPresenter),
        ],
        child: MaterialApp(
          home: const CameraPage(),
          navigatorObservers: [mockNavigatorObserver],
        ),
      );
    }

    group('UI 顯示測試', () {
      testWidgets('初始狀態下應該顯示載入中', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = const CameraState(isLoading: true);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('相機初始化中...'), findsOneWidget);
      });

      testWidgets('相機初始化後應該顯示相機預覽', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byType(CameraPreview), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('應該顯示拍照按鈕和控制按鈕', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byKey(const Key('camera_shutter_button')), findsOneWidget);
        expect(find.byKey(const Key('flash_toggle_button')), findsOneWidget);
        expect(find.byKey(const Key('photo_library_button')), findsOneWidget);
        expect(find.byKey(const Key('close_camera_button')), findsOneWidget);
      });

      testWidgets('錯誤狀態時應該顯示錯誤訊息', (WidgetTester tester) async {
        // Arrange
        const errorMessage = '相機初始化失敗';
        mockCameraViewModel.state = const CameraState(
          error: errorMessage,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('相機錯誤'), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.text('重試'), findsOneWidget);
      });

      testWidgets('應該顯示掃描框架', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byKey(const Key('camera_overlay')), findsOneWidget);
        expect(find.text('將名片放入框內'), findsOneWidget);
      });

      testWidgets('閃光燈按鈕應該顯示正確的圖示', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        final flashButton = find.byKey(const Key('flash_toggle_button'));
        expect(flashButton, findsOneWidget);

        // 檢查是否有閃光燈圖示
        expect(
          find.descendant(
            of: flashButton,
            matching: find.byIcon(Icons.flash_auto),
          ),
          findsOneWidget,
        );
      });
    });

    group('使用者互動測試', () {
      testWidgets('點擊拍照按鈕應該觸發拍照', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.byKey(const Key('camera_shutter_button')));
        await tester.pump();

        // Assert
        verify(() => mockCameraViewModel.takePicture()).called(1);
      });

      testWidgets('點擊閃光燈按鈕應該切換閃光燈模式', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.byKey(const Key('flash_toggle_button')));
        await tester.pump();

        // Assert
        verify(() => mockCameraViewModel.toggleFlashMode()).called(1);
      });

      testWidgets('點擊相簿按鈕應該開啟相簿', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.byKey(const Key('photo_library_button')));
        await tester.pump();

        // Assert
        // 這裡會檢查是否調用了相簿選擇功能
        // 實際實作中會有相簿選擇的回調
      });

      testWidgets('點擊關閉按鈕應該返回上一頁', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.byKey(const Key('close_camera_button')));
        await tester.pump();

        // Assert
        // 檢查導航是否被調用
        verify(() => mockNavigatorObserver.didPop(any(), any()));
      });

      testWidgets('點擊相機預覽應該設定焦點', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // 點擊相機預覽的中心
        await tester.tap(find.byType(CameraPreview));
        await tester.pump();

        // Assert
        verify(() => mockCameraViewModel.setFocusPoint(any())).called(1);
      });

      testWidgets('錯誤狀態下點擊重試按鈕應該重新初始化', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = const CameraState(
          error: '相機錯誤',
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.text('重試'));
        await tester.pump();

        // Assert
        verify(() => mockCameraViewModel.initializeCamera(any())).called(1);
      });
    });

    group('狀態變化測試', () {
      testWidgets('拍照成功後應該導航到下一頁', (WidgetTester tester) async {
        // Arrange
        const imagePath = '/test/path/image.jpg';
        mockCameraViewModel.state = const CameraState(
          isInitialized: true,
          capturedImagePath: imagePath,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        // 這裡應該檢查導航到 OCR 處理頁面
        // 實際實作中會有導航邏輯
      });

      testWidgets('載入狀態變化應該正確顯示', (WidgetTester tester) async {
        // Arrange - 初始載入狀態
        mockCameraViewModel.state = const CameraState(isLoading: true);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert - 應該顯示載入中
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Arrange - 更新為已初始化狀態
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
        );

        // Act - 觸發重建
        await tester.pump();

        // Assert - 應該顯示相機預覽
        expect(find.byType(CameraPreview), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('閃光燈模式變化應該更新圖示', (WidgetTester tester) async {
        // Arrange - torch 模式
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
          flashMode: FlashMode.torch,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert - 應該顯示 torch 圖示
        expect(find.byIcon(Icons.flash_on), findsOneWidget);

        // Arrange - 更新為 off 模式
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
          flashMode: FlashMode.off,
        );

        // Act
        await tester.pump();

        // Assert - 應該顯示 off 圖示
        expect(find.byIcon(Icons.flash_off), findsOneWidget);
      });
    });

    group('權限和生命週期測試', () {
      testWidgets('頁面初始化時應該請求相機權限', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = const CameraState();

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        // 這裡會檢查是否請求了相機權限
        // 實際實作中會有權限請求邏輯
        verify(() => mockCameraViewModel.initializeCamera(any())).called(1);
      });

      testWidgets('頁面銷毀時應該清理資源', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
        );

        // Act - 建立頁面
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Act - 銷毀頁面
        await tester.pumpWidget(const SizedBox());
        await tester.pump();

        // Assert
        verify(() => mockCameraViewModel.dispose()).called(1);
      });

      testWidgets('相機預覽應該適應螢幕比例', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        final cameraPreview = tester.widget<CameraPreview>(
          find.byType(CameraPreview),
        );
        expect(cameraPreview, isNotNull);
        // 檢查預覽是否正確設定了相機控制器
        expect(cameraPreview.controller, equals(mockCameraController));
      });
    });

    group('無障礙測試', () {
      testWidgets('按鈕應該有正確的語義標籤', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.bySemanticsLabel('拍照'), findsOneWidget);
        expect(find.bySemanticsLabel('切換閃光燈'), findsOneWidget);
        expect(find.bySemanticsLabel('從相簿選擇'), findsOneWidget);
        expect(find.bySemanticsLabel('關閉相機'), findsOneWidget);
      });

      testWidgets('應該提供適當的語音提示', (WidgetTester tester) async {
        // Arrange
        mockCameraViewModel.state = CameraState(
          isInitialized: true,
          cameraController: mockCameraController,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('將名片放入框內'), findsOneWidget);
      });
    });
  });
}
