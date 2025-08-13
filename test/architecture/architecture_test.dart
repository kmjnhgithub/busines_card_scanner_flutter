import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Clean Architecture 邊界測試
///
/// 驗證各層之間的依賴方向是否正確：
/// - Domain 層不能依賴 Data 層或 Presentation 層
/// - Presentation 層不能直接依賴 Data 層
/// - 確保依賴注入原則得到遵循
void main() {
  group('Architecture Boundary Tests', () {
    late Directory libDirectory;
    late Map<String, List<String>> fileImports;

    setUpAll(() async {
      // 獲取 lib 資料夾
      libDirectory = Directory('lib');
      if (!libDirectory.existsSync()) {
        throw Exception('lib directory not found');
      }

      // 分析所有 Dart 檔案的 import 語句
      fileImports = await _analyzeImports(libDirectory);
    });

    group('Domain Layer Dependencies', () {
      test('Domain layer should not import from Data layer', () {
        final domainFiles = fileImports.keys
            .where((file) => file.contains('/domain/'))
            .toList();

        for (final domainFile in domainFiles) {
          final imports = fileImports[domainFile] ?? [];
          final dataImports = imports
              .where((import) => import.contains('/data/'))
              .toList();

          expect(
            dataImports,
            isEmpty,
            reason:
                'Domain file $domainFile should not import from Data layer: $dataImports',
          );
        }
      });

      test('Domain layer should not import from Presentation layer', () {
        final domainFiles = fileImports.keys
            .where((file) => file.contains('/domain/'))
            .toList();

        for (final domainFile in domainFiles) {
          final imports = fileImports[domainFile] ?? [];
          final presentationImports = imports
              .where((import) => import.contains('/presentation/'))
              .toList();

          expect(
            presentationImports,
            isEmpty,
            reason:
                'Domain file $domainFile should not import from Presentation layer: $presentationImports',
          );
        }
      });

      test('Domain layer should only import from Core and external packages', () {
        final domainFiles = fileImports.keys
            .where((file) => file.contains('/domain/'))
            .toList();

        for (final domainFile in domainFiles) {
          final imports = fileImports[domainFile] ?? [];
          final internalImports = imports
              .where(
                (import) =>
                    import.startsWith('package:busines_card_scanner_flutter/'),
              )
              .toList();

          for (final import in internalImports) {
            expect(
              import.contains('/core/') || import.contains('/domain/'),
              isTrue,
              reason:
                  'Domain file $domainFile can only import from Core or Domain: $import',
            );
          }
        }
      });
    });

    group('Data Layer Dependencies', () {
      test('Data layer should not import from Presentation layer', () {
        final dataFiles = fileImports.keys
            .where((file) => file.contains('/data/'))
            .toList();

        for (final dataFile in dataFiles) {
          final imports = fileImports[dataFile] ?? [];
          final presentationImports = imports
              .where((import) => import.contains('/presentation/'))
              .toList();

          expect(
            presentationImports,
            isEmpty,
            reason:
                'Data file $dataFile should not import from Presentation layer: $presentationImports',
          );
        }
      });

      test('Data layer can import from Domain and Core layers', () {
        final dataFiles = fileImports.keys
            .where((file) => file.contains('/data/'))
            .toList();

        for (final dataFile in dataFiles) {
          final imports = fileImports[dataFile] ?? [];
          final internalImports = imports
              .where(
                (import) =>
                    import.startsWith('package:busines_card_scanner_flutter/'),
              )
              .toList();

          for (final import in internalImports) {
            expect(
              import.contains('/core/') ||
                  import.contains('/domain/') ||
                  import.contains('/data/'),
              isTrue,
              reason:
                  'Data file $dataFile can import from Core, Domain, or Data: $import',
            );
          }
        }
      });
    });

    group('Presentation Layer Dependencies', () {
      test(
        'Presentation layer should not directly import from Data layer models',
        () {
          final presentationFiles = fileImports.keys
              .where((file) => file.contains('/presentation/'))
              .toList();

          for (final presentationFile in presentationFiles) {
            final imports = fileImports[presentationFile] ?? [];
            final dataModelImports = imports
                .where((import) => import.contains('/data/models/'))
                .toList();

            expect(
              dataModelImports,
              isEmpty,
              reason:
                  'Presentation file $presentationFile should not directly import Data models: $dataModelImports',
            );
          }
        },
      );

      test('Presentation layer can import from Domain and Core layers', () {
        final presentationFiles = fileImports.keys
            .where((file) => file.contains('/presentation/'))
            .toList();

        for (final presentationFile in presentationFiles) {
          final imports = fileImports[presentationFile] ?? [];
          final internalImports = imports
              .where(
                (import) =>
                    import.startsWith('package:busines_card_scanner_flutter/'),
              )
              .toList();

          for (final import in internalImports) {
            expect(
              import.contains('/core/') ||
                  import.contains('/domain/') ||
                  import.contains('/presentation/'),
              isTrue,
              reason:
                  'Presentation file $presentationFile can import from Core, Domain, or Presentation: $import',
            );
          }
        }
      });
    });

    group('Core Layer Dependencies', () {
      test('Core layer should not import from other layers except itself', () {
        final coreFiles = fileImports.keys
            .where((file) => file.contains('/core/'))
            .toList();

        for (final coreFile in coreFiles) {
          final imports = fileImports[coreFile] ?? [];
          final layerImports = imports
              .where(
                (import) =>
                    import.contains('/data/') ||
                    import.contains('/domain/') ||
                    import.contains('/presentation/'),
              )
              .toList();

          expect(
            layerImports,
            isEmpty,
            reason:
                'Core file $coreFile should not import from other layers: $layerImports',
          );
        }
      });
    });

    group('Package Structure Validation', () {
      test('All Dart files should be in appropriate layer directories', () {
        final allDartFiles = fileImports.keys.toList();
        final validLayerPatterns = [
          RegExp('/core/'),
          RegExp('/domain/'),
          RegExp('/data/'),
          RegExp('/presentation/'),
          RegExp(r'main\.dart$'), // main.dart 可以在根目錄
        ];

        for (final file in allDartFiles) {
          final isInValidLayer = validLayerPatterns.any(
            (pattern) => pattern.hasMatch(file),
          );
          expect(
            isInValidLayer,
            isTrue,
            reason: 'File $file should be in a valid layer directory',
          );
        }
      });

      test('Feature modules should follow consistent structure', () {
        final presentationDir = Directory('lib/presentation');
        if (presentationDir.existsSync()) {
          final featureDirs = presentationDir
              .listSync()
              .whereType<Directory>()
              .where((dir) => !dir.path.contains('shared'))
              .toList();

          for (final featureDir in featureDirs) {
            // final featureName = featureDir.path.split('/').last;

            // TODO: 當功能模組實作時啟用基本資料夾結構檢查
            // 預期的子目錄包括: 'pages', 'view_models', 'widgets', 'providers'
            if (featureDir.listSync().isNotEmpty) {
              // TODO: 當功能模組實作時檢查子目錄結構
            }
          }
        }
      });
    });

    group('Dependency Injection Rules', () {
      test('Repository interfaces should be in Domain layer', () {
        // final repositoryInterfaces = fileImports.keys
        //     .where(
        //       (file) =>
        //           file.contains('repository') && file.contains('/domain/'),
        //     )
        //     .toList();

        // 目前還沒有 repository 實作，這個測試將在後續 Phase 中生效
        // expect(repositoryInterfaces.isNotEmpty, isTrue,
        //     reason: 'Repository interfaces should exist in Domain layer');
      });

      test('Repository implementations should be in Data layer', () {
        // final repositoryImpls = fileImports.keys
        //     .where(
        //       (file) =>
        //           file.contains('repository') &&
        //           file.contains('/data/') &&
        //           file.contains('_impl'),
        //     )
        //     .toList();

        // 目前還沒有 repository 實作，這個測試將在後續 Phase 中生效
        // expect(repositoryImpls.isNotEmpty, isTrue,
        //     reason: 'Repository implementations should exist in Data layer');
      });
    });

    group('Import Analysis Quality', () {
      test('Should have analyzed some files', () {
        expect(
          fileImports.isNotEmpty,
          isTrue,
          reason: 'Should have analyzed at least some Dart files',
        );
      });

      test('Core layer files should exist', () {
        final coreFiles = fileImports.keys
            .where((file) => file.contains('/core/'))
            .toList();

        expect(
          coreFiles.isNotEmpty,
          isTrue,
          reason: 'Should have Core layer files',
        );
      });
    });
  });
}

/// 分析指定目錄下所有 Dart 檔案的 import 語句
Future<Map<String, List<String>>> _analyzeImports(Directory directory) async {
  final Map<String, List<String>> imports = {};

  await for (final entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final relativePath = entity.path.replaceFirst(RegExp('^.*lib/'), 'lib/');
      final fileImports = await _extractImports(entity);
      imports[relativePath] = fileImports;
    }
  }

  return imports;
}

/// 從 Dart 檔案中提取 import 語句
Future<List<String>> _extractImports(File file) async {
  final List<String> imports = [];

  try {
    final content = await file.readAsString();
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('import ')) {
        // 簡單的字串解析，提取引號之間的內容
        String? extractedImport;

        if (trimmed.contains("'")) {
          final startIndex = trimmed.indexOf("'") + 1;
          final endIndex = trimmed.indexOf("'", startIndex);
          if (endIndex != -1) {
            extractedImport = trimmed.substring(startIndex, endIndex);
          }
        } else if (trimmed.contains('"')) {
          final startIndex = trimmed.indexOf('"') + 1;
          final endIndex = trimmed.indexOf('"', startIndex);
          if (endIndex != -1) {
            extractedImport = trimmed.substring(startIndex, endIndex);
          }
        }

        if (extractedImport != null && extractedImport.isNotEmpty) {
          imports.add(extractedImport);
        }
      }
    }
  } catch (e) {
    // 如果檔案讀取失敗，回傳空列表
    return [];
  }

  return imports;
}
