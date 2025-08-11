import 'package:busines_card_scanner_flutter/core/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure Tests', () {
    group('NetworkFailure', () {
      test('should create NetworkFailure with correct properties', () {
        const failure = NetworkFailure(
          userMessage: 'Network connection failed',
          internalMessage: 'SocketException: Connection timeout',
          statusCode: 408,
        );

        expect(failure.userMessage, 'Network connection failed');
        expect(failure.internalMessage, 'SocketException: Connection timeout');
        expect(failure.statusCode, 408);
      });

      test('should support equality comparison', () {
        const failure1 = NetworkFailure(
          userMessage: 'Network error',
          internalMessage: 'Internal error',
          statusCode: 500,
        );
        const failure2 = NetworkFailure(
          userMessage: 'Network error',
          internalMessage: 'Internal error',
          statusCode: 500,
        );
        const failure3 = NetworkFailure(
          userMessage: 'Different error',
          internalMessage: 'Internal error',
          statusCode: 500,
        );

        expect(failure1, equals(failure2));
        expect(failure1, isNot(equals(failure3)));
      });

      test('should have correct toString implementation', () {
        const failure = NetworkFailure(
          userMessage: 'Connection failed',
          internalMessage: 'Timeout error',
          statusCode: 408,
        );

        final toString = failure.toString();
        expect(toString, contains('NetworkFailure'));
        expect(toString, contains('408'));
        expect(toString, isNot(contains('Connection failed')));
      });
    });

    group('ServerFailure', () {
      test('should create ServerFailure with correct properties', () {
        const failure = ServerFailure(
          userMessage: 'Server error occurred',
          internalMessage: 'Internal server error: Database connection lost',
          statusCode: 500,
        );

        expect(failure.userMessage, 'Server error occurred');
        expect(failure.internalMessage, 'Internal server error: Database connection lost');
        expect(failure.statusCode, 500);
      });

      test('should support equality comparison', () {
        const failure1 = ServerFailure(
          userMessage: 'Server error',
          internalMessage: 'DB error',
          statusCode: 500,
        );
        const failure2 = ServerFailure(
          userMessage: 'Server error',
          internalMessage: 'DB error',
          statusCode: 500,
        );

        expect(failure1, equals(failure2));
      });
    });

    group('ValidationFailure', () {
      test('should create ValidationFailure with field information', () {
        const failure = ValidationFailure(
          userMessage: 'Invalid email address',
          internalMessage: 'Email validation failed: regex mismatch',
          field: 'email',
        );

        expect(failure.userMessage, 'Invalid email address');
        expect(failure.internalMessage, 'Email validation failed: regex mismatch');
        expect(failure.field, 'email');
      });

      test('should support multiple validation errors', () {
        const failures = [
          ValidationFailure(
            userMessage: 'Invalid email',
            internalMessage: 'Email format error',
            field: 'email',
          ),
          ValidationFailure(
            userMessage: 'Phone number required',
            internalMessage: 'Phone field is empty',
            field: 'phone',
          ),
        ];

        expect(failures.length, 2);
        expect(failures[0].field, 'email');
        expect(failures[1].field, 'phone');
      });
    });

    group('SecurityFailure', () {
      test('should create SecurityFailure without exposing sensitive data', () {
        const failure = SecurityFailure(
          userMessage: 'Access denied',
          internalMessage: 'API key validation failed: key=abc123xyz',
        );

        expect(failure.userMessage, 'Access denied');
        expect(failure.internalMessage, 'API key validation failed: key=abc123xyz');
        
        final toString = failure.toString();
        expect(toString, isNot(contains('abc123xyz')));
        expect(toString, contains('SecurityFailure'));
      });

      test('should handle authentication failures', () {
        const failure = SecurityFailure(
          userMessage: 'Authentication failed',
          internalMessage: 'JWT token expired',
          securityCode: 'AUTH_EXPIRED',
        );

        expect(failure.securityCode, 'AUTH_EXPIRED');
        expect(failure.userMessage, 'Authentication failed');
      });
    });

    group('UnexpectedFailure', () {
      test('should create UnexpectedFailure with error tracking', () {
        final exception = Exception('Unexpected error occurred');
        final failure = UnexpectedFailure(
          userMessage: 'Something went wrong',
          internalMessage: 'Unexpected exception in card parsing',
          cause: exception,
        );

        expect(failure.userMessage, 'Something went wrong');
        expect(failure.internalMessage, 'Unexpected exception in card parsing');
        expect(failure.cause, exception);
      });

      test('should support error chaining', () {
        final rootCause = Exception('Root cause');
        final intermediateCause = UnexpectedFailure(
          userMessage: 'Intermediate error',
          internalMessage: 'Intermediate failure',
          cause: rootCause,
        );
        final topLevelFailure = UnexpectedFailure(
          userMessage: 'Top level error',
          internalMessage: 'Chain of failures',
          cause: intermediateCause,
        );

        expect(topLevelFailure.cause, intermediateCause);
        expect((topLevelFailure.cause as UnexpectedFailure).cause, rootCause);
      });
    });

    group('CacheFailure', () {
      test('should create CacheFailure with cache operation details', () {
        const failure = CacheFailure(
          userMessage: 'Data temporarily unavailable',
          internalMessage: 'Cache read failed: file not found /cache/cards.db',
          operation: 'READ',
        );

        expect(failure.userMessage, 'Data temporarily unavailable');
        expect(failure.operation, 'READ');
      });
    });

    group('PermissionFailure', () {
      test('should create PermissionFailure with permission details', () {
        const failure = PermissionFailure(
          userMessage: 'Camera access required',
          internalMessage: 'Camera permission denied by user',
          permission: 'CAMERA',
        );

        expect(failure.userMessage, 'Camera access required');
        expect(failure.permission, 'CAMERA');
      });
    });

    group('Failure Base Class', () {
      test('should not expose sensitive information in user messages', () {
        const failures = [
          NetworkFailure(
            userMessage: 'Connection error',
            internalMessage: 'API_KEY=secret123 failed',
          ),
          SecurityFailure(
            userMessage: 'Access denied',
            internalMessage: 'User token: bearer_token_xyz',
          ),
        ];

        for (final failure in failures) {
          expect(failure.userMessage, isNot(contains('secret123')));
          expect(failure.userMessage, isNot(contains('bearer_token_xyz')));
          expect(failure.userMessage, isNot(contains('API_KEY')));
        }
      });

      test('should support generic error handling', () {
        const List<Failure> failures = [
          NetworkFailure(userMessage: 'Network error', internalMessage: 'Net error'),
          ServerFailure(userMessage: 'Server error', internalMessage: 'Server error'),
          ValidationFailure(userMessage: 'Validation error', internalMessage: 'Val error'),
        ];

        expect(failures.length, 3);
        for (final failure in failures) {
          expect(failure.userMessage, isNotEmpty);
          expect(failure.internalMessage, isNotEmpty);
        }
      });
    });
  });
}