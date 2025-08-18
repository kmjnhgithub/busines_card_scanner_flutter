import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/entities/ocr_result.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Core Workflow Unit Tests', () {
    test('OCR processing workflow simulation', () {
      // 模擬OCR結果
      final mockOCRResult = OCRResult(
        id: 'ocr-test-001',
        rawText: '張大明\n軟體工程師\ntech@example.com\n0912-345-678',
        confidence: 0.95,
        processedAt: DateTime.now(),
      );

      // 驗證OCR結果格式
      expect(mockOCRResult.rawText, contains('張大明'));
      expect(mockOCRResult.confidence, greaterThan(0.9));
      expect(mockOCRResult.id, equals('ocr-test-001'));

      print('✅ OCR處理流程測試通過！');
      print('   - 文字信心度: ${mockOCRResult.confidence}');
      print('   - OCR結果ID: ${mockOCRResult.id}');
    });

    test('Business card validation workflow', () {
      // 測試名片驗證邏輯
      final validCard = BusinessCard(
        id: 'test-001',
        name: '王小華',
        company: '科技公司',
        jobTitle: '產品經理',
        email: 'wang@tech.com',
        phone: '0987-654-321',
        website: 'https://tech.com',
        createdAt: DateTime.now(),
      );

      // 驗證基本資訊
      expect(validCard.name, equals('王小華'));
      expect(validCard.company, equals('科技公司'));
      expect(validCard.email, equals('wang@tech.com'));
      expect(validCard.phone, equals('0987-654-321'));

      // 測試複製功能
      final updatedCard = validCard.copyWith(jobTitle: '技術總監');
      expect(updatedCard.jobTitle, equals('技術總監'));
      expect(updatedCard.name, equals(validCard.name)); // 其他欄位保持不變

      print('✅ 名片驗證流程測試通過！');
      print('   - 姓名: ${validCard.name}');
      print('   - 公司: ${validCard.company}');
      print('   - 電子郵件: ${validCard.email}');
    });

    test('Data validation and security', () {
      // 測試資料驗證和安全性

      // 測試空名稱處理
      expect(
        () => BusinessCard(id: 'test-002', name: '', createdAt: DateTime.now()),
        throwsArgumentError,
      );

      // 測試有效的最小名片
      final minimalCard = BusinessCard(
        id: 'test-003',
        name: '測試用戶',
        createdAt: DateTime.now(),
      );

      expect(minimalCard.name, equals('測試用戶'));
      expect(minimalCard.id, equals('test-003'));
      expect(minimalCard.company, isNull); // 沒有公司資訊
      expect(minimalCard.email, isNull); // 沒有聯絡資訊

      print('✅ 資料驗證和安全性測試通過！');
      print('   - 空名稱正確被拒絕');
      print('   - 最小名片格式有效');
    });

    test('Image data processing', () {
      // 模擬圖片數據處理
      final mockImageData = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // width=1, height=1
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
        0x54, 0x08, 0xD7, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
        0x00, 0x05, 0xFE, 0x02, 0xFE, 0xDC, 0xCC, 0x59,
        0xE7, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND chunk
        0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      // 驗證圖片數據
      expect(mockImageData.length, greaterThan(0));
      expect(mockImageData.first, equals(0x89)); // PNG魔數

      // 模擬OCR處理結果
      final ocrWithImage = OCRResult(
        id: 'ocr-with-image-001',
        rawText: '從圖片識別的文字',
        confidence: 0.88,
        processedAt: DateTime.now(),
        imageData: mockImageData,
        imageWidth: 1,
        imageHeight: 1,
      );

      expect(ocrWithImage.imageData, equals(mockImageData));
      expect(ocrWithImage.imageWidth, equals(1));
      expect(ocrWithImage.imageHeight, equals(1));

      print('✅ 圖片數據處理測試通過！');
      print('   - 圖片數據大小: ${mockImageData.length} bytes');
      print(
        '   - 圖片尺寸: ${ocrWithImage.imageWidth}x${ocrWithImage.imageHeight}',
      );
    });

    test('Complete workflow simulation', () {
      // 模擬完整工作流程
      final startTime = DateTime.now();

      // 步驟1：模擬OCR識別
      final ocrResult = OCRResult(
        id: 'workflow-ocr-001',
        rawText: '李經理\n台灣科技股份有限公司\n總經理\nli.manager@tech.tw\n02-2345-6789',
        confidence: 0.92,
        processedAt: startTime,
      );

      expect(ocrResult.confidence, greaterThan(0.9));

      // 步驟2：模擬AI解析和名片創建
      final businessCard = BusinessCard(
        id: 'workflow-card-001',
        name: '李經理',
        company: '台灣科技股份有限公司',
        jobTitle: '總經理',
        email: 'li.manager@tech.tw',
        phone: '02-2345-6789',
        createdAt: startTime.add(const Duration(seconds: 1)),
      );

      // 驗證工作流程結果
      expect(businessCard.name, equals('李經理'));
      expect(businessCard.company, equals('台灣科技股份有限公司'));
      expect(businessCard.email, equals('li.manager@tech.tw'));
      expect(businessCard.createdAt.isAfter(ocrResult.processedAt), true);

      print('✅ 完整工作流程模擬測試通過！');
      print('   - OCR識別 → AI解析 → 名片創建');
      print(
        '   - 處理時間: ${businessCard.createdAt.difference(ocrResult.processedAt).inMilliseconds}ms',
      );
      print('   - 最終名片: ${businessCard.name} (${businessCard.company})');
    });
  });
}
