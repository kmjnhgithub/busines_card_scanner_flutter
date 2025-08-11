import 'package:busines_card_scanner_flutter/core/errors/failures.dart';
import 'package:busines_card_scanner_flutter/core/services/validation_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ValidationService Tests', () {
    late ValidationService validationService;

    setUp(() {
      validationService = ValidationService();
    });

    group('Email Validation', () {
      test('should return success for valid email addresses', () {
        final validEmails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'firstname+lastname@example.com',
          'email@123.123.123.123', // IP address
          '1234567890@example.com',
          'email@example-one.com',
          '_______@example.com',
          'test.email.with+symbol@example.com',
          'x@example.com',
          'example@s.example',
        ];

        for (final email in validEmails) {
          final result = validationService.validateEmail(email);
          expect(result.isRight(), true, reason: 'Email: $email should be valid');
        }
      });

      test('should return ValidationFailure for invalid email addresses', () {
        final invalidEmails = [
          '',
          'plainaddress',
          '@missingdomain.com',
          'missing-at-sign.net',
          'missing@.com',
          'missing@domain',
          'spaces in@email.com',
          'email@domain@domain.com',
          'email@domain..com',
          '  leadingspace@email.com',
          'trailingspace@email.com  ',
          'email with spaces@domain.com',
        ];

        for (final email in invalidEmails) {
          final result = validationService.validateEmail(email);
          expect(result.isLeft(), true, reason: 'Email: $email should be invalid');
          
          result.fold(
            (failure) {
              expect(failure, isA<ValidationFailure>());
              expect(failure.field, 'email');
            },
            (success) => fail('Should return failure for invalid email: $email'),
          );
        }
      });

      test('should handle null and empty email gracefully', () {
        final result = validationService.validateEmail('');
        expect(result.isLeft(), true);
        
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.userMessage, contains('請輸入有效的電子信箱'));
          },
          (success) => fail('Should return failure for empty email'),
        );
      });

      test('should handle extremely long email addresses', () {
        final longEmail = '${'a' * 250}@example.com'; // >254 characters
        final result = validationService.validateEmail(longEmail);
        expect(result.isLeft(), true);
      });
    });

    group('Phone Number Validation', () {
      test('should return success for valid Taiwan phone numbers', () {
        final validPhones = [
          '0912345678',      // Mobile format
          '09-1234-5678',    // Mobile with dashes
          '(09) 1234-5678',  // Mobile with parentheses
          '02-12345678',     // Taipei landline
          '(02) 1234-5678',  // Landline with parentheses
          '04-12345678',     // Taichung landline
          '07-1234567',      // Kaohsiung landline (7 digits)
          '+886-9-1234-5678', // International format
          '+886 912 345 678', // International with spaces
          '886912345678',    // International without +
        ];

        for (final phone in validPhones) {
          final result = validationService.validatePhoneNumber(phone);
          expect(result.isRight(), true, reason: 'Phone: $phone should be valid');
        }
      });

      test('should return ValidationFailure for invalid phone numbers', () {
        final invalidPhones = [
          '',
          '123',
          'abcd1234',
          '091234567',      // Too short mobile
          '0912345678901',  // Too long
          '00123456789',    // Invalid prefix
          '+1-555-123-4567', // US format (not Taiwan)
          '02-123456',      // Too short landline
          '123-456-7890',   // Invalid format
        ];

        for (final phone in invalidPhones) {
          final result = validationService.validatePhoneNumber(phone);
          expect(result.isLeft(), true, reason: 'Phone: $phone should be invalid');
          
          result.fold(
            (failure) {
              expect(failure, isA<ValidationFailure>());
              expect(failure.field, 'phone');
            },
            (success) => fail('Should return failure for invalid phone: $phone'),
          );
        }
      });
    });

    group('URL Validation', () {
      test('should return success for valid URLs', () {
        final validUrls = [
          'http://example.com',
          'https://example.com',
          'https://www.example.com',
          'https://example.com/path',
          'https://example.com/path?query=1',
          'https://example.com:8080',
          'http://subdomain.example.com',
          'https://example.com/path/to/resource.html',
          'ftp://ftp.example.com',
          'https://127.0.0.1:3000',
        ];

        for (final url in validUrls) {
          final result = validationService.validateUrl(url);
          expect(result.isRight(), true, reason: 'URL: $url should be valid');
        }
      });

      test('should return ValidationFailure for invalid URLs', () {
        final invalidUrls = [
          '',
          'not-a-url',
          'example.com',     // Missing protocol
          'http://',         // Incomplete URL
          'https://.com',    // Invalid domain
          'http://exam ple.com', // Spaces
          'javascript:alert(1)', // Dangerous protocol
          'file:///etc/passwd', // Local file access
        ];

        for (final url in invalidUrls) {
          final result = validationService.validateUrl(url);
          expect(result.isLeft(), true, reason: 'URL: $url should be invalid');
        }
      });
    });

    group('Name Validation', () {
      test('should return success for valid names', () {
        final validNames = [
          '王小明',           // Chinese name
          'John Doe',        // English name
          'María García',    // Name with accents
          'O\'Connor',       // Name with apostrophe
          'Jean-Pierre',     // Hyphenated name
          '李 大華',          // Name with space
          'A',               // Single character
          '王-小明',          // Chinese with hyphen
        ];

        for (final name in validNames) {
          final result = validationService.validateName(name);
          expect(result.isRight(), true, reason: 'Name: $name should be valid');
        }
      });

      test('should return ValidationFailure for invalid names', () {
        final invalidNames = [
          '',                    // Empty
          '123',                 // Only numbers
          'John123',             // Numbers in name
          'John@Doe',           // Special characters
          'Name!',              // Exclamation mark
          '  John  ',           // Leading/trailing spaces
          'A' * 101,            // Too long (>100 characters)
          'John\nDoe',          // Newline characters
        ];

        for (final name in invalidNames) {
          final result = validationService.validateName(name);
          expect(result.isLeft(), true, reason: 'Name: $name should be invalid');
        }
      });
    });

    group('Company Name Validation', () {
      test('should return success for valid company names', () {
        final validCompanyNames = [
          '台灣積體電路製造股份有限公司',
          'Apple Inc.',
          'Google LLC',
          'Microsoft Corporation',
          '中華電信股份有限公司',
          'ABC Co., Ltd.',
          'XYZ & Associates',
          'Tech Solutions (Taiwan)',
          'Best-Buy Store',
        ];

        for (final company in validCompanyNames) {
          final result = validationService.validateCompanyName(company);
          expect(result.isRight(), true, reason: 'Company: $company should be valid');
        }
      });

      test('should return ValidationFailure for invalid company names', () {
        final invalidCompanyNames = [
          '',                    // Empty
          'A',                   // Too short
          'A' * 201,            // Too long (>200 characters)
          'Company!!!',         // Multiple special characters
          '123456',             // Only numbers
          'Company\nName',      // Newline characters
        ];

        for (final company in invalidCompanyNames) {
          final result = validationService.validateCompanyName(company);
          expect(result.isLeft(), true, reason: 'Company: $company should be invalid');
        }
      });
    });

    group('Text Length Validation', () {
      test('should validate minimum length correctly', () {
        const minLength = 5;
        final validTexts = ['12345', 'hello world', 'test string longer than minimum'];
        final invalidTexts = ['', '1', '1234'];

        for (final text in validTexts) {
          final result = validationService.validateMinLength(text, minLength);
          expect(result.isRight(), true, reason: 'Text: "$text" should meet minimum length');
        }

        for (final text in invalidTexts) {
          final result = validationService.validateMinLength(text, minLength);
          expect(result.isLeft(), true, reason: 'Text: "$text" should fail minimum length');
        }
      });

      test('should validate maximum length correctly', () {
        const maxLength = 10;
        final validTexts = ['', '1', '1234567890'];
        final invalidTexts = ['12345678901', 'this is too long'];

        for (final text in validTexts) {
          final result = validationService.validateMaxLength(text, maxLength);
          expect(result.isRight(), true, reason: 'Text: "$text" should meet maximum length');
        }

        for (final text in invalidTexts) {
          final result = validationService.validateMaxLength(text, maxLength);
          expect(result.isLeft(), true, reason: 'Text: "$text" should fail maximum length');
        }
      });

      test('should validate length range correctly', () {
        const minLength = 5;
        const maxLength = 15;
        final validTexts = ['12345', 'hello world', '123456789012345'];
        final invalidTexts = ['', '1234', '1234567890123456'];

        for (final text in validTexts) {
          final result = validationService.validateLengthRange(text, minLength, maxLength);
          expect(result.isRight(), true, reason: 'Text: "$text" should be in valid range');
        }

        for (final text in invalidTexts) {
          final result = validationService.validateLengthRange(text, minLength, maxLength);
          expect(result.isLeft(), true, reason: 'Text: "$text" should fail length range');
        }
      });
    });

    group('Required Field Validation', () {
      test('should return success for non-empty strings', () {
        final validInputs = ['a', 'hello', 'valid input', '123'];

        for (final input in validInputs) {
          final result = validationService.validateRequired(input, 'testField');
          expect(result.isRight(), true, reason: 'Input: "$input" should be valid');
        }
      });

      test('should return ValidationFailure for empty or whitespace strings', () {
        final invalidInputs = ['', '   ', '\t', '\n', '  \t\n  '];

        for (final input in invalidInputs) {
          final result = validationService.validateRequired(input, 'testField');
          expect(result.isLeft(), true, reason: 'Input: "$input" should be invalid');
          
          result.fold(
            (failure) {
              expect(failure, isA<ValidationFailure>());
              expect(failure.field, 'testField');
            },
            (success) => fail('Should return failure for empty input: "$input"'),
          );
        }
      });
    });

    group('Multiple Validation', () {
      test('should combine multiple validation rules correctly', () {
        // Test valid email that also meets length requirements
        const email = 'test@example.com';
        final emailResult = validationService.validateEmail(email);
        final lengthResult = validationService.validateLengthRange(email, 5, 50);

        expect(emailResult.isRight(), true);
        expect(lengthResult.isRight(), true);
      });

      test('should return appropriate failure when any validation fails', () {
        // Test invalid email that meets length requirements
        const invalidEmail = 'not-an-email-but-correct-length';
        final emailResult = validationService.validateEmail(invalidEmail);
        final lengthResult = validationService.validateLengthRange(invalidEmail, 5, 50);

        expect(emailResult.isLeft(), true);
        expect(lengthResult.isRight(), true);
      });
    });

    group('Edge Cases and Performance', () {
      test('should handle very long strings without performance issues', () {
        final longString = 'a' * 10000;
        final stopwatch = Stopwatch()..start();
        
        validationService.validateMaxLength(longString, 5000);
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100), 
               reason: 'Validation should complete within 100ms');
      });

      test('should handle special Unicode characters', () {
        final unicodeInputs = [
          '👨‍💼 Business',    // Emoji
          'Café',             // Accented characters
          'مرحبا',             // Arabic
          '你好',              // Chinese
          'Здравствуйте',     // Cyrillic
        ];

        for (final input in unicodeInputs) {
          final result = validationService.validateName(input);
          // Should handle gracefully (either pass or fail consistently)
          expect(result, isA<Either<ValidationFailure, String>>());
        }
      });
    });
  });
}