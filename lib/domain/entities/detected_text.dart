import 'package:equatable/equatable.dart';

/// 偵測到的文字區塊
///
/// 代表 OCR 處理過程中偵測到的單一文字區塊，
/// 包含文字內容、信心度、邊界框等詳細資訊。
/// 遵循 Clean Architecture 原則，此實體不依賴外部框架。
class DetectedText extends Equatable {
  /// 偵測到的文字內容
  final String text;

  /// 信心度（0.0 到 1.0）
  final double confidence;

  /// 文字區塊的邊界框
  final BoundingBox boundingBox;

  /// 語言代碼（可選）
  final String? languageCode;

  const DetectedText({
    required this.text,
    required this.confidence,
    required this.boundingBox,
    this.languageCode,
  });

  /// 檢查是否為高信心度文字
  ///
  /// 高信心度定義為 confidence >= 0.8
  bool isHighConfidence() {
    return confidence >= 0.8;
  }

  /// 檢查是否為空白或無意義文字
  bool isEmptyOrMeaningless() {
    final trimmed = text.trim();
    return trimmed.isEmpty || trimmed.length < 2;
  }

  /// 取得文字長度
  int get textLength => text.length;

  /// 取得清理後的文字（移除多餘空白）
  String get cleanedText => text.trim().replaceAll(RegExp(r'\s+'), ' ');

  @override
  List<Object?> get props => [text, confidence, boundingBox, languageCode];

  @override
  String toString() {
    return 'DetectedText('
        'text: "$text", '
        'confidence: ${confidence.toStringAsFixed(2)}, '
        'boundingBox: $boundingBox'
        '${languageCode != null ? ', language: $languageCode' : ''}'
        ')';
  }
}

/// 文字區塊的邊界框
///
/// 定義偵測到的文字在圖片中的位置和大小。
/// 座標系統：(0,0) 為左上角，向右為 X 軸正方向，向下為 Y 軸正方向。
class BoundingBox extends Equatable {
  /// 左上角 X 座標
  final double left;

  /// 左上角 Y 座標
  final double top;

  /// 寬度
  final double width;

  /// 高度
  final double height;

  const BoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// 建立來自四個角落座標的邊界框
  factory BoundingBox.fromCorners({
    required num left,
    required num top,
    required num right,
    required num bottom,
  }) {
    return BoundingBox(
      left: left.toDouble(),
      top: top.toDouble(),
      width: (right - left).toDouble(),
      height: (bottom - top).toDouble(),
    );
  }

  /// 建立來自中心點和尺寸的邊界框
  factory BoundingBox.fromCenter({
    required num centerX,
    required num centerY,
    required num width,
    required num height,
  }) {
    return BoundingBox(
      left: (centerX - width / 2).toDouble(),
      top: (centerY - height / 2).toDouble(),
      width: width.toDouble(),
      height: height.toDouble(),
    );
  }

  /// 右邊界 X 座標
  double get right => left + width;

  /// 下邊界 Y 座標
  double get bottom => top + height;

  /// 中心點 X 座標
  double get centerX => left + width / 2;

  /// 中心點 Y 座標
  double get centerY => top + height / 2;

  /// 面積
  double get area => width * height;

  /// 檢查邊界框是否有效（尺寸為正數）
  bool get isValid => width > 0 && height > 0;

  /// 檢查是否包含某個點
  bool containsPoint(double x, double y) {
    return x >= left && x <= right && y >= top && y <= bottom;
  }

  /// 檢查是否與另一個邊界框重疊
  bool intersects(BoundingBox other) {
    return left < other.right &&
        right > other.left &&
        top < other.bottom &&
        bottom > other.top;
  }

  /// 計算與另一個邊界框的重疊面積
  double getIntersectionArea(BoundingBox other) {
    if (!intersects(other)) {
      return 0;
    }

    final intersectionLeft = left > other.left ? left : other.left;
    final intersectionTop = top > other.top ? top : other.top;
    final intersectionRight = right < other.right ? right : other.right;
    final intersectionBottom = bottom < other.bottom ? bottom : other.bottom;

    final intersectionWidth = intersectionRight - intersectionLeft;
    final intersectionHeight = intersectionBottom - intersectionTop;

    return intersectionWidth * intersectionHeight;
  }

  /// 擴展邊界框（向外擴展指定的邊距）
  BoundingBox expand(double margin) {
    return BoundingBox(
      left: left - margin,
      top: top - margin,
      width: width + 2 * margin,
      height: height + 2 * margin,
    );
  }

  /// 縮放邊界框
  BoundingBox scale(double factor) {
    final newWidth = width * factor;
    final newHeight = height * factor;
    final deltaWidth = newWidth - width;
    final deltaHeight = newHeight - height;

    return BoundingBox(
      left: left - deltaWidth / 2,
      top: top - deltaHeight / 2,
      width: newWidth,
      height: newHeight,
    );
  }

  /// 限制邊界框在指定範圍內
  BoundingBox clamp({
    required double maxX,
    required double maxY,
    double minX = 0,
    double minY = 0,
  }) {
    final clampedLeft = left.clamp(minX.toDouble(), (maxX - width).toDouble());
    final clampedTop = top.clamp(minY.toDouble(), (maxY - height).toDouble());
    final clampedWidth = width.clamp(0.0, maxX - clampedLeft);
    final clampedHeight = height.clamp(0.0, maxY - clampedTop);

    return BoundingBox(
      left: clampedLeft,
      top: clampedTop,
      width: clampedWidth,
      height: clampedHeight,
    );
  }

  @override
  List<Object?> get props => [left, top, width, height];

  @override
  String toString() {
    return 'BoundingBox('
        'left: ${left.toStringAsFixed(1)}, '
        'top: ${top.toStringAsFixed(1)}, '
        'width: ${width.toStringAsFixed(1)}, '
        'height: ${height.toStringAsFixed(1)}'
        ')';
  }
}

/// 矩形區域（Rect 的簡化版本）
///
/// 用於與其他圖形庫互操作時的類型轉換
class Rect extends Equatable {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// 從 BoundingBox 建立 Rect
  factory Rect.fromBoundingBox(BoundingBox box) {
    return Rect(
      left: box.left,
      top: box.top,
      right: box.right,
      bottom: box.bottom,
    );
  }

  /// 轉換為 BoundingBox
  BoundingBox toBoundingBox() {
    return BoundingBox(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
    );
  }

  double get width => right - left;
  double get height => bottom - top;

  @override
  List<Object?> get props => [left, top, right, bottom];
}
