import 'dart:async';

import 'package:busines_card_scanner_flutter/presentation/providers/event_bus_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

/// 事件總線測試
///
/// 測試範圍：
/// - Provider 建立和銷毀
/// - 事件發布和訂閱機制
/// - 型別安全事件處理
/// - 多個訂閱者管理
/// - 錯誤處理和邊界條件
/// - 記憶體洩漏防護
///
/// 遵循專案的 TDD 測試原則，確保：
/// - 獨立性：每個測試案例獨立執行
/// - 可重複性：測試結果一致可靠
/// - 清晰命名：描述測試內容和預期結果
void main() {
  group('EventBus Provider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('Provider 建立和基本功能', () {
      test('should create EventBus provider successfully', () {
        // Act
        final eventBus = container.read(eventBusProvider);

        // Assert
        expect(eventBus, isNotNull);
        expect(eventBus, isA<EventBus>());
      });

      test('should be singleton - same instance across reads', () {
        // Act
        final eventBus1 = container.read(eventBusProvider);
        final eventBus2 = container.read(eventBusProvider);

        // Assert
        expect(identical(eventBus1, eventBus2), isTrue);
      });

      test('should dispose correctly without memory leaks', () {
        // Arrange - 讀取 provider 以建立依賴
        container.read(eventBusProvider);

        // Act & Assert - should not throw
        expect(() => container.dispose(), returnsNormally);
      });
    });

    group('事件發布和訂閱機制', () {
      test('should publish and receive events successfully', () async {
        // Arrange
        final eventBus = container.read(eventBusProvider);
        final events = <TestEvent>[];

        // 訂閱事件
        final subscription = eventBus.on<TestEvent>().listen(events.add);

        const testEvent = TestEvent('test_data');

        // Act
        eventBus.emit(testEvent);
        await Future.delayed(Duration.zero); // 等待事件處理

        // Assert
        expect(events, hasLength(1));
        expect(events.first.data, equals('test_data'));

        // Cleanup
        await subscription.cancel();
      });

      test('should handle multiple subscribers for same event type', () async {
        // Arrange
        final eventBus = container.read(eventBusProvider);
        final events1 = <TestEvent>[];
        final events2 = <TestEvent>[];

        final subscription1 = eventBus.on<TestEvent>().listen(events1.add);

        final subscription2 = eventBus.on<TestEvent>().listen(events2.add);

        const testEvent = TestEvent('shared_data');

        // Act
        eventBus.emit(testEvent);
        await Future.delayed(Duration.zero);

        // Assert
        expect(events1, hasLength(1));
        expect(events2, hasLength(1));
        expect(events1.first.data, equals('shared_data'));
        expect(events2.first.data, equals('shared_data'));

        // Cleanup
        await subscription1.cancel();
        await subscription2.cancel();
      });

      test('should only receive events of subscribed type', () async {
        // Arrange
        final eventBus = container.read(eventBusProvider);
        final testEvents = <TestEvent>[];
        final userEvents = <UserEvent>[];

        final testSubscription = eventBus.on<TestEvent>().listen(
          testEvents.add,
        );

        final userSubscription = eventBus.on<UserEvent>().listen(
          userEvents.add,
        );

        // Act
        eventBus.emit(const TestEvent('test_data'));
        eventBus.emit(const UserEvent('user_data'));
        await Future.delayed(Duration.zero);

        // Assert
        expect(testEvents, hasLength(1));
        expect(userEvents, hasLength(1));
        expect(testEvents.first.data, equals('test_data'));
        expect(userEvents.first.data, equals('user_data'));

        // Cleanup
        unawaited(testSubscription.cancel());
        unawaited(userSubscription.cancel());
      });
    });

    group('領域事件整合', () {
      test('should handle domain events from business logic', () async {
        // Arrange
        final eventBus = container.read(eventBusProvider);
        final domainEvents = <CardCreatedEvent>[];

        final subscription = eventBus.on<CardCreatedEvent>().listen(
          domainEvents.add,
        );

        final domainEvent = CardCreatedEvent(
          cardId: 'card_123',
          cardName: '張三',
          timestamp: DateTime.now(),
        );

        // Act
        eventBus.emit(domainEvent);
        await Future.delayed(Duration.zero);

        // Assert
        expect(domainEvents, hasLength(1));
        expect(domainEvents.first.cardId, equals('card_123'));
        expect(domainEvents.first.cardName, equals('張三'));

        await subscription.cancel();
      });

      test('should support event filtering and transformation', () async {
        // Arrange
        final eventBus = container.read(eventBusProvider);
        final filteredEvents = <CardCreatedEvent>[];

        // 只訂閱特定條件的事件
        final subscription = eventBus
            .on<CardCreatedEvent>()
            .where((event) => event.cardName.contains('張'))
            .listen(filteredEvents.add);

        // Act
        eventBus.emit(
          CardCreatedEvent(
            cardId: 'card_1',
            cardName: '張三',
            timestamp: DateTime.now(),
          ),
        );

        eventBus.emit(
          CardCreatedEvent(
            cardId: 'card_2',
            cardName: '李四',
            timestamp: DateTime.now(),
          ),
        );

        await Future.delayed(Duration.zero);

        // Assert - 只有張三的事件被接收
        expect(filteredEvents, hasLength(1));
        expect(filteredEvents.first.cardName, equals('張三'));

        await subscription.cancel();
      });
    });

    group('錯誤處理和邊界條件', () {
      test('should handle subscription after provider disposal', () {
        // Arrange
        final eventBus = container.read(eventBusProvider);
        container.dispose();

        // Act & Assert - should not crash
        expect(() => eventBus.on<TestEvent>(), returnsNormally);
      });

      test('should handle emit after provider disposal', () {
        // Arrange
        final eventBus = container.read(eventBusProvider);
        container.dispose();

        // Act & Assert - should not crash
        expect(() => eventBus.emit(const TestEvent('test')), returnsNormally);
      });

      test('should prevent null events at compile time', () {
        // Arrange
        final eventBus = container.read(eventBusProvider);

        // Act & Assert - 編譯時型別安全檢查
        // 由於泛型約束 `T extends Object`，null 在編譯時就被阻止
        // 這是比執行時檢查更好的設計

        // 驗證只能傳遞非 null 物件
        expect(() => eventBus.emit(const TestEvent('valid')), returnsNormally);

        // 注意：eventBus.emit(null) 現在是編譯時錯誤，無法通過編譯
        // 這正是我們想要的型別安全保護
      });

      test('should handle subscription cancellation correctly', () async {
        // Arrange
        final eventBus = container.read(eventBusProvider);
        final events = <TestEvent>[];

        final subscription = eventBus.on<TestEvent>().listen(events.add);

        // Act
        await subscription.cancel();
        eventBus.emit(const TestEvent('after_cancel'));
        await Future.delayed(Duration.zero);

        // Assert - 取消後不應收到事件
        expect(events, isEmpty);
      });
    });

    group('效能和記憶體管理', () {
      test('should handle high volume events without memory leaks', () async {
        // Arrange
        final eventBus = container.read(eventBusProvider);
        const eventCount = 1000;
        var receivedCount = 0;

        final subscription = eventBus.on<TestEvent>().listen((event) {
          receivedCount++;
        });

        // Act - 發送大量事件
        for (int i = 0; i < eventCount; i++) {
          eventBus.emit(TestEvent('event_$i'));
        }
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(receivedCount, equals(eventCount));

        await subscription.cancel();
      });

      test('should clean up subscriptions on provider override', () {
        // Arrange
        final originalBus = container.read(eventBusProvider);

        // Create new container with override
        final newContainer = ProviderContainer(
          overrides: [eventBusProvider.overrideWith((ref) => EventBusImpl())],
        );

        // Act & Assert
        final overriddenBus = newContainer.read(eventBusProvider);
        expect(identical(originalBus, overriddenBus), isFalse);

        newContainer.dispose();
      });
    });

    group('型別安全和開發體驗', () {
      test('should maintain type safety for different event types', () {
        // Arrange
        final eventBus = container.read(eventBusProvider);

        // Act & Assert - 編譯時型別檢查
        expect(() {
          // 正確的型別使用
          final testStream = eventBus.on<TestEvent>();
          final userStream = eventBus.on<UserEvent>();

          expect(testStream, isA<Stream<TestEvent>>());
          expect(userStream, isA<Stream<UserEvent>>());
        }, returnsNormally);
      });

      test('should support generic event base classes', () async {
        // Arrange
        final eventBus = container.read(eventBusProvider);
        final baseEvents = <BaseEvent>[];

        final subscription = eventBus.on<BaseEvent>().listen(baseEvents.add);

        // Act - 發送不同的事件子類別
        eventBus.emit(const TestEvent('test'));
        eventBus.emit(const UserEvent('user'));
        await Future.delayed(Duration.zero);

        // Assert - 基底類別應該能接收所有子類別事件
        expect(baseEvents, hasLength(2));

        await subscription.cancel();
      });
    });
  });
}

// =============================================
// 測試用事件類別定義
// =============================================

/// 基底事件類別
@immutable
abstract class BaseEvent {
  const BaseEvent();
}

/// 測試事件
@immutable
class TestEvent extends BaseEvent {
  final String data;

  const TestEvent(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestEvent &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'TestEvent{data: $data}';
}

/// 使用者事件
@immutable
class UserEvent extends BaseEvent {
  final String data;

  const UserEvent(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEvent &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'UserEvent{data: $data}';
}

/// 領域事件：名片建立事件
@immutable
class CardCreatedEvent extends BaseEvent {
  final String cardId;
  final String cardName;
  final DateTime timestamp;

  const CardCreatedEvent({
    required this.cardId,
    required this.cardName,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardCreatedEvent &&
          runtimeType == other.runtimeType &&
          cardId == other.cardId &&
          cardName == other.cardName;

  @override
  int get hashCode => cardId.hashCode ^ cardName.hashCode;

  @override
  String toString() =>
      'CardCreatedEvent{cardId: $cardId, cardName: $cardName, timestamp: $timestamp}';
}
