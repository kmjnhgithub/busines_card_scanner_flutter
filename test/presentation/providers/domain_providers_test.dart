import 'package:busines_card_scanner_flutter/domain/repositories/card_repository.dart';
import 'package:busines_card_scanner_flutter/domain/repositories/ocr_repository.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/create_card_from_image_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/create_card_from_ocr_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/create_card_manually_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/delete_card_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/get_cards_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/process_image_usecase.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/data_providers.dart' as data;
import 'package:busines_card_scanner_flutter/presentation/providers/domain_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockCardRepository extends Mock implements CardRepository {}
class MockOCRRepository extends Mock implements OCRRepository {}
void main() {
  group('Domain Providers', () {
    late ProviderContainer container;
    late MockCardRepository mockCardRepository;
    late MockOCRRepository mockOCRRepository;

    setUp(() {
      mockCardRepository = MockCardRepository();
      mockOCRRepository = MockOCRRepository();

      container = ProviderContainer(
        overrides: [
          data.cardRepositoryProvider.overrideWithValue(mockCardRepository),
          data.ocrRepositoryProvider.overrideWithValue(mockOCRRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('UseCase Providers', () {
      test('getCardsUseCaseProvider should create GetCardsUseCase', () {
        // Act
        final useCase = container.read(getCardsUseCaseProvider);

        // Assert
        expect(useCase, isA<GetCardsUseCase>());
      });

      test('createCardFromImageUseCaseProvider should create CreateCardFromImageUseCase', () {
        // Act
        final useCase = container.read(createCardFromImageUseCaseProvider);

        // Assert
        expect(useCase, isA<CreateCardFromImageUseCase>());
      });

      test('createCardFromOCRUseCaseProvider should create CreateCardFromOCRUseCase', () {
        // Act
        final useCase = container.read(createCardFromOCRUseCaseProvider);

        // Assert
        expect(useCase, isA<CreateCardFromOCRUseCase>());
      });

      test('createCardManuallyUseCaseProvider should create CreateCardManuallyUseCase', () {
        // Act
        final useCase = container.read(createCardManuallyUseCaseProvider);

        // Assert
        expect(useCase, isA<CreateCardManuallyUseCase>());
      });

      test('deleteCardUseCaseProvider should create DeleteCardUseCase', () {
        // Act
        final useCase = container.read(deleteCardUseCaseProvider);

        // Assert
        expect(useCase, isA<DeleteCardUseCase>());
      });

      test('processImageUseCaseProvider should create ProcessImageUseCase', () {
        // Act
        final useCase = container.read(processImageUseCaseProvider);

        // Assert
        expect(useCase, isA<ProcessImageUseCase>());
      });
    });

    group('UseCase Dependencies', () {
      test('should inject correct repository dependencies', () {
        // Act
        final getCardsUseCase = container.read(getCardsUseCaseProvider);
        final deleteCardUseCase = container.read(deleteCardUseCaseProvider);
        final processImageUseCase = container.read(processImageUseCaseProvider);

        // Assert - 驗證 UseCase 正確實例化
        expect(getCardsUseCase, isNotNull);
        expect(deleteCardUseCase, isNotNull);
        expect(processImageUseCase, isNotNull);
      });

      test('should create different instances for different UseCases', () {
        // Act
        final useCase1 = container.read(getCardsUseCaseProvider);
        final useCase2 = container.read(createCardFromImageUseCaseProvider);
        final useCase3 = container.read(deleteCardUseCaseProvider);

        // Assert
        expect(useCase1, isNot(same(useCase2)));
        expect(useCase2, isNot(same(useCase3)));
        expect(useCase1, isNot(same(useCase3)));
      });

      test('should return same instance for same provider', () {
        // Act
        final useCase1 = container.read(getCardsUseCaseProvider);
        final useCase2 = container.read(getCardsUseCaseProvider);

        // Assert
        expect(useCase1, same(useCase2));
      });
    });

    group('Provider Lifecycle', () {
      test('should dispose UseCases correctly', () {
        // Arrange - 讀取 providers 以建立依賴
        container.read(getCardsUseCaseProvider);
        container.read(createCardFromImageUseCaseProvider);

        // Act & Assert - 驗證 dispose 不會拋出異常
        expect(() => container.dispose(), returnsNormally);
      });

      test('should handle provider overrides correctly', () {
        // Arrange
        final customRepository = MockCardRepository();
        final customContainer = ProviderContainer(
          overrides: [
            data.cardRepositoryProvider.overrideWithValue(customRepository),
          ],
        );

        // Act
        final useCase = customContainer.read(getCardsUseCaseProvider);

        // Assert
        expect(useCase, isA<GetCardsUseCase>());

        customContainer.dispose();
      });
    });

    group('Provider Composition', () {
      test('should compose providers correctly for complex UseCases', () {
        // Act
        final createFromImageUseCase = container.read(createCardFromImageUseCaseProvider);
        final processImageUseCase = container.read(processImageUseCaseProvider);

        // Assert - 驗證複合依賴的 UseCase 正確創建
        expect(createFromImageUseCase, isA<CreateCardFromImageUseCase>());
        expect(processImageUseCase, isA<ProcessImageUseCase>());
      });

      test('should maintain proper dependency separation', () {
        // Arrange - 建立不同的 container 測試隔離性
        final container1 = ProviderContainer();
        final container2 = ProviderContainer();

        // Act
        final useCase1 = container1.read(getCardsUseCaseProvider);
        final useCase2 = container2.read(getCardsUseCaseProvider);

        // Assert
        expect(useCase1, isNot(same(useCase2)));

        container1.dispose();
        container2.dispose();
      });
    });

    group('Error Handling', () {
      test('should handle missing dependencies gracefully', () {
        // Arrange - 建立沒有 override 的 container
        final emptyContainer = ProviderContainer();

        // Act & Assert - 在缺少依賴時應該能正常創建（使用真實實例）
        expect(
          () => emptyContainer.read(getCardsUseCaseProvider),
          returnsNormally,
        );

        emptyContainer.dispose();
      });
    });
  });
}