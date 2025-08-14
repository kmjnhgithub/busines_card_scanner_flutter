import 'dart:typed_data';

import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/create_card_from_image_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/create_card_from_ocr_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/process_image_usecase.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_creation/view_models/ocr_processing_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/loading_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/presenters/toast_presenter.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/domain_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_helpers.dart';

// Mock 類別
class MockProcessImageUseCase extends Mock implements ProcessImageUseCase {}

class MockCreateCardFromImageUseCase extends Mock
    implements CreateCardFromImageUseCase {}

class MockCreateCardFromOCRUseCase extends Mock
    implements CreateCardFromOCRUseCase {}

class MockLoadingPresenter extends Mock implements LoadingPresenter {}

class MockToastPresenter extends Mock implements ToastPresenter {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    suppressDatabaseWarnings();
    registerCommonFallbackValues();
  });
  
  group('OCRProcessingViewModel Tests', () {
    late MockProcessImageUseCase mockProcessImageUseCase;
    late MockCreateCardFromImageUseCase mockCreateCardFromImageUseCase;
    late MockCreateCardFromOCRUseCase mockCreateCardFromOCRUseCase;
    late MockLoadingPresenter mockLoadingPresenter;
    late MockToastPresenter mockToastPresenter;
    late ProviderContainer container;

    // 測試資料
    final testImageData = Uint8List.fromList([1, 2, 3, 4, 5]);
    final testOCRResult = OCRResult(
      id: 'test-ocr-1',
      rawText: '張三\n台灣科技有限公司\n軟體工程師\n電話：0912-345-678\n信箱：john@example.com',
      confidence: 0.95,
      processedAt: DateTime.now(),
      processingTimeMs: 1500,
      ocrEngine: 'GoogleMLKit',
    );

    final testBusinessCard = BusinessCard(
      id: 'test-card-1',
      name: '張三',
      company: '台灣科技有限公司',
      jobTitle: '軟體工程師',
      email: 'john@example.com',
      phone: '0912-345-678',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      mockProcessImageUseCase = MockProcessImageUseCase();
      mockCreateCardFromImageUseCase = MockCreateCardFromImageUseCase();
      mockCreateCardFromOCRUseCase = MockCreateCardFromOCRUseCase();
      mockLoadingPresenter = MockLoadingPresenter();
      mockToastPresenter = MockToastPresenter();

      // 設定 fallback values
      registerFallbackValue(
        ProcessImageParams(imageData: Uint8List.fromList([1, 2, 3])),
      );
      registerFallbackValue(
        CreateCardFromImageParams(imageData: Uint8List.fromList([1, 2, 3])),
      );
      registerFallbackValue(
        CreateCardFromOCRParams(
          ocrResult: OCRResult(
            id: 'fallback',
            rawText: 'test text',
            confidence: 0.8,
            processedAt: DateTime.now(),
          ),
        ),
      );

      container = ProviderContainer(
        overrides: [
          processImageUseCaseProvider.overrideWithValue(
            mockProcessImageUseCase,
          ),
          createCardFromImageUseCaseProvider.overrideWithValue(
            mockCreateCardFromImageUseCase,
          ),
          createCardFromOCRUseCaseProvider.overrideWithValue(
            mockCreateCardFromOCRUseCase,
          ),
          loadingPresenterProvider.overrideWith((ref) => mockLoadingPresenter),
          toastPresenterProvider.overrideWith((ref) => mockToastPresenter),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('初始化狀態', () {
      test('初始狀態應該正確設定', () {
        final state = container.read(ocrProcessingViewModelProvider);

        expect(state.imageData, isNull);
        expect(state.ocrResult, isNull);
        expect(state.parsedCard, isNull);
        expect(state.processingStep, OCRProcessingStep.idle);
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
        expect(state.confidence, isNull);
        expect(state.warnings, isEmpty);
      });
    });

    group('圖片載入', () {
      test('載入圖片成功時應該更新狀態', () async {
        // Act
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        await viewModel.loadImage(testImageData);

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.imageData, equals(testImageData));
        expect(state.processingStep, OCRProcessingStep.imageLoaded);
        expect(state.error, isNull);
      });

      test('載入空圖片應該設定錯誤', () async {
        // Arrange
        final emptyImageData = Uint8List(0);

        // Act
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        await viewModel.loadImage(emptyImageData);

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.imageData, isNull);
        expect(state.error, contains('圖片資料不能為空'));
        verify(() => mockToastPresenter.showError('圖片資料不能為空')).called(1);
      });
    });

    group('OCR 處理', () {
      test('OCR 處理成功時應該更新狀態', () async {
        // Arrange
        final mockProcessResult = ProcessImageResult(
          isSuccess: true,
          ocrResult: testOCRResult,
          processingSteps: ['圖片預處理', 'OCR 文字識別', '結果驗證'],
          warnings: [],
        );
        when(
          () => mockProcessImageUseCase.execute(any()),
        ).thenAnswer((_) async => mockProcessResult);

        // Act
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        await viewModel.loadImage(testImageData);
        await viewModel.processOCR();

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.ocrResult, equals(testOCRResult));
        expect(state.processingStep, OCRProcessingStep.ocrCompleted);
        expect(state.confidence, equals(0.95));
        expect(state.error, isNull);
        verify(() => mockLoadingPresenter.show('正在處理圖片...')).called(1);
        verify(() => mockLoadingPresenter.hide()).called(1);
      });

      test('OCR 處理失敗時應該設定錯誤狀態', () async {
        // Arrange
        when(
          () => mockProcessImageUseCase.execute(any()),
        ).thenThrow(Exception('OCR 處理失敗'));

        // Act
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        await viewModel.loadImage(testImageData);
        await viewModel.processOCR();

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.ocrResult, isNull);
        expect(state.processingStep, OCRProcessingStep.imageLoaded);
        expect(state.error, contains('OCR 處理失敗'));
        verify(() => mockLoadingPresenter.hide()).called(1);
        verify(
          () => mockToastPresenter.showError(any(that: contains('OCR 處理失敗'))),
        ).called(1);
      });

      test('低信心度 OCR 結果應該顯示警告', () async {
        // Arrange
        final lowConfidenceOCRResult = OCRResult(
          id: 'test-ocr-2',
          rawText: '模糊文字',
          confidence: 0.4,
          processedAt: DateTime.now(),
        );
        final mockProcessResult = ProcessImageResult(
          isSuccess: true,
          ocrResult: lowConfidenceOCRResult,
          processingSteps: ['OCR 處理'],
          warnings: ['OCR 信心度較低 (40.0%)'],
        );
        when(
          () => mockProcessImageUseCase.execute(any()),
        ).thenAnswer((_) async => mockProcessResult);

        // Act
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        await viewModel.loadImage(testImageData);
        await viewModel.processOCR();

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.confidence, equals(0.4));
        expect(state.warnings, contains('OCR 信心度較低 (40.0%)'));
        verify(
          () => mockToastPresenter.showWarning('OCR 信心度較低，建議重新拍攝'),
        ).called(1);
      });

      test('沒有載入圖片時執行 OCR 應該顯示錯誤', () async {
        // Act
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        await viewModel.processOCR();

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.error, contains('請先載入圖片'));
        verify(() => mockToastPresenter.showError('請先載入圖片')).called(1);
      });
    });

    group('AI 解析', () {
      test('AI 解析成功時應該更新狀態', () async {
        // Arrange
        final mockCreateResult = CreateCardFromOCRResult(
          card: testBusinessCard,
          parsedData: ParsedCardData(
            name: '張三',
            company: '台灣科技有限公司',
            jobTitle: '軟體工程師',
            email: 'john@example.com',
            phone: '0912-345-678',
            confidence: 0.95,
            source: ParseSource.ai,
            parsedAt: DateTime.now(),
          ),
          processingSteps: ['AI 文字解析', '資料驗證', '名片建立'],
          warnings: [],
        );
        when(
          () => mockCreateCardFromOCRUseCase.execute(any()),
        ).thenAnswer((_) async => mockCreateResult);

        // Act
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        await viewModel.loadImage(testImageData);
        // 模擬 OCR 完成
        viewModel.setOCRResult(testOCRResult);
        await viewModel.parseWithAI();

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.parsedCard, equals(testBusinessCard));
        expect(state.processingStep, OCRProcessingStep.completed);
        expect(state.error, isNull);
        verify(() => mockLoadingPresenter.show('AI 正在解析名片資訊...')).called(1);
        verify(() => mockLoadingPresenter.hide()).called(1);
      });

      test('AI 解析失敗時應該設定錯誤狀態', () async {
        // Arrange
        when(
          () => mockCreateCardFromOCRUseCase.execute(any()),
        ).thenThrow(Exception('AI 解析失敗'));

        // Act
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        await viewModel.loadImage(testImageData);
        viewModel.setOCRResult(testOCRResult);
        await viewModel.parseWithAI();

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.parsedCard, isNull);
        expect(state.processingStep, OCRProcessingStep.ocrCompleted);
        expect(state.error, contains('AI 解析失敗'));
        verify(() => mockLoadingPresenter.hide()).called(1);
        verify(
          () => mockToastPresenter.showError(any(that: contains('AI 解析失敗'))),
        ).called(1);
      });

      test('沒有 OCR 結果時執行 AI 解析應該顯示錯誤', () async {
        // Act
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        await viewModel.parseWithAI();

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.error, contains('請先完成 OCR 處理'));
        verify(() => mockToastPresenter.showError('請先完成 OCR 處理')).called(1);
      });
    });

    group('完整流程處理', () {
      test('從圖片到名片的完整流程成功', () async {
        // Arrange
        final mockCreateFromImageResult = CreateCardFromImageResult(
          card: testBusinessCard,
          ocrResult: testOCRResult,
          parsedData: ParsedCardData(
            name: '張三',
            company: '台灣科技有限公司',
            jobTitle: '軟體工程師',
            email: 'john@example.com',
            phone: '0912-345-678',
            confidence: 0.95,
            source: ParseSource.ai,
            parsedAt: DateTime.now(),
          ),
          processingSteps: ['圖片預處理', 'OCR 處理', 'AI 解析', '名片建立'],
          warnings: [],
        );
        when(
          () => mockCreateCardFromImageUseCase.execute(any()),
        ).thenAnswer((_) async => mockCreateFromImageResult);

        // Act
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        await viewModel.processImageToCard(testImageData);

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.imageData, equals(testImageData));
        expect(state.ocrResult, equals(testOCRResult));
        expect(state.parsedCard, equals(testBusinessCard));
        expect(state.processingStep, OCRProcessingStep.completed);
        expect(state.error, isNull);
        verify(() => mockLoadingPresenter.show('正在處理名片...')).called(1);
        verify(() => mockLoadingPresenter.hide()).called(1);
        verify(() => mockToastPresenter.showSuccess('名片處理完成！')).called(1);
      });

      test('完整流程失敗時應該正確處理錯誤', () async {
        // Arrange
        when(
          () => mockCreateCardFromImageUseCase.execute(any()),
        ).thenThrow(Exception('處理失敗'));

        // Act
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        await viewModel.processImageToCard(testImageData);

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.processingStep, OCRProcessingStep.idle);
        expect(state.error, contains('名片處理失敗'));
        verify(() => mockLoadingPresenter.hide()).called(1);
        verify(
          () => mockToastPresenter.showError(any(that: contains('名片處理失敗'))),
        ).called(1);
      });
    });

    group('狀態管理', () {
      test('重設狀態應該清除所有資料', () {
        // Arrange
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        // 先設定一些狀態
        viewModel.setOCRResult(testOCRResult);

        // Act
        viewModel.resetState();

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.imageData, isNull);
        expect(state.ocrResult, isNull);
        expect(state.parsedCard, isNull);
        expect(state.processingStep, OCRProcessingStep.idle);
        expect(state.error, isNull);
        expect(state.warnings, isEmpty);
      });

      test('重試處理應該重新開始流程', () async {
        // Arrange
        final mockProcessResult = ProcessImageResult(
          isSuccess: true,
          ocrResult: testOCRResult,
          processingSteps: ['OCR 重試'],
          warnings: [],
        );
        when(
          () => mockProcessImageUseCase.execute(any()),
        ).thenAnswer((_) async => mockProcessResult);

        // Act
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        await viewModel.loadImage(testImageData);
        await viewModel.retryProcessing();

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.ocrResult, equals(testOCRResult));
        expect(state.error, isNull);
        verify(() => mockProcessImageUseCase.execute(any())).called(1);
      });

      test('更新處理步驟應該正確切換狀態', () {
        // Act
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        viewModel.updateProcessingStep(OCRProcessingStep.ocrProcessing);

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.processingStep, OCRProcessingStep.ocrProcessing);
        expect(state.isLoading, isTrue);
      });
    });

    group('文字編輯功能', () {
      test('手動編輯 OCR 文字應該更新狀態', () {
        // Arrange
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        viewModel.setOCRResult(testOCRResult);

        // Act
        const editedText = '編輯後的文字內容';
        viewModel.updateOCRText(editedText);

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.ocrResult?.rawText, equals(editedText));
      });

      test('重新解析編輯過的文字', () async {
        // Arrange
        final editedBusinessCard = BusinessCard(
          id: 'test-card-edited',
          name: '編輯後姓名',
          company: '編輯後公司',
          jobTitle: '編輯後職稱',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final mockCreateResult = CreateCardFromOCRResult(
          card: editedBusinessCard,
          parsedData: ParsedCardData(
            name: '編輯後姓名',
            company: '編輯後公司',
            jobTitle: '編輯後職稱',
            confidence: 0.9,
            source: ParseSource.ai,
            parsedAt: DateTime.now(),
          ),
          processingSteps: ['重新解析編輯文字'],
          warnings: [],
        );
        when(
          () => mockCreateCardFromOCRUseCase.execute(any()),
        ).thenAnswer((_) async => mockCreateResult);

        // Act
        final viewModel = container.read(
          ocrProcessingViewModelProvider.notifier,
        );
        viewModel.setOCRResult(testOCRResult);
        viewModel.updateOCRText('編輯後的文字');
        await viewModel.reparseText();

        // Assert
        final state = container.read(ocrProcessingViewModelProvider);
        expect(state.parsedCard?.name, equals('編輯後姓名'));
        verify(() => mockCreateCardFromOCRUseCase.execute(any())).called(1);
      });
    });
  });
}
