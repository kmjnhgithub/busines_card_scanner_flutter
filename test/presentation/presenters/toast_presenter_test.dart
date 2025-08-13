import 'package:busines_card_scanner_flutter/presentation/presenters/toast_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToastMessage', () {
    test('should create ToastMessage with required parameters', () {
      // Arrange & Act
      const message = ToastMessage(
        message: 'Test message',
        type: ToastType.info,
      );

      // Assert
      expect(message.message, equals('Test message'));
      expect(message.type, equals(ToastType.info));
      expect(message.duration, equals(const Duration(seconds: 3)));
      expect(message.action, isNull);
    });

    test('should create ToastMessage with custom duration and action', () {
      // Arrange
      const customDuration = Duration(seconds: 5);
      void testCallback() {}
      final action = ToastAction(
        label: 'Undo',
        onPressed: testCallback,
      );

      // Act
      final message = ToastMessage(
        message: 'Test message',
        type: ToastType.success,
        duration: customDuration,
        action: action,
      );

      // Assert
      expect(message.message, equals('Test message'));
      expect(message.type, equals(ToastType.success));
      expect(message.duration, equals(customDuration));
      expect(message.action, equals(action));
    });

    test('should support equality comparison', () {
      // Arrange
      const message1 = ToastMessage(
        message: 'Test message',
        type: ToastType.info,
      );
      const message2 = ToastMessage(
        message: 'Test message',
        type: ToastType.info,
      );
      const message3 = ToastMessage(
        message: 'Different message',
        type: ToastType.info,
      );

      // Assert
      expect(message1, equals(message2));
      expect(message1, isNot(equals(message3)));
      expect(message1.hashCode, equals(message2.hashCode));
    });

    group('ToastType enum', () {
      test('should contain all expected toast types', () {
        expect(ToastType.values, hasLength(4));
        expect(ToastType.values, contains(ToastType.info));
        expect(ToastType.values, contains(ToastType.success));
        expect(ToastType.values, contains(ToastType.warning));
        expect(ToastType.values, contains(ToastType.error));
      });
    });
  });

  group('ToastAction', () {
    test('should create ToastAction with required parameters', () {
      // Arrange
      void testCallback() {}

      // Act
      final action = ToastAction(
        label: 'Action',
        onPressed: testCallback,
      );

      // Assert
      expect(action.label, equals('Action'));
      expect(action.onPressed, equals(testCallback));
    });

    test('should support equality comparison', () {
      // Arrange
      void testCallback() {}
      
      final action1 = ToastAction(
        label: 'Action',
        onPressed: testCallback,
      );
      final action2 = ToastAction(
        label: 'Action',
        onPressed: testCallback,
      );
      final action3 = ToastAction(
        label: 'Different',
        onPressed: testCallback,
      );

      // Assert
      expect(action1, equals(action2));
      expect(action1, isNot(equals(action3)));
      expect(action1.hashCode, equals(action2.hashCode));
    });
  });

  group('ToastPresenter', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('should be able to read toastPresenterProvider', (tester) async {
      // Act
      final presenter = container.read(toastPresenterProvider.notifier);

      // Assert
      expect(presenter, isA<ToastPresenter>());
    });

    group('ToastPresenter methods', () {
      testWidgets('showInfo should create info toast using SnackBar', (tester) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        ToastHelper.showSnackBar(
                          context,
                          'Info message',
                          type: ToastType.info,
                        );
                      },
                      child: const Text('Show Info'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Show Info'));
        await tester.pump();

        // Assert
        expect(find.text('Info message'), findsOneWidget);
      });

      testWidgets('showSuccess should create success toast', (tester) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        ToastHelper.showSnackBar(
                          context,
                          'Success message',
                          type: ToastType.success,
                        );
                      },
                      child: const Text('Show Success'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Show Success'));
        await tester.pump();

        // Assert
        expect(find.text('Success message'), findsOneWidget);
      });

      testWidgets('showWarning should create warning toast', (tester) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        ToastHelper.showSnackBar(
                          context,
                          'Warning message',
                          type: ToastType.warning,
                        );
                      },
                      child: const Text('Show Warning'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Show Warning'));
        await tester.pump();

        // Assert
        expect(find.text('Warning message'), findsOneWidget);
      });

      testWidgets('showError should create error toast', (tester) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        ToastHelper.showSnackBar(
                          context,
                          'Error message',
                          type: ToastType.error,
                        );
                      },
                      child: const Text('Show Error'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Show Error'));
        await tester.pump();

        // Assert
        expect(find.text('Error message'), findsOneWidget);
      });

      testWidgets('show should create toast with custom parameters', (tester) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        ToastHelper.showSnackBar(
                          context,
                          'Custom message',
                          type: ToastType.info,
                          duration: const Duration(milliseconds: 100),
                        );
                      },
                      child: const Text('Show Custom'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Show Custom'));
        await tester.pump();

        // Assert
        expect(find.text('Custom message'), findsOneWidget);
      });

      testWidgets('toast should disappear after duration', (tester) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Builder(
                builder: (context) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () {
                        ToastHelper.showSnackBar(
                          context,
                          'Temporary message',
                          type: ToastType.info,
                          duration: const Duration(milliseconds: 100),
                        );
                      },
                      child: const Text('Show Temporary'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.text('Show Temporary'));
        await tester.pump();

        // Assert toast is visible
        expect(find.text('Temporary message'), findsOneWidget);

        // Wait for toast to disappear
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        // Assert toast is gone
        expect(find.text('Temporary message'), findsNothing);
      });
    });
  });
}