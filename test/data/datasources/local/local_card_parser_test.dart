import 'package:busines_card_scanner_flutter/data/datasources/local/local_card_parser.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ai_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LocalCardParser parser;

  setUp(() {
    parser = LocalCardParser();
  });

  group('LocalCardParser', () {
    test('應該正確解析中文名片', () {
      // Arrange
      const ocrText = '''
      王小明
      資深軟體工程師
      科技創新股份有限公司
      電話: 02-2345-6789
      手機: 0912-345-678
      Email: xiaoming.wang@techcorp.com
      地址: 台北市信義區信義路五段7號
      www.techcorp.com
      ''';

      // Act
      final result = parser.parseCard(ocrText);

      // Assert
      expect(result.name, equals('王小明'));
      expect(result.jobTitle, contains('資深軟體工程師'));
      expect(result.company, contains('科技創新股份有限公司'));
      expect(result.phone, contains('02-2345-6789'));
      expect(result.mobile, contains('0912-345-678'));
      expect(result.email, equals('xiaoming.wang@techcorp.com'));
      expect(result.address, contains('台北市信義區信義路五段7號'));
      expect(result.website, contains('www.techcorp.com'));
      expect(result.source, equals(ParseSource.local));
      expect(result.confidence, greaterThan(0.7));
    });

    test('應該正確解析英文名片', () {
      // Arrange
      const ocrText = '''
      John Smith
      Senior Software Engineer
      Tech Innovation Inc.
      Phone: +886-2-2345-6789
      Mobile: +886-912-345-678
      Email: john.smith@techinnovation.com
      Address: 7F, No. 5, Xinyi Rd., Xinyi Dist., Taipei City
      www.techinnovation.com
      ''';

      // Act
      final result = parser.parseCard(ocrText);

      // Assert
      expect(result.name, equals('John Smith'));
      expect(result.jobTitle, contains('Senior Software Engineer'));
      expect(result.company, contains('Tech Innovation Inc.'));
      expect(result.email, equals('john.smith@techinnovation.com'));
      expect(result.website, contains('www.techinnovation.com'));
      expect(result.source, equals(ParseSource.local));
    });

    test('應該正確處理部分資訊缺失的名片', () {
      // Arrange
      const ocrText = '''
      張三豐
      總經理
      0933-123-456
      zhangsan@example.com
      ''';

      // Act
      final result = parser.parseCard(ocrText);

      // Assert
      expect(result.name, equals('張三豐'));
      expect(result.jobTitle, contains('總經理'));
      expect(result.mobile, contains('0933-123-456'));
      expect(result.email, equals('zhangsan@example.com'));
      expect(result.company, isNull);
      expect(result.address, isNull);
      expect(result.confidence, lessThan(0.7));
    });

    test('應該正確識別多個email和電話', () {
      // Arrange
      const ocrText = '''
      李四
      業務經理
      ABC有限公司
      Tel: 02-8765-4321 / 02-8765-4322
      Mobile: 0987-654-321
      Email: lisi@abc.com, sales@abc.com
      ''';

      // Act
      final result = parser.parseCard(ocrText);

      // Assert
      expect(result.name, equals('李四'));
      expect(result.company, contains('ABC有限公司'));
      expect(result.mobile, contains('0987-654-321'));
      expect(result.email, equals('lisi@abc.com')); // 應該選擇第一個
      expect(result.phone, isNotNull);
    });

    test('應該處理雜亂格式的文字', () {
      // Arrange
      const ocrText = '''
      陳    大    文
      
      執行長 | CEO
      
      創新科技有限公司 Innovation Tech Co., Ltd.
      
      手機Mobile: 0912 345 678
      電話Tel: (02) 2345-6789
      
      Email：david.chen@innovationtech.com
      
      地址：台北市大安區復興南路一段100號5樓
      ''';

      // Act
      final result = parser.parseCard(ocrText);

      // Assert
      expect(result.name, isNotNull);
      expect(result.jobTitle, isNotNull);
      expect(result.company, isNotNull);
      expect(result.mobile, isNotNull);
      expect(result.phone, isNotNull);
      expect(result.email, equals('david.chen@innovationtech.com'));
      expect(result.address, isNotNull);
    });

    test('應該返回低信心度當文字太少', () {
      // Arrange
      const ocrText = '王五';

      // Act
      final result = parser.parseCard(ocrText);

      // Assert
      expect(result.name, anyOf(equals('王五'), isNull));
      expect(result.confidence, lessThan(0.5));
    });

    test('應該處理空白輸入', () {
      // Arrange
      const ocrText = '';

      // Act
      final result = parser.parseCard(ocrText);

      // Assert
      expect(result.name, isNull);
      expect(result.company, isNull);
      expect(result.email, isNull);
      expect(result.confidence, equals(0.0));
      expect(result.source, equals(ParseSource.local));
    });

    test('應該正確識別台灣常見姓氏', () {
      // Arrange
      const testCases = ['陳小明', '林美華', '黃志明', '蔡英文', '許文龍', '郭台銘'];

      for (final name in testCases) {
        // Act
        final result = parser.parseCard(name);

        // Assert
        expect(result.name, equals(name), reason: '應該識別姓名: $name');
      }
    });

    test('應該正確識別各種電話格式', () {
      // Arrange
      const ocrText = '''
      電話1: 02-2345-6789
      電話2: (02) 2345 6789
      電話3: 02 23456789
      手機1: 0912-345-678
      手機2: 0912 345 678
      手機3: 0912345678
      國際: +886-2-2345-6789
      ''';

      // Act
      final result = parser.parseCard(ocrText);

      // Assert
      expect(result.phone, isNotNull);
      expect(result.mobile, isNotNull);
    });

    test('應該正確識別網址格式', () {
      // Arrange
      const testCases = [
        'www.example.com',
        'https://www.example.com',
        'http://example.com/path',
        'example.com.tw',
        'sub.example.com',
      ];

      for (final url in testCases) {
        // Act
        final result = parser.parseCard('公司網站: $url');

        // Assert
        expect(result.website, contains(url), reason: '應該識別網址: $url');
      }
    });
  });
}
