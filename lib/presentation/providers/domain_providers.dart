import 'package:busines_card_scanner_flutter/domain/usecases/card/create_card_from_image_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/create_card_from_ocr_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/create_card_manually_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/delete_card_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/get_cards_usecase.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/process_image_usecase.dart';
import 'package:busines_card_scanner_flutter/presentation/providers/data_providers.dart' as data;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// UseCase Providers (Domain Layer Business Logic)
// =============================================================================

/// Provider for GetCardsUseCase
/// Handles retrieving all business cards
final getCardsUseCaseProvider = Provider<GetCardsUseCase>((ref) {
  final repository = ref.watch(data.cardRepositoryProvider);
  return GetCardsUseCase(repository);
});

/// Provider for CreateCardFromImageUseCase
/// Handles creating business card from image with OCR and AI parsing
final createCardFromImageUseCaseProvider = Provider<CreateCardFromImageUseCase>((ref) {
  final cardRepository = ref.watch(data.cardRepositoryProvider);
  final ocrRepository = ref.watch(data.ocrRepositoryProvider);
  final aiRepository = ref.watch(data.aiRepositoryProvider);
  return CreateCardFromImageUseCase(cardRepository, ocrRepository, aiRepository);
});

/// Provider for CreateCardFromOCRUseCase
/// Handles creating business card from OCR text with AI parsing
final createCardFromOCRUseCaseProvider = Provider<CreateCardFromOCRUseCase>((ref) {
  final cardRepository = ref.watch(data.cardRepositoryProvider);
  final aiRepository = ref.watch(data.aiRepositoryProvider);
  return CreateCardFromOCRUseCase(cardRepository, aiRepository);
});

/// Provider for CreateCardManuallyUseCase
/// Handles manual business card creation
final createCardManuallyUseCaseProvider = Provider<CreateCardManuallyUseCase>((ref) {
  final repository = ref.watch(data.cardRepositoryProvider);
  return CreateCardManuallyUseCase(repository);
});

/// Provider for DeleteCardUseCase
/// Handles deleting business cards and associated resources
final deleteCardUseCaseProvider = Provider<DeleteCardUseCase>((ref) {
  final repository = ref.watch(data.cardRepositoryProvider);
  return DeleteCardUseCase(repository);
});

/// Provider for ProcessImageUseCase
/// Handles OCR processing of images
final processImageUseCaseProvider = Provider<ProcessImageUseCase>((ref) {
  final repository = ref.watch(data.ocrRepositoryProvider);
  return ProcessImageUseCase(repository);
});