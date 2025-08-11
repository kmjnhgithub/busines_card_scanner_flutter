import 'dart:typed_data';
import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';

void main() {
  try {
    // 測試 ParsedCardData 的 toBusinessCard 方法
    final parsedData = ParsedCardData(
      name: '王大明',
      company: '科技股份有限公司',
      confidence: 0.88,
      source: ParseSource.ai,
      parsedAt: DateTime.now(),
    );
    
    print('建立 ParsedCardData 成功');
    
    final card = parsedData.toBusinessCard(id: '');
    print('呼叫 toBusinessCard 成功');
    print('Card name: ${card.name}');
    
  } catch (e, stackTrace) {
    print('錯誤: $e');
    print('堆疊追蹤: $stackTrace');
  }
}