import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/get_cards_usecase.dart';
import 'package:busines_card_scanner_flutter/presentation/features/settings/view_models/export_view_model.dart';

// Mock classes
class MockGetCardsUseCase extends Mock implements GetCardsUseCase {}
class MockFileSystemService extends Mock implements FileSystemService {}
class MockShareService extends Mock implements ShareService {}
class MockDirectory extends Mock implements Directory {}
class MockFile extends Mock implements File {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(const GetCardsParams());
    registerFallbackValue(const SearchCardsParams(query: ''));
  });

  group('ExportViewModel Tests', () {
    late MockGetCardsUseCase mockGetCardsUseCase;
    late MockFileSystemService mockFileSystemService;
    late MockShareService mockShareService;
    late MockDirectory mockDirectory;
    late MockFile mockFile;
    late ProviderContainer container;
    late List<BusinessCard> testCards;

    setUp(() {
      mockGetCardsUseCase = MockGetCardsUseCase();
      mockFileSystemService = MockFileSystemService();
      mockShareService = MockShareService();
      mockDirectory = MockDirectory();
      mockFile = MockFile();

      // 準備測試名片資料
      testCards = [
        BusinessCard(
          id: '1',
          name: 'John Doe',
          jobTitle: 'Software Engineer',
          company: 'Tech Corp',
          email: 'john@techcorp.com',
          phone: '+1-555-0123',
          address: '123 Tech Street, Silicon Valley',
          website: 'https://johndoe.dev',
          notes: 'Flutter developer',
          createdAt: DateTime(2024, 1, 1),
        ),
        BusinessCard(
          id: '2', 
          name: '李小明',
          jobTitle: '產品經理',
          company: '創新科技',
          email: 'ming@innovation.com.tw',
          phone: '0912-345-678',
          address: '台北市信義區101號',
          website: 'https://innovation.com.tw',
          notes: '專精AI產品開發',
          createdAt: DateTime(2024, 1, 2),
        ),
        BusinessCard(
          id: '3',
          name: 'Jane Smith',
          jobTitle: 'Designer', 
          company: 'Creative Studio',
          email: 'jane@creative.com',
          phone: '+44-20-7123-4567',
          createdAt: DateTime(2024, 1, 3),
        ),
      ];

      // 設定 Mock 預設回傳值
      when(() => mockGetCardsUseCase.execute(any()))
          .thenAnswer((_) async => testCards);
      when(() => mockGetCardsUseCase.searchCards(any()))
          .thenAnswer((_) async => testCards.take(2).toList());
      
      when(() => mockDirectory.path).thenReturn('/mock/documents');
      when(() => mockFileSystemService.getApplicationDocumentsDirectory())
          .thenAnswer((_) async => mockDirectory);
      when(() => mockFileSystemService.writeFile(any(), any()))
          .thenAnswer((_) async => mockFile);
      when(() => mockFileSystemService.fileExists(any()))
          .thenAnswer((_) async => true);
      when(() => mockShareService.shareFile(any(), any()))
          .thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          exportViewModelProvider.overrideWith(
            (ref) => ExportViewModel(
              getCardsUseCase: mockGetCardsUseCase,
              fileSystemService: mockFileSystemService,
              shareService: mockShareService,
            ),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('初始狀態', () {
      test('應該有正確的初始狀態', () {
        final state = container.read(exportViewModelProvider);

        expect(state.isExporting, false);
        expect(state.progress, 0.0);
        expect(state.exportedFilePath, isNull);
        expect(state.errorMessage, isNull);
        expect(state.selectedFormat, ExportFormat.csv);
        expect(state.selectedCardIds, isEmpty);
      });

      test('初始化不應該觸發任何 UseCase 呼叫', () {
        container.read(exportViewModelProvider);

        verifyNever(() => mockGetCardsUseCase.execute(any()));
        verifyNever(() => mockGetCardsUseCase.searchCards(any()));
      });
    });

    group('匯出格式設定', () {
      test('應該成功設定 CSV 格式', () {
        final viewModel = container.read(exportViewModelProvider.notifier);

        viewModel.setExportFormat(ExportFormat.csv);

        final state = viewModel.state;
        expect(state.selectedFormat, ExportFormat.csv);
        expect(state.errorMessage, isNull);
      });

      test('應該成功設定 VCF 格式', () {
        final viewModel = container.read(exportViewModelProvider.notifier);

        viewModel.setExportFormat(ExportFormat.vcf);

        final state = viewModel.state;
        expect(state.selectedFormat, ExportFormat.vcf);
        expect(state.errorMessage, isNull);
      });

      test('應該成功設定 JSON 格式', () {
        final viewModel = container.read(exportViewModelProvider.notifier);

        viewModel.setExportFormat(ExportFormat.json);

        final state = viewModel.state;
        expect(state.selectedFormat, ExportFormat.json);
        expect(state.errorMessage, isNull);
      });

      test('切換格式應該清除先前的錯誤', () {
        final viewModel = container.read(exportViewModelProvider.notifier);

        // 先設定一個錯誤狀態
        viewModel.state = viewModel.state.copyWith(
          errorMessage: '測試錯誤',
        );
        expect(viewModel.state.errorMessage, isNotNull);

        // 切換格式
        viewModel.setExportFormat(ExportFormat.json);

        expect(viewModel.state.errorMessage, isNull);
      });
    });

    group('名片選擇', () {
      test('應該成功選擇名片', () {
        final viewModel = container.read(exportViewModelProvider.notifier);
        final cardIds = ['1', '2'];

        viewModel.selectCards(cardIds);

        final state = viewModel.state;
        expect(state.selectedCardIds, equals(cardIds));
        expect(state.errorMessage, isNull);
      });

      test('應該成功清空選擇', () {
        final viewModel = container.read(exportViewModelProvider.notifier);

        // 先選擇一些名片
        viewModel.selectCards(['1', '2']);
        expect(viewModel.state.selectedCardIds, isNotEmpty);

        // 清空選擇
        viewModel.selectCards([]);

        final state = viewModel.state;
        expect(state.selectedCardIds, isEmpty);
      });

      test('選擇名片應該清除先前的錯誤', () {
        final viewModel = container.read(exportViewModelProvider.notifier);

        // 先設定一個錯誤狀態
        viewModel.state = viewModel.state.copyWith(
          errorMessage: '測試錯誤',
        );

        viewModel.selectCards(['1']);

        expect(viewModel.state.errorMessage, isNull);
      });

      test('應該處理重複的名片 ID', () {
        final viewModel = container.read(exportViewModelProvider.notifier);
        final cardIds = ['1', '2', '1', '3', '2'];

        viewModel.selectCards(cardIds);

        final state = viewModel.state;
        // 應該去除重複項目
        expect(state.selectedCardIds, equals(['1', '2', '3']));
      });
    });

    group('匯出全部名片', () {
      test('應該成功匯出全部名片為 CSV', () async {
        final viewModel = container.read(exportViewModelProvider.notifier);
        bool progressUpdated = false;
        bool exportStarted = false;

        // 監聽狀態變化
        container.listen(exportViewModelProvider, (previous, next) {
          if (next.isExporting && !exportStarted) {
            exportStarted = true;
          }
          if (next.progress > 0.0 && next.progress < 1.0) {
            progressUpdated = true;
          }
        });

        viewModel.setExportFormat(ExportFormat.csv);
        await viewModel.exportAllCards();

        final state = viewModel.state;
        expect(state.isExporting, false);
        expect(state.progress, 1.0);
        expect(state.exportedFilePath, isNotNull);
        expect(state.errorMessage, isNull);
        expect(exportStarted, true);
        expect(progressUpdated, true);

        verify(() => mockGetCardsUseCase.execute(any())).called(1);
      });

      test('應該成功匯出全部名片為 VCF', () async {
        final viewModel = container.read(exportViewModelProvider.notifier);

        viewModel.setExportFormat(ExportFormat.vcf);
        await viewModel.exportAllCards();

        final state = viewModel.state;
        expect(state.isExporting, false);
        expect(state.progress, 1.0);
        expect(state.exportedFilePath, isNotNull);
        expect(state.exportedFilePath, contains('.vcf'));
        expect(state.errorMessage, isNull);

        verify(() => mockGetCardsUseCase.execute(any())).called(1);
      });

      test('應該成功匯出全部名片為 JSON', () async {
        final viewModel = container.read(exportViewModelProvider.notifier);

        viewModel.setExportFormat(ExportFormat.json);
        await viewModel.exportAllCards();

        final state = viewModel.state;
        expect(state.isExporting, false);
        expect(state.progress, 1.0);
        expect(state.exportedFilePath, isNotNull);
        expect(state.exportedFilePath, contains('.json'));
        expect(state.errorMessage, isNull);

        verify(() => mockGetCardsUseCase.execute(any())).called(1);
      });

      test('匯出失敗時應該顯示錯誤', () async {
        when(() => mockGetCardsUseCase.execute(any()))
            .thenThrow(Exception('資料庫連線失敗'));
        final viewModel = container.read(exportViewModelProvider.notifier);

        await viewModel.exportAllCards();

        final state = viewModel.state;
        expect(state.isExporting, false);
        expect(state.progress, 0.0);
        expect(state.exportedFilePath, isNull);
        expect(state.errorMessage, isNotNull);
        expect(state.errorMessage, contains('匯出失敗'));
      });

      test('無名片資料時應該顯示適當錯誤', () async {
        when(() => mockGetCardsUseCase.execute(any()))
            .thenAnswer((_) async => []);
        final viewModel = container.read(exportViewModelProvider.notifier);

        await viewModel.exportAllCards();

        final state = viewModel.state;
        expect(state.errorMessage, contains('沒有名片資料可匯出'));
      });

      test('大量名片應該分批處理', () async {
        // 準備大量測試資料
        final largeCardList = List.generate(150, (index) => BusinessCard(
          id: 'card_$index',
          name: 'User $index',
          createdAt: DateTime.now(),
        ));

        when(() => mockGetCardsUseCase.execute(any()))
            .thenAnswer((_) async => largeCardList);

        final viewModel = container.read(exportViewModelProvider.notifier);
        final progressValues = <double>[];

        container.listen(exportViewModelProvider, (previous, next) {
          if (next.progress > (previous?.progress ?? 0.0)) {
            progressValues.add(next.progress);
          }
        });

        await viewModel.exportAllCards();

        // 應該有多次進度更新
        expect(progressValues.length, greaterThan(1));
        expect(progressValues.last, 1.0);
      });
    });

    group('匯出選定名片', () {
      test('應該成功匯出選定的名片', () async {
        final viewModel = container.read(exportViewModelProvider.notifier);

        viewModel.selectCards(['1', '2']);
        await viewModel.exportSelectedCards();

        final state = viewModel.state;
        expect(state.isExporting, false);
        expect(state.progress, 1.0);
        expect(state.exportedFilePath, isNotNull);
        expect(state.errorMessage, isNull);

        verify(() => mockGetCardsUseCase.execute(any())).called(1);
      });

      test('未選擇名片時應該顯示錯誤', () async {
        final viewModel = container.read(exportViewModelProvider.notifier);

        await viewModel.exportSelectedCards();

        final state = viewModel.state;
        expect(state.errorMessage, contains('請先選擇要匯出的名片'));
        expect(state.isExporting, false);
        expect(state.exportedFilePath, isNull);
      });

      test('選定的名片不存在時應該顯示錯誤', () async {
        when(() => mockGetCardsUseCase.execute(any()))
            .thenAnswer((_) async => []);
        final viewModel = container.read(exportViewModelProvider.notifier);

        viewModel.selectCards(['999', '888']);
        await viewModel.exportSelectedCards();

        final state = viewModel.state;
        expect(state.errorMessage, contains('找不到指定的名片'));
      });
    });

    group('取消匯出', () {
      test('應該能夠取消進行中的匯出', () async {
        final viewModel = container.read(exportViewModelProvider.notifier);
        
        // 開始匯出（不等待完成）
        final exportFuture = viewModel.exportAllCards();
        
        // 立即取消
        viewModel.cancelExport();
        
        // 等待匯出完成
        await exportFuture;

        final state = viewModel.state;
        expect(state.isExporting, false);
        expect(state.errorMessage, contains('匯出已取消'));
        expect(state.exportedFilePath, isNull);
      });

      test('未在匯出時呼叫取消應該沒有影響', () {
        final viewModel = container.read(exportViewModelProvider.notifier);

        viewModel.cancelExport();

        final state = viewModel.state;
        expect(state.isExporting, false);
        expect(state.errorMessage, isNull);
      });

      test('取消後應該能重新開始匯出', () async {
        final viewModel = container.read(exportViewModelProvider.notifier);

        // 取消一次匯出
        final exportFuture = viewModel.exportAllCards();
        viewModel.cancelExport();
        await exportFuture;

        // 重新匯出應該成功
        await viewModel.exportAllCards();

        final state = viewModel.state;
        expect(state.isExporting, false);
        expect(state.progress, 1.0);
        expect(state.exportedFilePath, isNotNull);
        expect(state.errorMessage, isNull);
      });
    });

    group('檔案分享', () {
      test('成功匯出後應該能分享檔案', () async {
        final viewModel = container.read(exportViewModelProvider.notifier);

        await viewModel.exportAllCards();
        expect(viewModel.state.exportedFilePath, isNotNull);

        await viewModel.shareExportedFile();

        // 由於 Share.shareXFiles 是靜態方法且難以 Mock，
        // 這裡主要測試方法呼叫不會拋出異常
        expect(viewModel.state.errorMessage, isNull);
      });

      test('未匯出檔案時分享應該顯示錯誤', () async {
        final viewModel = container.read(exportViewModelProvider.notifier);

        await viewModel.shareExportedFile();

        final state = viewModel.state;
        expect(state.errorMessage, contains('請先匯出檔案'));
      });

      test('檔案不存在時分享應該顯示錯誤', () async {
        when(() => mockFileSystemService.fileExists(any()))
            .thenAnswer((_) async => false);

        final viewModel = container.read(exportViewModelProvider.notifier);

        // 手動設定一個不存在的檔案路徑
        viewModel.state = viewModel.state.copyWith(
          exportedFilePath: '/nonexistent/path/file.csv',
        );

        await viewModel.shareExportedFile();

        final state = viewModel.state;
        expect(state.errorMessage, contains('檔案不存在或已被刪除'));
      });
    });

    group('格式轉換', () {
      test('CSV 格式應該包含正確的標題列', () async {
        String? capturedContent;
        when(() => mockFileSystemService.writeFile(any(), any()))
            .thenAnswer((invocation) async {
              capturedContent = invocation.positionalArguments[1] as String;
              return mockFile;
            });

        final viewModel = container.read(exportViewModelProvider.notifier);

        viewModel.setExportFormat(ExportFormat.csv);
        await viewModel.exportAllCards();

        expect(capturedContent, isNotNull);
        expect(capturedContent!, contains('姓名,職稱,公司,電子郵件,電話,地址,網站,備註,建立日期'));
      });

      test('CSV 格式應該正確處理特殊字元', () async {
        final cardWithSpecialChars = BusinessCard(
          id: 'special',
          name: '測試,引號"使用者',
          jobTitle: 'Senior\nEngineer',
          company: 'Test "Company" Inc.',
          createdAt: DateTime.now(),
        );

        when(() => mockGetCardsUseCase.execute(any()))
            .thenAnswer((_) async => [cardWithSpecialChars]);

        String? capturedContent;
        when(() => mockFileSystemService.writeFile(any(), any()))
            .thenAnswer((invocation) async {
              capturedContent = invocation.positionalArguments[1] as String;
              return mockFile;
            });

        final viewModel = container.read(exportViewModelProvider.notifier);
        viewModel.setExportFormat(ExportFormat.csv);
        await viewModel.exportAllCards();

        expect(capturedContent, isNotNull);
        // CSV 應該正確轉義特殊字元
        expect(capturedContent!, contains('"測試,引號""使用者"'));
        expect(capturedContent!, contains('"Test ""Company"" Inc."'));
      });

      test('VCF 格式應該符合 vCard 標準', () async {
        String? capturedContent;
        when(() => mockFileSystemService.writeFile(any(), any()))
            .thenAnswer((invocation) async {
              capturedContent = invocation.positionalArguments[1] as String;
              return mockFile;
            });

        final viewModel = container.read(exportViewModelProvider.notifier);

        viewModel.setExportFormat(ExportFormat.vcf);
        await viewModel.exportAllCards();

        expect(capturedContent, isNotNull);
        // 檢查 vCard 基本結構
        expect(capturedContent!, contains('BEGIN:VCARD'));
        expect(capturedContent!, contains('VERSION:3.0'));
        expect(capturedContent!, contains('FN:John Doe'));
        expect(capturedContent!, contains('ORG:Tech Corp'));
        expect(capturedContent!, contains('EMAIL:john@techcorp.com'));
        expect(capturedContent!, contains('TEL:+1-555-0123'));
        expect(capturedContent!, contains('END:VCARD'));
      });

      test('JSON 格式應該包含完整名片資料', () async {
        String? capturedContent;
        when(() => mockFileSystemService.writeFile(any(), any()))
            .thenAnswer((invocation) async {
              capturedContent = invocation.positionalArguments[1] as String;
              return mockFile;
            });

        final viewModel = container.read(exportViewModelProvider.notifier);

        viewModel.setExportFormat(ExportFormat.json);
        await viewModel.exportAllCards();

        expect(capturedContent, isNotNull);
        // 檢查 JSON 結構
        expect(capturedContent!, contains('"name": "John Doe"'));
        expect(capturedContent!, contains('"jobTitle": "Software Engineer"'));
        expect(capturedContent!, contains('"company": "Tech Corp"'));
        expect(capturedContent!, contains('"email": "john@techcorp.com"'));
        expect(capturedContent!, contains('"exportedAt":'));
        expect(capturedContent!, contains('"totalCards":'));
      });
    });

    group('檔案命名', () {
      test('應該產生包含時間戳記的檔案名稱', () async {
        final viewModel = container.read(exportViewModelProvider.notifier);

        await viewModel.exportAllCards();

        final filePath = viewModel.state.exportedFilePath!;
        final fileName = filePath.split('/').last;

        expect(fileName, matches(r'business_cards_\d{8}_\d{6}\.csv'));
      });

      test('不同格式應該有相對應的副檔名', () async {
        final viewModel = container.read(exportViewModelProvider.notifier);

        // 測試 VCF
        viewModel.setExportFormat(ExportFormat.vcf);
        await viewModel.exportAllCards();
        expect(viewModel.state.exportedFilePath, endsWith('.vcf'));

        // 測試 JSON
        viewModel.setExportFormat(ExportFormat.json);
        await viewModel.exportAllCards();
        expect(viewModel.state.exportedFilePath, endsWith('.json'));
      });
    });

    group('錯誤處理與清除', () {
      test('應該能清除錯誤狀態', () {
        final viewModel = container.read(exportViewModelProvider.notifier);

        // 設定錯誤狀態
        viewModel.state = viewModel.state.copyWith(
          errorMessage: '測試錯誤',
        );

        viewModel.clearError();

        expect(viewModel.state.errorMessage, isNull);
      });

      test('重新開始匯出應該清除先前的錯誤和進度', () async {
        final viewModel = container.read(exportViewModelProvider.notifier);

        // 設定先前的狀態
        viewModel.state = viewModel.state.copyWith(
          errorMessage: '先前錯誤',
          progress: 0.5,
          exportedFilePath: 'old_file.csv',
        );

        await viewModel.exportAllCards();

        final state = viewModel.state;
        expect(state.errorMessage, isNull);
        expect(state.progress, 1.0);
        expect(state.exportedFilePath, isNot('old_file.csv'));
      });
    });

    group('邊界條件', () {
      test('應該處理空名片列表', () async {
        when(() => mockGetCardsUseCase.execute(any()))
            .thenAnswer((_) async => []);
        final viewModel = container.read(exportViewModelProvider.notifier);

        await viewModel.exportAllCards();

        expect(viewModel.state.errorMessage, contains('沒有名片資料可匯出'));
      });

      test('應該處理只有部分欄位的名片', () async {
        final minimalCard = BusinessCard(
          id: 'minimal',
          name: 'Minimal User',
          createdAt: DateTime.now(),
        );

        when(() => mockGetCardsUseCase.execute(any()))
            .thenAnswer((_) async => [minimalCard]);

        final viewModel = container.read(exportViewModelProvider.notifier);
        await viewModel.exportAllCards();

        expect(viewModel.state.isExporting, false);
        expect(viewModel.state.exportedFilePath, isNotNull);
        expect(viewModel.state.errorMessage, isNull);
      });

      test('應該處理超長文字內容', () async {
        final longTextCard = BusinessCard(
          id: 'long',
          name: 'A' * 1000,
          notes: 'B' * 5000,
          createdAt: DateTime.now(),
        );

        when(() => mockGetCardsUseCase.execute(any()))
            .thenAnswer((_) async => [longTextCard]);

        final viewModel = container.read(exportViewModelProvider.notifier);
        await viewModel.exportAllCards();

        expect(viewModel.state.errorMessage, isNull);
        expect(viewModel.state.exportedFilePath, isNotNull);
      });
    });

    group('多執行緒安全', () {
      test('同時呼叫多個匯出方法應該正確處理', () async {
        final viewModel = container.read(exportViewModelProvider.notifier);
        
        viewModel.selectCards(['1']);

        // 同時呼叫多個匯出方法
        final futures = [
          viewModel.exportAllCards(),
          viewModel.exportSelectedCards(),
        ];

        await Future.wait(futures);

        // 最後的狀態應該是穩定的
        final state = viewModel.state;
        expect(state.isExporting, false);
        // 至少應該有一個成功的匯出
        expect(state.exportedFilePath != null || state.errorMessage != null, true);
      });
    });
  });
}