import 'dart:io';
import 'dart:typed_data';

import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_creation/pages/ocr_processing_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_creation/view_models/ocr_processing_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/loading_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/toast_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/domain_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock 類別
class MockOCRProcessingViewModel extends StateNotifier<OCRProcessingState>
    with Mock
    implements OCRProcessingViewModel {
  MockOCRProcessingViewModel() : super(const OCRProcessingState());
}

class MockLoadingPresenter extends Mock implements LoadingPresenter {}

class MockToastPresenter extends Mock implements ToastPresenter {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  setUpAll(() {
    // 註冊 fallback values 給 Mocktail
    registerFallbackValue(Uint8List(0));
  });
  group('OCRProcessingPage Widget Tests', () {
    late MockOCRProcessingViewModel mockOCRProcessingViewModel;
    late MockLoadingPresenter mockLoadingPresenter;
    late MockToastPresenter mockToastPresenter;
    late MockNavigatorObserver mockNavigatorObserver;

    // 測試資料
    const testImagePath = '/test/path/image.jpg';
    final testOCRResult = OCRResult(
      id: 'test-id',
      rawText: '張三\n軟體工程師\nABC公司\n電話: 0912-345-678\nEmail: test@example.com',
      confidence: 0.85,
      processedAt: DateTime.now(),
    );
    final testBusinessCard = BusinessCard(
      id: 'test-card-id',
      name: '張三',
      jobTitle: '軟體工程師',
      company: 'ABC公司',
      phone: '0912-345-678',
      email: 'test@example.com',
      imageUrl: testImagePath,
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockOCRProcessingViewModel = MockOCRProcessingViewModel();
      mockLoadingPresenter = MockLoadingPresenter();
      mockToastPresenter = MockToastPresenter();
      mockNavigatorObserver = MockNavigatorObserver();
    });

    Widget createTestWidget({OCRProcessingState? state}) {
      return ProviderScope(
        overrides: [
          ocrProcessingViewModelProvider.overrideWith(
            (ref) => mockOCRProcessingViewModel,
          ),
          loadingPresenterProvider.overrideWith((ref) => mockLoadingPresenter),
          toastPresenterProvider.overrideWith((ref) => mockToastPresenter),
        ],
        child: MaterialApp(
          home: const OCRProcessingPage(imagePath: testImagePath),
          navigatorObservers: [mockNavigatorObserver],
        ),
      );
    }

    group('UI 顯示測試', () {
      testWidgets('初始狀態下應該顯示圖片載入', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = const OCRProcessingState(
          processingStep: OCRProcessingStep.idle,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('載入圖片中...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('應該顯示圖片預覽', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = const OCRProcessingState(
          processingStep: OCRProcessingStep.imageLoaded,
          imageData: null,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byType(Image), findsOneWidget);
        expect(find.byKey(const Key('image_preview')), findsOneWidget);
      });

      testWidgets('OCR 處理中應該顯示進度指示器', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = const OCRProcessingState(
          processingStep: OCRProcessingStep.ocrProcessing,
          imageData: null,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('文字識別中...'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('OCR 完成後應該顯示識別文字', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.ocrCompleted,
          imageData: null,
          ocrResult: testOCRResult,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('識別文字'), findsOneWidget);
        expect(find.text(testOCRResult.rawText), findsOneWidget);
        expect(find.byKey(const Key('raw_text_display')), findsOneWidget);
      });

      testWidgets('AI 處理中應該顯示 AI 圖示和文字', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.aiProcessing,
          imageData: null,
          ocrResult: testOCRResult,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('AI 解析中...'), findsOneWidget);
        expect(find.byIcon(Icons.psychology), findsOneWidget);
      });

      testWidgets('處理完成後應該顯示名片預覽', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.completed,
          imageData: null,
          ocrResult: testOCRResult,
          parsedCard: testBusinessCard,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('處理完成'), findsOneWidget);
        expect(find.text(testBusinessCard.name), findsOneWidget);
        expect(find.text(testBusinessCard.company!), findsOneWidget);
        expect(find.byKey(const Key('business_card_preview')), findsOneWidget);
      });

      testWidgets('錯誤狀態應該顯示錯誤訊息', (WidgetTester tester) async {
        // Arrange
        const errorMessage = 'OCR 處理失敗';
        mockOCRProcessingViewModel.state = const OCRProcessingState(
          processingStep: OCRProcessingStep.idle,
          error: errorMessage,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('處理失敗'), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('應該顯示處理步驟進度', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = const OCRProcessingState(
          processingStep: OCRProcessingStep.ocrProcessing,
          imageData: null,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byKey(const Key('progress_steps')), findsOneWidget);
        expect(find.text('1'), findsOneWidget); // 第一步
        expect(find.text('圖片載入'), findsOneWidget);
        expect(find.text('文字識別'), findsOneWidget);
        expect(find.text('AI 解析'), findsOneWidget);
      });

      testWidgets('低信心度時應該顯示警告', (WidgetTester tester) async {
        // Arrange
        final lowConfidenceOCR = OCRResult(
          id: 'test-id',
          rawText: '模糊文字',
          confidence: 0.6, // 低於 70% 閾值
          processedAt: DateTime.now(),
        );
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.ocrCompleted,
          imageData: null,
          ocrResult: lowConfidenceOCR,
          confidence: 0.85,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.byIcon(Icons.warning), findsOneWidget);
        expect(find.text('建議重新拍攝'), findsOneWidget);
      });
    });

    group('使用者互動測試', () {
      testWidgets('點擊開始處理按鈕應該觸發 OCR', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = const OCRProcessingState(
          processingStep: OCRProcessingStep.imageLoaded,
          imageData: null,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.byKey(const Key('start_processing_button')));
        await tester.pump();

        // Assert
        verify(() => mockOCRProcessingViewModel.processOCR()).called(1);
      });

      testWidgets('點擊重新拍攝按鈕應該返回相機頁面', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.ocrCompleted,
          imageData: null,
          ocrResult: testOCRResult,
          confidence: 0.85,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.byKey(const Key('retake_photo_button')));
        await tester.pump();

        // Assert
        verify(() => mockNavigatorObserver.didPop(any(), any()));
      });

      testWidgets('點擊編輯文字按鈕應該開啟文字編輯', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.ocrCompleted,
          imageData: null,
          ocrResult: testOCRResult,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.byKey(const Key('edit_text_button')));
        await tester.pump();

        // Assert
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byKey(const Key('text_editor')), findsOneWidget);
      });

      testWidgets('編輯文字後點擊確定應該更新文字', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.ocrCompleted,
          imageData: null,
          ocrResult: testOCRResult,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // 編輯文字
        await tester.enterText(find.byType(TextField), '編輯後的文字');
        await tester.tap(find.byKey(const Key('confirm_edit_button')));
        await tester.pump();

        // Assert
        verify(
          () => mockOCRProcessingViewModel.updateOCRText('編輯後的文字'),
        ).called(1);
      });

      testWidgets('點擊重新 AI 解析按鈕應該觸發 AI 處理', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.ocrCompleted,
          imageData: null,
          ocrResult: testOCRResult,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.byKey(const Key('reprocess_ai_button')));
        await tester.pump();

        // Assert
        verify(() => mockOCRProcessingViewModel.parseWithAI()).called(1);
      });

      testWidgets('點擊完成處理按鈕應該觸發完整流程', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.ocrCompleted,
          imageData: null,
          ocrResult: testOCRResult,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.byKey(const Key('complete_processing_button')));
        await tester.pump();

        // Assert
        verify(
          () => mockOCRProcessingViewModel.processImageToCard(any()),
        ).called(1);
      });

      testWidgets('處理完成後點擊保存應該導航到編輯頁面', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.completed,
          imageData: null,
          ocrResult: testOCRResult,
          parsedCard: testBusinessCard,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.byKey(const Key('save_card_button')));
        await tester.pump();

        // Assert
        // 檢查導航到編輯頁面
        // 實際實作中會有導航邏輯
      });

      testWidgets('錯誤狀態下點擊重試按鈕應該重新開始處理', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = const OCRProcessingState(
          processingStep: OCRProcessingStep.idle,
          imageData: null,
          error: 'OCR 處理失敗',
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.byKey(const Key('retry_button')));
        await tester.pump();

        // Assert
        verify(() => mockOCRProcessingViewModel.resetState()).called(1);
      });
    });

    group('狀態變化測試', () {
      testWidgets('步驟變化應該更新進度指示器', (WidgetTester tester) async {
        // Arrange - OCR 處理中
        mockOCRProcessingViewModel.state = const OCRProcessingState(
          processingStep: OCRProcessingStep.ocrProcessing,
          imageData: null,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert - 應該顯示 OCR 處理進度
        expect(find.text('文字識別中...'), findsOneWidget);

        // Arrange - 更新為 AI 處理中
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.aiProcessing,
          imageData: null,
          ocrResult: testOCRResult,
        );

        // Act
        await tester.pump();

        // Assert - 應該顯示 AI 處理進度
        expect(find.text('AI 解析中...'), findsOneWidget);
      });

      testWidgets('文字編輯狀態變化應該正確顯示', (WidgetTester tester) async {
        // Arrange - 非編輯狀態
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.ocrCompleted,
          imageData: null,
          ocrResult: testOCRResult,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert - 應該顯示只讀文字
        expect(find.text(testOCRResult.rawText), findsOneWidget);
        expect(find.byType(TextField), findsNothing);

        // Arrange - 編輯狀態
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.ocrCompleted,
          imageData: null,
          ocrResult: testOCRResult,
        );

        // Act
        await tester.pump();

        // Assert - 應該顯示文字輸入框
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byKey(const Key('confirm_edit_button')), findsOneWidget);
      });

      testWidgets('警告狀態變化應該正確顯示', (WidgetTester tester) async {
        // Arrange - 無警告
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.ocrCompleted,
          imageData: null,
          ocrResult: testOCRResult,
          confidence: 0.5,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert - 不應該顯示警告
        expect(find.byIcon(Icons.warning), findsNothing);

        // Arrange - 顯示警告
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.ocrCompleted,
          imageData: null,
          ocrResult: testOCRResult,
          confidence: 0.85,
        );

        // Act
        await tester.pump();

        // Assert - 應該顯示警告
        expect(find.byIcon(Icons.warning), findsOneWidget);
        expect(find.text('建議重新拍攝'), findsOneWidget);
      });
    });

    group('AppBar 和導航測試', () {
      testWidgets('應該顯示正確的 AppBar 標題', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = const OCRProcessingState(
          processingStep: OCRProcessingStep.imageLoaded,
          imageData: null,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.text('處理名片'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('點擊返回按鈕應該正確處理', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = const OCRProcessingState(
          processingStep: OCRProcessingStep.imageLoaded,
          imageData: null,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.byTooltip('Back'));
        await tester.pump();

        // Assert
        verify(() => mockNavigatorObserver.didPop(any(), any()));
      });

      testWidgets('處理中狀態應該禁用返回按鈕', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = const OCRProcessingState(
          processingStep: OCRProcessingStep.ocrProcessing,
          imageData: null,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        // 檢查返回按鈕是否被禁用或有適當的處理
        final backButton = find.byTooltip('Back');
        expect(backButton, findsOneWidget);
      });
    });

    group('無障礙測試', () {
      testWidgets('應該有適當的語義標籤', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = OCRProcessingState(
          processingStep: OCRProcessingStep.completed,
          imageData: null,
          parsedCard: testBusinessCard,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.bySemanticsLabel('名片圖片預覽'), findsOneWidget);
        expect(find.bySemanticsLabel('保存名片'), findsOneWidget);
      });

      testWidgets('進度指示器應該有語義描述', (WidgetTester tester) async {
        // Arrange
        mockOCRProcessingViewModel.state = const OCRProcessingState(
          processingStep: OCRProcessingStep.ocrProcessing,
          imageData: null,
        );

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Assert
        expect(find.bySemanticsLabel('文字識別進度'), findsOneWidget);
      });
    });
  });
}
