import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_list/pages/card_list_page.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_list/view_models/card_list_view_model.dart';
import 'package:busines_card_scanner_flutter/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('CardListPage Search Tests', () {
    late MockCardListViewModel mockViewModel;

    setUp(() {
      mockViewModel = MockCardListViewModel();

      // 設定預設狀態
      when(mockViewModel.state).thenReturn(
        const CardListState(cards: [], filteredCards: [], isLoading: false),
      );
    });

    testWidgets('應該正確展開搜尋欄', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestApp(
          child: ProviderScope(
            overrides: [
              cardListViewModelProvider.overrideWith(() => mockViewModel),
            ],
            child: const CardListPage(),
          ),
        ),
      );

      // 確認初始狀態：顯示標題，不顯示搜尋欄
      expect(find.text('名片'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      // Act - 點擊搜尋圖標
      final searchIcon = find.byIcon(Icons.search);
      expect(searchIcon, findsOneWidget);
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      // Assert - 應該展開搜尋欄
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('名片'), findsNothing); // 標題應該隱藏
    });

    testWidgets('應該正確收合搜尋欄', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestApp(
          child: ProviderScope(
            overrides: [
              cardListViewModelProvider.overrideWith(() => mockViewModel),
            ],
            child: const CardListPage(),
          ),
        ),
      );

      // 先展開搜尋欄
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 確認搜尋欄已展開
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Act - 點擊 Cancel 按鈕
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert - 應該收合搜尋欄
      expect(find.text('名片'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Cancel'), findsNothing);

      // 驗證清空搜尋
      verify(mockViewModel.searchCards('')).called(1);
    });

    testWidgets('搜尋功能應該正確運作', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestApp(
          child: ProviderScope(
            overrides: [
              cardListViewModelProvider.overrideWith(() => mockViewModel),
            ],
            child: const CardListPage(),
          ),
        ),
      );

      // 展開搜尋欄
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Act - 輸入搜尋文字
      await tester.enterText(textField, '張三');

      // 等待 debounce 延遲
      await tester.pump(const Duration(milliseconds: 400));

      // Assert - 應該呼叫搜尋方法
      verify(mockViewModel.searchCards('張三')).called(1);
    });

    testWidgets('搜尋欄應該有正確的提示文字', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestApp(
          child: ProviderScope(
            overrides: [
              cardListViewModelProvider.overrideWith(() => mockViewModel),
            ],
            child: const CardListPage(),
          ),
        ),
      );

      // 展開搜尋欄
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Assert - 檢查提示文字
      expect(find.text('搜尋姓名、公司、電話、Email'), findsOneWidget);
    });

    testWidgets('搜尋欄應該具有自動對焦', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestApp(
          child: ProviderScope(
            overrides: [
              cardListViewModelProvider.overrideWith(() => mockViewModel),
            ],
            child: const CardListPage(),
          ),
        ),
      );

      // Act - 展開搜尋欄
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Assert - TextField 應該獲得焦點
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, true);
    });

    testWidgets('搜尋欄應該有正確的樣式', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestApp(
          child: ProviderScope(
            overrides: [
              cardListViewModelProvider.overrideWith(() => mockViewModel),
            ],
            child: const CardListPage(),
          ),
        ),
      );

      // 展開搜尋欄
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Assert - 檢查搜尋欄容器樣式
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(TextField),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container.constraints?.maxHeight, 40.0);

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.secondaryBackground);
      expect(decoration.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('按下 Enter 鍵應該觸發搜尋', (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestApp(
          child: ProviderScope(
            overrides: [
              cardListViewModelProvider.overrideWith(() => mockViewModel),
            ],
            child: const CardListPage(),
          ),
        ),
      );

      // 展開搜尋欄
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);

      // Act - 輸入文字並按 Enter
      await tester.enterText(textField, '李四');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      // Assert - 應該立即呼叫搜尋方法（不等待 debounce）
      verify(mockViewModel.searchCards('李四')).called(1);
    });
  });
}
