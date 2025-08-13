import 'package:busines_card_scanner_flutter/core/utils/string_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StringUtils Tests', () {
    group('cleanWhitespace', () {
      test('should remove leading and trailing whitespace', () {
        expect(StringUtils.cleanWhitespace('  hello world  '), 'hello world');
        expect(StringUtils.cleanWhitespace('\t\n hello \t\n'), 'hello');
      });

      test('should merge multiple spaces into single space', () {
        expect(StringUtils.cleanWhitespace('hello    world'), 'hello world');
        expect(StringUtils.cleanWhitespace('a  b   c    d'), 'a b c d');
      });

      test('should handle empty and whitespace-only strings', () {
        expect(StringUtils.cleanWhitespace(''), '');
        expect(StringUtils.cleanWhitespace('   '), '');
        expect(StringUtils.cleanWhitespace('\t\n'), '');
      });
    });

    group('removeControlCharacters', () {
      test(
        'should remove control characters but preserve newlines and tabs',
        () {
          const input = 'hello\x00\x01world\n\ttest\x1F';
          const expected = 'helloworld\n\ttest';
          expect(StringUtils.removeControlCharacters(input), expected);
        },
      );

      test('should handle empty string', () {
        expect(StringUtils.removeControlCharacters(''), '');
      });
    });

    group('isNullOrWhitespace', () {
      test('should return true for null and empty strings', () {
        expect(StringUtils.isNullOrWhitespace(null), true);
        expect(StringUtils.isNullOrWhitespace(''), true);
        expect(StringUtils.isNullOrWhitespace('   '), true);
        expect(StringUtils.isNullOrWhitespace('\t\n'), true);
      });

      test('should return false for non-empty strings', () {
        expect(StringUtils.isNullOrWhitespace('hello'), false);
        expect(StringUtils.isNullOrWhitespace(' a '), false);
      });
    });

    group('isNumericOnly', () {
      test('should return true for numeric strings', () {
        expect(StringUtils.isNumericOnly('123'), true);
        expect(StringUtils.isNumericOnly('0'), true);
        expect(StringUtils.isNumericOnly('1234567890'), true);
      });

      test('should return false for non-numeric strings', () {
        expect(StringUtils.isNumericOnly('12a3'), false);
        expect(StringUtils.isNumericOnly(''), false);
        expect(StringUtils.isNumericOnly('12.3'), false);
        expect(StringUtils.isNumericOnly('+123'), false);
      });
    });

    group('containsChinese', () {
      test('should detect Chinese characters', () {
        expect(StringUtils.containsChinese('你好'), true);
        expect(StringUtils.containsChinese('hello 世界'), true);
        expect(StringUtils.containsChinese('王小明'), true);
      });

      test('should return false for non-Chinese text', () {
        expect(StringUtils.containsChinese('hello world'), false);
        expect(StringUtils.containsChinese('123'), false);
        expect(StringUtils.containsChinese(''), false);
      });
    });

    group('isSafeText', () {
      test('should return true for safe text', () {
        expect(StringUtils.isSafeText('hello world'), true);
        expect(StringUtils.isSafeText('你好世界'), true);
        expect(StringUtils.isSafeText('John Doe, Inc.'), true);
        expect(StringUtils.isSafeText("O'Connor"), true);
        expect(StringUtils.isSafeText(''), true);
      });

      test('should return false for potentially unsafe text', () {
        expect(StringUtils.isSafeText('<script>'), false);
        expect(StringUtils.isSafeText('hello\x00world'), false);
        expect(StringUtils.isSafeText('test"quote'), false);
      });
    });

    group('truncate', () {
      test('should truncate long strings', () {
        expect(StringUtils.truncate('hello world', 8), 'hello...');
        expect(StringUtils.truncate('test', 10), 'test');
        expect(
          StringUtils.truncate('hello world', 8, suffix: '---'),
          'hello---',
        );
      });

      test('should handle edge cases', () {
        expect(StringUtils.truncate('hello', 3), '...');
        expect(StringUtils.truncate('hello', 2), '..');
        expect(StringUtils.truncate('', 5), '');
      });
    });

    group('formatPhoneNumber', () {
      test('should format Taiwan mobile numbers', () {
        expect(StringUtils.formatPhoneNumber('0912345678'), '0912-345-678');
        expect(StringUtils.formatPhoneNumber('09-1234-5678'), '0912-345-678');
        expect(StringUtils.formatPhoneNumber('(09) 1234-5678'), '0912-345-678');
      });

      test('should format Taiwan landline numbers', () {
        expect(StringUtils.formatPhoneNumber('0212345678'), '(02) 1234-5678');
        expect(StringUtils.formatPhoneNumber('02-12345678'), '(02) 1234-5678');
      });

      test('should format international numbers', () {
        expect(
          StringUtils.formatPhoneNumber('886912345678'),
          '+886 9 1234-5678',
        );
      });

      test('should return original for unrecognized formats', () {
        expect(StringUtils.formatPhoneNumber('123'), '123');
        expect(StringUtils.formatPhoneNumber(''), '');
      });
    });

    group('maskSensitiveInfo', () {
      test('should mask sensitive information', () {
        expect(StringUtils.maskSensitiveInfo('1234567890'), '******7890');
        expect(StringUtils.maskSensitiveInfo('abcd'), '****');
        expect(StringUtils.maskSensitiveInfo('ab'), '**');
      });

      test('should handle custom visible chars', () {
        expect(
          StringUtils.maskSensitiveInfo('1234567890', visibleChars: 2),
          '********90',
        );
      });
    });

    group('extractInitials', () {
      test('should extract initials from names', () {
        expect(StringUtils.extractInitials('John Doe'), 'JD');
        expect(StringUtils.extractInitials('Mary Jane Watson'), 'MJ');
        expect(StringUtils.extractInitials('   John   Doe   '), 'JD');
      });

      test('should handle single names and edge cases', () {
        expect(StringUtils.extractInitials('John'), 'J');
        expect(StringUtils.extractInitials(''), '');
        expect(StringUtils.extractInitials('   '), '');
      });
    });

    group('isValidEmailFormat', () {
      test('should validate correct email formats', () {
        expect(StringUtils.isValidEmailFormat('test@example.com'), true);
        expect(StringUtils.isValidEmailFormat('user.name@domain.co.uk'), true);
        expect(StringUtils.isValidEmailFormat('email@123.123.123.123'), true);
      });

      test('should reject invalid email formats', () {
        expect(StringUtils.isValidEmailFormat('plainaddress'), false);
        expect(StringUtils.isValidEmailFormat('@missingdomain.com'), false);
        expect(StringUtils.isValidEmailFormat('missing@.com'), false);
        expect(StringUtils.isValidEmailFormat(''), false);
      });
    });

    group('isValidUrlFormat', () {
      test('should validate correct URL formats', () {
        expect(StringUtils.isValidUrlFormat('https://example.com'), true);
        expect(StringUtils.isValidUrlFormat('http://test.com'), true);
        expect(StringUtils.isValidUrlFormat('ftp://ftp.example.com'), true);
      });

      test('should reject invalid URL formats', () {
        expect(StringUtils.isValidUrlFormat('example.com'), false);
        expect(StringUtils.isValidUrlFormat('javascript:alert(1)'), false);
        expect(StringUtils.isValidUrlFormat(''), false);
      });
    });

    group('safeEquals', () {
      test('should compare strings safely', () {
        expect(StringUtils.safeEquals('hello', 'hello'), true);
        expect(StringUtils.safeEquals('hello', 'world'), false);
        expect(StringUtils.safeEquals('', ''), true);
      });

      test('should handle different length strings', () {
        expect(StringUtils.safeEquals('hello', 'hello world'), false);
        expect(StringUtils.safeEquals('a', 'ab'), false);
      });
    });

    group('sanitizeFileName', () {
      test('should remove dangerous characters from filenames', () {
        expect(StringUtils.sanitizeFileName('file<name>'), 'file_name_');
        expect(StringUtils.sanitizeFileName('test/file.txt'), 'test_file.txt');
        expect(StringUtils.sanitizeFileName('file|name'), 'file_name');
      });

      test('should handle edge cases', () {
        expect(StringUtils.sanitizeFileName(''), 'unnamed');
        expect(StringUtils.sanitizeFileName('...'), 'unnamed');
        expect(StringUtils.sanitizeFileName('   '), 'unnamed');
      });
    });

    group('extractEmails', () {
      test('should extract valid email addresses from text', () {
        const text = 'Contact us at info@company.com or support@test.org';
        final emails = StringUtils.extractEmails(text);
        expect(emails, contains('info@company.com'));
        expect(emails, contains('support@test.org'));
        expect(emails.length, 2);
      });

      test('should return empty list for text without emails', () {
        expect(StringUtils.extractEmails('No emails here'), isEmpty);
        expect(StringUtils.extractEmails(''), isEmpty);
      });
    });

    group('extractPhoneNumbers', () {
      test('should extract phone numbers from text', () {
        const text = 'Call us at 02-1234-5678 or mobile 0912-345-678';
        final phones = StringUtils.extractPhoneNumbers(text);
        expect(phones.length, greaterThan(0));
      });

      test('should return empty list for text without phone numbers', () {
        expect(StringUtils.extractPhoneNumbers('No phones here'), isEmpty);
        expect(StringUtils.extractPhoneNumbers(''), isEmpty);
      });
    });

    group('Performance', () {
      test('should handle large strings efficiently', () {
        final largeString = 'test ' * 10000;
        final stopwatch = Stopwatch()..start();

        StringUtils.cleanWhitespace(largeString);
        StringUtils.truncate(largeString, 100);
        StringUtils.isNullOrWhitespace(largeString);

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}
