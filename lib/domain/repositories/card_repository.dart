import 'package:busines_card_scanner_flutter/domain/repositories/card_reader.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/card_writer.dart';

/// 名片存取 Repository 主要介面
///
/// 遵循介面隔離原則（ISP）和組合模式，將 CardReader 和 CardWriter 組合成
/// 完整的 Repository 介面。這樣的設計優點：
///
/// - **靈活性**：可以只實作讀取或寫入功能的部分實作
/// - **測試性**：可以分別對讀取和寫入功能進行單元測試
/// - **權限控制**：可以根據使用者權限提供不同的介面
/// - **單一職責**：每個介面專注於特定的操作類型
///
/// 使用範例：
/// ```dart
/// // 完整功能的 Repository
/// final repository = CardRepositoryImpl();
/// await repository.saveCard(newCard);
/// final cards = await repository.getCards();
///
/// // 只需要讀取功能的場景
/// CardReader reader = repository;
/// final cards = await reader.getCards();
/// // reader.saveCard() 不可用，編譯時錯誤
///
/// // 只需要寫入功能的場景
/// CardWriter writer = repository;
/// await writer.saveCard(card);
/// // writer.getCards() 不可用，編譯時錯誤
/// ```
abstract class CardRepository implements CardReader, CardWriter {
  // 此介面不定義額外方法，純粹作為 CardReader 和 CardWriter 的組合
  // 所有方法繼承自父介面

  /// Repository 實作的識別名稱
  ///
  /// 用於除錯和日誌記錄，幫助識別使用的是哪種實作
  String get implementationName;

  /// 檢查 Repository 連線狀態
  ///
  /// 回傳 true 如果可以正常存取資料來源
  Future<bool> isHealthy();

  /// 清理和釋放資源
  ///
  /// 在不再使用 Repository 時調用，用於關閉資料庫連線、
  /// 清理快取等清理工作
  Future<void> dispose();
}
