import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusinessCard Entity Tests', () {
    late DateTime testDateTime;

    setUp(() {
      testDateTime = DateTime(2024, 1, 15, 10, 30);
    });

    group('Construction and Properties', () {
      test('should create BusinessCard with all fields', () {
        // Arrange & Act
        final card = BusinessCard(
          id: 'card-123',
          name: 'John Doe',
          jobTitle: 'Software Engineer',
          company: 'Tech Corp',
          email: 'john@techcorp.com',
          phone: '+1-555-123-4567',
          address: '123 Main St, Tech City',
          website: 'https://johndoe.com',
          notes: 'Met at tech conference',
          imagePath: '/path/to/card/image.jpg',
          createdAt: testDateTime,
          updatedAt: testDateTime,
        );

        // Assert
        expect(card.id, 'card-123');
        expect(card.name, 'John Doe');
        expect(card.jobTitle, 'Software Engineer');
        expect(card.company, 'Tech Corp');
        expect(card.email, 'john@techcorp.com');
        expect(card.phone, '+1-555-123-4567');
        expect(card.address, '123 Main St, Tech City');
        expect(card.website, 'https://johndoe.com');
        expect(card.notes, 'Met at tech conference');
        expect(card.imagePath, '/path/to/card/image.jpg');
        expect(card.createdAt, testDateTime);
        expect(card.updatedAt, testDateTime);
      });

      test('should create BusinessCard with only required fields', () {
        // Arrange & Act
        final card = BusinessCard(
          id: 'card-456',
          name: 'Jane Smith',
          createdAt: testDateTime,
        );

        // Assert
        expect(card.id, 'card-456');
        expect(card.name, 'Jane Smith');
        expect(card.createdAt, testDateTime);
        expect(card.jobTitle, isNull);
        expect(card.company, isNull);
        expect(card.email, isNull);
        expect(card.phone, isNull);
        expect(card.address, isNull);
        expect(card.website, isNull);
        expect(card.notes, isNull);
        expect(card.imagePath, isNull);
        expect(card.updatedAt, isNull);
      });

      test('should handle empty string values correctly', () {
        // Arrange & Act
        final card = BusinessCard(
          id: 'card-789',
          name: 'Bob Wilson',
          jobTitle: '',
          company: '',
          email: '',
          phone: '',
          address: '',
          website: '',
          notes: '',
          createdAt: testDateTime,
        );

        // Assert
        expect(card.name, 'Bob Wilson');
        // Empty strings should be converted to null after cleaning
        expect(card.jobTitle, isNull);
        expect(card.company, isNull);
        expect(card.email, isNull);
        expect(card.phone, isNull);
        expect(card.address, isNull);
        expect(card.website, isNull);
        expect(card.notes, isNull);
      });
    });

    group('Equality and Hash Code', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        final card1 = BusinessCard(
          id: 'card-123',
          name: 'John Doe',
          jobTitle: 'Developer',
          company: 'Tech Corp',
          createdAt: testDateTime,
        );

        final card2 = BusinessCard(
          id: 'card-123',
          name: 'John Doe',
          jobTitle: 'Developer',
          company: 'Tech Corp',
          createdAt: testDateTime,
        );

        // Act & Assert
        expect(card1, equals(card2));
        expect(card1.hashCode, equals(card2.hashCode));
      });

      test('should not be equal when ids are different', () {
        // Arrange
        final card1 = BusinessCard(
          id: 'card-123',
          name: 'John Doe',
          createdAt: testDateTime,
        );

        final card2 = BusinessCard(
          id: 'card-456',
          name: 'John Doe',
          createdAt: testDateTime,
        );

        // Act & Assert
        expect(card1, isNot(equals(card2)));
        expect(card1.hashCode, isNot(equals(card2.hashCode)));
      });

      test('should not be equal when names are different', () {
        // Arrange
        final card1 = BusinessCard(
          id: 'card-123',
          name: 'John Doe',
          createdAt: testDateTime,
        );

        final card2 = BusinessCard(
          id: 'card-123',
          name: 'Jane Smith',
          createdAt: testDateTime,
        );

        // Act & Assert
        expect(card1, isNot(equals(card2)));
      });
    });

    group('toString Method', () {
      test('should return proper string representation', () {
        // Arrange
        final card = BusinessCard(
          id: 'card-123',
          name: 'John Doe',
          company: 'Tech Corp',
          createdAt: testDateTime,
        );

        // Act
        final result = card.toString();

        // Assert
        expect(result, contains('BusinessCard'));
        expect(result, contains('card-123'));
        expect(result, contains('John Doe'));
        expect(result, contains('Tech Corp'));
      });

      test('should not expose sensitive information in toString', () {
        // Arrange
        final card = BusinessCard(
          id: 'card-123',
          name: 'John Doe',
          notes: 'Secret client information',
          createdAt: testDateTime,
        );

        // Act
        final result = card.toString();

        // Assert - Notes should not be in toString for security
        expect(result, isNot(contains('Secret client information')));
      });
    });

    group('Validation Logic', () {
      test('should validate required fields', () {
        // Assert that constructor throws when required fields are missing
        expect(
          () => BusinessCard(
            id: '', // Empty id should be invalid
            name: 'John Doe',
            createdAt: testDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => BusinessCard(
            id: 'card-123',
            name: '', // Empty name should be invalid
            createdAt: testDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should validate email format if provided', () {
        expect(
          () => BusinessCard(
            id: 'card-123',
            name: 'John Doe',
            email: 'invalid-email-format',
            createdAt: testDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should validate phone format if provided', () {
        expect(
          () => BusinessCard(
            id: 'card-123',
            name: 'John Doe',
            phone: '123', // Too short
            createdAt: testDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should validate website URL format if provided', () {
        // 無效網址應該被清除而不是拋出異常（容錯處理）
        final card = BusinessCard(
          id: 'card-123',
          name: 'John Doe',
          website: 'not-a-valid-url',
          createdAt: testDateTime,
        );

        // 無效網址應該被設為 null
        expect(card.website, isNull);
      });

      test('should allow valid email, phone, and website formats', () {
        // This should not throw
        expect(
          () => BusinessCard(
            id: 'card-123',
            name: 'John Doe',
            email: 'john@example.com',
            phone: '+1-555-123-4567',
            website: 'https://johndoe.com',
            createdAt: testDateTime,
          ),
          returnsNormally,
        );
      });
    });

    group('Business Logic Methods', () {
      test('should check if card has complete information', () {
        // Arrange
        final completeCard = BusinessCard(
          id: 'card-123',
          name: 'John Doe',
          jobTitle: 'Developer',
          company: 'Tech Corp',
          email: 'john@techcorp.com',
          phone: '+1-555-123-4567',
          createdAt: testDateTime,
        );

        final incompleteCard = BusinessCard(
          id: 'card-456',
          name: 'Jane Smith',
          createdAt: testDateTime,
        );

        // Act & Assert
        expect(completeCard.isComplete(), isTrue);
        expect(incompleteCard.isComplete(), isFalse);
      });

      test('should check if card has contact information', () {
        // Arrange
        final cardWithContact = BusinessCard(
          id: 'card-123',
          name: 'John Doe',
          email: 'john@example.com',
          createdAt: testDateTime,
        );

        final cardWithoutContact = BusinessCard(
          id: 'card-456',
          name: 'Jane Smith',
          createdAt: testDateTime,
        );

        // Act & Assert
        expect(cardWithContact.hasContactInfo(), isTrue);
        expect(cardWithoutContact.hasContactInfo(), isFalse);
      });

      test('should create copy with updated fields', () {
        // Arrange
        final originalCard = BusinessCard(
          id: 'card-123',
          name: 'John Doe',
          company: 'Old Corp',
          createdAt: testDateTime,
        );

        // Act
        final updatedCard = originalCard.copyWith(
          company: 'New Corp',
          updatedAt: testDateTime.add(const Duration(hours: 1)),
        );

        // Assert
        expect(updatedCard.id, originalCard.id);
        expect(updatedCard.name, originalCard.name);
        expect(updatedCard.company, 'New Corp');
        expect(updatedCard.createdAt, originalCard.createdAt);
        expect(
          updatedCard.updatedAt,
          testDateTime.add(const Duration(hours: 1)),
        );
      });

      test('should get display name with fallback', () {
        // Arrange
        final cardWithName = BusinessCard(
          id: 'card-123',
          name: 'John Doe',
          createdAt: testDateTime,
        );

        final cardWithEmail = BusinessCard(
          id: 'card-456',
          name: 'Unknown Person', // Name is required, so use a valid name
          email: 'unknown@example.com',
          createdAt: testDateTime,
        );

        // Act & Assert
        expect(cardWithName.getDisplayName(), 'John Doe');
        expect(
          cardWithEmail.getDisplayName(),
          'Unknown Person',
        ); // Should return name, not email
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle null values gracefully', () {
        // This should work without throwing
        expect(
          () => BusinessCard(
            id: 'card-123',
            name: 'John Doe',
            createdAt: testDateTime,
          ),
          returnsNormally,
        );
      });

      test('should handle very long text fields', () {
        final longText = 'A' * 1000;

        expect(
          () => BusinessCard(
            id: 'card-123',
            name: 'John Doe',
            notes: longText,
            createdAt: testDateTime,
          ),
          returnsNormally,
        );
      });

      test('should handle special characters in text fields', () {
        expect(
          () => BusinessCard(
            id: 'card-123',
            name: 'José García-López',
            company: '株式会社テスト',
            address: '北京市朝阳区',
            createdAt: testDateTime,
          ),
          returnsNormally,
        );
      });
    });

    group('Security Considerations', () {
      test('should not allow script injection in text fields', () {
        expect(
          () => BusinessCard(
            id: 'card-123',
            name: '<script>alert("XSS")</script>',
            createdAt: testDateTime,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should sanitize input fields', () {
        // Arrange & Act
        final card = BusinessCard(
          id: 'card-123',
          name: 'John  Doe', // Multiple spaces
          email: ' john@example.com ',
          phone: ' +1-555-123-4567 ',
          createdAt: testDateTime,
        );

        // Assert - Should be sanitized
        expect(card.name, 'John Doe'); // Single space
        expect(card.email, 'john@example.com'); // Trimmed
        expect(card.phone, '+1-555-123-4567'); // Trimmed
      });
    });
  });
}
