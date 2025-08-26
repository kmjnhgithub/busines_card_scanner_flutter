import 'dart:async';

/// 防抖器工具類
///
/// 用於防止短時間內頻繁觸發同一個操作
/// 常用於搜尋輸入框、按鈕點擊等場景
class Debouncer {
  /// 延遲時間
  final Duration delay;

  /// 內部計時器
  Timer? _timer;

  /// 建立防抖器
  ///
  /// [delay] 延遲時間，預設為 300 毫秒
  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// 執行防抖操作
  ///
  /// 如果在 [delay] 時間內再次呼叫，會取消前一次的操作並重新計時
  /// [action] 要執行的操作
  void run(VoidCallback action) {
    // 取消之前的計時器
    _timer?.cancel();

    // 設定新的計時器
    _timer = Timer(delay, action);
  }

  /// 立即執行操作並取消計時器
  void runNow(VoidCallback action) {
    _timer?.cancel();
    action.call();
  }

  /// 取消當前的防抖操作
  void cancel() {
    _timer?.cancel();
  }

  /// 清理資源
  void dispose() {
    _timer?.cancel();
  }

  /// 檢查是否有待執行的操作
  bool get isActive => _timer?.isActive ?? false;
}

/// VoidCallback 類型定義
typedef VoidCallback = void Function();
