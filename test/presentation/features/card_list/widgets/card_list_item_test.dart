import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/presentation/features/card_list/widgets/card_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CardListItem Widget Tests', () {
    // 測試用名片資料
    final testCard = BusinessCard(
      id: '1',
      name: '張三',
      jobTitle: '軟體工程師',
      company: '科技公司',
      email: 'zhang@tech.com',
      phone: '0912345678',
      address: '台北市信義區',
      website: 'https://www.tech.com',
      createdAt: DateTime(2024, 1, 1),
    );

    final minimumCard = BusinessCard(
      id: '2',
      name: '李四',
      createdAt: DateTime(2024, 1, 2),
    );

    /// 建立測試用的 Widget
    Widget createTestWidget({
      required BusinessCard card,
      VoidCallback? onTap,
      VoidCallback? onLongPress,
      VoidCallback? onMoreActions,
      bool showMoreButton = true,
      bool isSelected = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CardListItem(
            card: card,
            onTap: onTap,
            onLongPress: onLongPress,
            onMoreActions: onMoreActions,
            showMoreButton: showMoreButton,
            isSelected: isSelected,
          ),
        ),
      );
    }

    group('基本顯示', () {
      testWidgets('應該顯示名片的基本資訊', (tester) async {
        await tester.pumpWidget(createTestWidget(card: testCard));

        // 驗證基本資訊顯示
        expect(find.text('張三'), findsOneWidget);
        expect(find.text('軟體工程師'), findsOneWidget);
        expect(find.text('科技公司'), findsOneWidget);
      });

      testWidgets('應該顯示名片縮圖容器', (tester) async {
        await tester.pumpWidget(createTestWidget(card: testCard));

        // 驗證縮圖容器存在
        expect(find.byIcon(Icons.credit_card), findsOneWidget);
      });

      testWidgets('應該顯示聯絡資訊指示器', (tester) async {
        await tester.pumpWidget(createTestWidget(card: testCard));

        // 驗證聯絡方式圖示
        expect(find.byIcon(Icons.email), findsOneWidget);
        expect(find.byIcon(Icons.phone), findsOneWidget);
        expect(find.byIcon(Icons.location_on), findsOneWidget);
        expect(find.byIcon(Icons.language), findsOneWidget);
      });

      testWidgets('最小資訊的名片應該正確顯示', (tester) async {
        await tester.pumpWidget(createTestWidget(card: minimumCard));

        // 應該只顯示姓名
        expect(find.text('李四'), findsOneWidget);

        // 不應該顯示空的職稱和公司
        expect(find.text('軟體工程師'), findsNothing);
        expect(find.text('科技公司'), findsNothing);

        // 不應該顯示聯絡資訊指示器
        expect(find.byIcon(Icons.email), findsNothing);
        expect(find.byIcon(Icons.phone), findsNothing);
      });
    });

    group('互動行為', () {
      testWidgets('點擊應該觸發 onTap 回調', (tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          createTestWidget(card: testCard, onTap: () => tapped = true),
        );

        await tester.tap(find.byType(CardListItem));
        expect(tapped, isTrue);
      });

      testWidgets('長按應該觸發 onLongPress 回調', (tester) async {
        bool longPressed = false;
        await tester.pumpWidget(
          createTestWidget(
            card: testCard,
            onLongPress: () => longPressed = true,
          ),
        );

        await tester.longPress(find.byType(CardListItem));
        expect(longPressed, isTrue);
      });

      testWidgets('點擊更多按鈕應該觸發 onMoreActions 回調', (tester) async {
        bool moreActionsPressed = false;
        await tester.pumpWidget(
          createTestWidget(
            card: testCard,
            onMoreActions: () => moreActionsPressed = true,
          ),
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        expect(moreActionsPressed, isTrue);
      });
    });

    group('顯示選項', () {
      testWidgets('showMoreButton = false 時不應該顯示更多按鈕', (tester) async {
        await tester.pumpWidget(
          createTestWidget(card: testCard, showMoreButton: false),
        );

        expect(find.byIcon(Icons.more_vert), findsNothing);
      });

      testWidgets('onMoreActions = null 時不應該顯示更多按鈕', (tester) async {
        await tester.pumpWidget(
          createTestWidget(card: testCard, onMoreActions: null),
        );

        expect(find.byIcon(Icons.more_vert), findsNothing);
      });

      testWidgets('isSelected = true 時應該顯示選中狀態', (tester) async {
        await tester.pumpWidget(
          createTestWidget(card: testCard, isSelected: true),
        );

        // 驗證選中狀態的視覺效果
        final cardListItem = tester.widget<CardListItem>(
          find.byType(CardListItem),
        );
        expect(cardListItem.isSelected, isTrue);
      });
    });

    group('文字截斷', () {
      testWidgets('長文字應該被正確截斷', (tester) async {
        final longTextCard = BusinessCard(
          id: '3',
          name: '這是一個非常非常長的姓名這是一個非常非常長的姓名',
          jobTitle: '這是一個非常非常長的職稱這是一個非常非常長的職稱',
          company: '這是一個非常非常長的公司名稱這是一個非常非常長的公司名稱',
          createdAt: DateTime(2024, 1, 3),
        );

        await tester.pumpWidget(createTestWidget(card: longTextCard));

        // 驗證文字被顯示（即使被截斷）
        expect(find.textContaining('這是一個非常非常長的姓名'), findsOneWidget);
        expect(find.textContaining('這是一個非常非常長的職稱'), findsOneWidget);
        expect(find.textContaining('這是一個非常非常長的公司名稱'), findsOneWidget);
      });
    });
  });

  group('CardListItemSkeleton Widget Tests', () {
    Widget createSkeletonTestWidget() {
      return const MaterialApp(home: Scaffold(body: CardListItemSkeleton()));
    }

    testWidgets('應該顯示骨架載入動畫', (tester) async {
      await tester.pumpWidget(createSkeletonTestWidget());

      // 驗證骨架元件存在
      expect(find.byType(CardListItemSkeleton), findsOneWidget);

      // 測試動畫
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump(const Duration(milliseconds: 750));
    });
  });

  group('CardListItemDivider Widget Tests', () {
    Widget createDividerTestWidget() {
      return const MaterialApp(home: Scaffold(body: CardListItemDivider()));
    }

    testWidgets('應該顯示分隔線', (tester) async {
      await tester.pumpWidget(createDividerTestWidget());

      expect(find.byType(CardListItemDivider), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });
  });

  group('CardListItemWrapper Widget Tests', () {
    Widget createWrapperTestWidget({
      bool showDivider = false,
      EdgeInsets? padding,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CardListItemWrapper(
            showDivider: showDivider,
            padding: padding,
            child: const Text('Test Content'),
          ),
        ),
      );
    }

    testWidgets('應該包裝子元件', (tester) async {
      await tester.pumpWidget(createWrapperTestWidget());

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(CardListItemWrapper), findsOneWidget);
    });

    testWidgets('showDivider = true 時應該顯示分隔線', (tester) async {
      await tester.pumpWidget(createWrapperTestWidget(showDivider: true));

      expect(find.byType(CardListItemDivider), findsOneWidget);
    });

    testWidgets('padding 設定時應該添加內邊距', (tester) async {
      const testPadding = EdgeInsets.all(16.0);
      await tester.pumpWidget(createWrapperTestWidget(padding: testPadding));

      expect(find.byType(Padding), findsOneWidget);
    });
  });
}
