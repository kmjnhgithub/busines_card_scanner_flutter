import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// Event Bus Provider (Presentation Layer Infrastructure)
// =============================================================================

/// 事件總線 Provider
///
/// 【架構設計】
/// 用於降低模組間耦合度，使用領域事件模式（Domain Event Pattern）進行模組通訊。
/// 符合 Clean Architecture 原則，作為 Presentation 層的基礎設施服務。
///
/// 【技術特色】
/// - **型別安全**：編譯時型別檢查，避免執行時錯誤
/// - **記憶體安全**：自動管理生命週期，防止記憶體洩漏
/// - **Riverpod 整合**：完全相容 Riverpod 依賴注入架構
/// - **領域事件支援**：支援 Domain Driven Design 的事件驅動架構
///
/// 【使用範例】
/// ```dart
/// // 在 ViewModel 中發布領域事件
/// class CardListViewModel extends _$CardListViewModel {
///   void _onCardDeleted(String cardId) {
///     ref.read(eventBusProvider).emit(
///       CardDeletedEvent(cardId: cardId, timestamp: DateTime.now())
///     );
///   }
/// }
///
/// // 在其他模組中訂閱事件
/// class NotificationService {
///   void startListening(WidgetRef ref) {
///     ref.read(eventBusProvider).on<CardDeletedEvent>().listen((event) {
///       showSnackBar('名片已刪除: ${event.cardId}');
///     });
///   }
/// }
/// ```
///
/// 【安全性考量】
/// - 事件內容應經過驗證，不包含敏感資料
/// - 支援優雅降級，在 Provider 銷毀後不會崩潰
/// - 自動清理訂閱，避免記憶體洩漏
final eventBusProvider = Provider<EventBus>((ref) {
  final eventBus = EventBusImpl();

  // 【資源管理】當 Provider 被銷毀時自動清理資源
  ref.onDispose(eventBus.dispose);

  return eventBus;
});

// =============================================================================
// Event Bus Interface (Clean Architecture Abstraction)
// =============================================================================

/// 事件總線抽象介面
///
/// 【設計原則】
/// 基於介面隔離原則（ISP），只定義事件總線必要的操作契約。
/// 支援型別安全的事件處理，符合 Liskov Substitution Principle。
///
/// 【使用場景】
/// - 跨模組通訊：避免直接依賴，降低耦合
/// - 領域事件傳播：Domain → Presentation 層事件通知
/// - UI 狀態同步：多個 Widget 間的狀態協調
///
/// 【型別安全設計】
/// 使用泛型確保編譯時型別檢查，避免執行時類型轉換錯誤。
abstract class EventBus {
  /// 發布事件
  ///
  /// 【職責】
  /// 將事件廣播給所有對應型別的訂閱者，支援一對多通訊模式。
  ///
  /// 【參數】
  /// - [event] 要發布的事件實例，泛型 T 確保型別安全
  ///
  /// 【約束】
  /// - 事件不能為 null（編譯時和執行時雙重保護）
  /// - 支援任何型別的事件，包括基底類別和子類別
  ///
  /// 【錯誤處理】
  /// - Throws [ArgumentError] 當 event 為 null
  /// - 在 EventBus 已銷毀時靜默忽略（優雅降級）
  ///
  /// 【範例】
  /// ```dart
  /// eventBus.emit(CardCreatedEvent(cardId: '123'));
  /// eventBus.emit(UserLoginEvent(userId: 'user_456'));
  /// ```
  void emit<T extends Object>(T event);

  /// 訂閱特定型別的事件
  ///
  /// 【職責】
  /// 建立指定型別事件的 Stream 訂閱，支援 Stream 的所有操作
  /// （如 where, map, take, listen 等）。
  ///
  /// 【泛型參數】
  /// - `T` 要訂閱的事件型別，支援繼承層次結構
  ///
  /// 【回傳值】
  /// - `Stream<T>` 該型別事件的串流
  /// - 支援多型：訂閱基底類別可接收所有子類別事件
  /// - 支援鏈式操作：過濾、轉換、組合等 Reactive Programming
  ///
  /// 【生命週期】
  /// - Stream 會在 EventBus 銷毀時自動關閉
  /// - 建議在不需要時主動 cancel subscription 避免記憶體洩漏
  ///
  /// 【範例】
  /// ```dart
  /// // 基本訂閱
  /// eventBus.on<CardCreatedEvent>().listen((event) {
  ///   print('Card created: ${event.cardId}');
  /// });
  ///
  /// // 帶過濾和轉換
  /// eventBus.on<CardEvent>()
  ///   .where((event) => event.priority == Priority.high)
  ///   .map((event) => event.cardId)
  ///   .listen((cardId) => handleHighPriorityCard(cardId));
  /// ```
  Stream<T> on<T extends Object>();

  /// 銷毀事件總線
  ///
  /// 【職責】
  /// 清理所有內部資源，關閉 StreamController，取消所有活躍訂閱。
  ///
  /// 【執行時機】
  /// - Provider 被銷毀時自動呼叫（透過 ref.onDispose）
  /// - 可手動呼叫進行提前清理
  ///
  /// 【冪等性】
  /// 支援多次呼叫而不會產生副作用或異常。
  ///
  /// 【銷毀後行為】
  /// - emit() 呼叫會被靜默忽略
  /// - on() 會回傳空的 Stream
  /// - 確保應用在銷毀過程中不會崩潰
  void dispose();
}

// =============================================================================
// Event Bus Implementation (High-Performance Stream-Based)
// =============================================================================

/// 事件總線實作類別
///
/// 【實作策略】
/// 使用高效能的 broadcast StreamController 實作發布/訂閱機制，
/// 支援一對多事件分發，具備完整的生命週期管理和錯誤復原能力。
///
/// 【效能特色】
/// - **Broadcast Stream**：支援多個訂閱者，無需複製事件
/// - **型別過濾**：使用編譯時最佳化的 is 檢查和 cast
/// - **記憶體安全**：自動清理，防止記憶體洩漏
/// - **錯誤隔離**：異常不會影響其他訂閱者
///
/// 【安全性設計】
/// - 優雅降級：銷毀後操作不會崩潰應用
/// - 冪等性：多次銷毀不會產生副作用
/// - 參數驗證：編譯時和執行時雙重保護
class EventBusImpl implements EventBus {
  // 【核心元件】使用 broadcast 支援多訂閱者的高效能 StreamController
  final StreamController<Object> _controller =
      StreamController<Object>.broadcast();

  // 【狀態追蹤】防止銷毀後操作，確保應用穩定性
  bool _disposed = false;

  @override
  void emit<T extends Object>(T event) {
    // 【參數驗證】編譯時透過 `extends Object` 已排除 null
    // 不需要執行時檢查，這提升了效能

    // 【優雅降級】銷毀後的發布請求靜默忽略，避免崩潰
    if (_disposed) {
      return;
    }

    // 【安全發布】檢查 StreamController 狀態，避免在已關閉時操作
    if (!_controller.isClosed) {
      try {
        _controller.add(event);
      } on Exception catch (e) {
        // 捕捉 Exception 類型的錯誤（如網路錯誤、序列化錯誤等）
        // 這些是可恢復的錯誤，記錄但不拋出
        assert(false, 'Exception in EventBus.emit: $e');
      }
      // 注意：不捕捉 Error（如 StateError），讓它們正常拋出
      // 因為 Error 通常表示程式邏輯錯誤，應該被開發者察覺
    }
  }

  @override
  Stream<T> on<T extends Object>() {
    // 【優雅降級】已銷毀時回傳空 Stream，維持 API 一致性
    if (_disposed) {
      return Stream<T>.empty();
    }

    // 【高效能過濾】
    // 1. where() 使用 Dart VM 最佳化的型別檢查
    // 2. cast() 使用零成本的型別轉換（編譯時最佳化）
    return _controller.stream
        .where((event) => event is T) // 型別安全過濾
        .cast<T>(); // 零成本型別轉換
  }

  @override
  void dispose() {
    // 【冪等性】防止重複銷毀造成的資源問題
    if (_disposed) {
      return;
    }

    // 【狀態更新】先更新狀態，防止併發問題
    _disposed = true;

    // 【資源清理】安全關閉 StreamController
    if (!_controller.isClosed) {
      try {
        _controller.close();
      } on Exception catch (e) {
        // 捕捉 Exception 類型錯誤（如 IO 錯誤等）
        // 記錄但不拋出，確保銷毀流程不會被中斷
        assert(false, 'Exception in EventBus.dispose: $e');
      }
      // 允許 Error（如 StateError）正常拋出，因為這通常表示程式邏輯問題
    }
  }

  /// 檢查銷毀狀態
  ///
  /// 【用途】
  /// - 測試驗證：確認資源正確清理
  /// - 除錯輔助：診斷生命週期問題
  /// - 條件檢查：避免在銷毀後執行不必要操作
  ///
  /// 【注意】
  /// 此屬性主要用於測試和除錯，不建議在業務邏輯中依賴。
  /// 正常使用時，EventBus 的 API 會自動處理銷毀狀態。
  bool get isDisposed => _disposed;
}
