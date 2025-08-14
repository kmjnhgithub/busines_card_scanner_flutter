import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart';
import 'package:busines_card_scanner_flutter/domain/usecases/card/get_cards_usecase.dart';
import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:share_plus/share_plus.dart';

part 'export_view_model.freezed.dart';
part 'export_view_model.g.dart';

/// 檔案系統服務介面
abstract class FileSystemService {
  Future<Directory> getApplicationDocumentsDirectory();
  Future<File> writeFile(String path, String content);
  Future<bool> fileExists(String path);
}

/// 檔案系統服務實作
class FileSystemServiceImpl implements FileSystemService {
  @override
  Future<Directory> getApplicationDocumentsDirectory() async {
    return path_provider.getApplicationDocumentsDirectory();
  }

  @override
  Future<File> writeFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
    return file;
  }

  @override
  Future<bool> fileExists(String path) async {
    final file = File(path);
    return file.existsSync();
  }
}

/// 分享服務介面
abstract class ShareService {
  Future<void> shareFile(String filePath, String text);
}

/// 分享服務實作
class ShareServiceImpl implements ShareService {
  @override
  Future<void> shareFile(String filePath, String text) async {
    await Share.shareXFiles([XFile(filePath)], text: text);
  }
}

/// 匯出格式列舉
enum ExportFormat {
  csv('CSV'),
  vcf('VCF'),
  json('JSON');

  const ExportFormat(this.displayName);
  final String displayName;
}

/// 匯出狀態
@freezed
class ExportState with _$ExportState {
  const factory ExportState({
    @Default(false) bool isExporting,
    @Default(0.0) double progress,
    String? exportedFilePath,
    String? errorMessage,
    @Default(ExportFormat.csv) ExportFormat selectedFormat,
    @Default([]) List<String> selectedCardIds,
  }) = _ExportState;
}

/// 匯出 ViewModel
class ExportViewModel extends StateNotifier<ExportState> {
  final GetCardsUseCase _getCardsUseCase;
  final FileSystemService _fileSystemService;
  final ShareService _shareService;
  late Completer<void>? _exportCompleter;
  bool _isCancelled = false;

  ExportViewModel({
    required GetCardsUseCase getCardsUseCase,
    required FileSystemService fileSystemService,
    required ShareService shareService,
  }) : _getCardsUseCase = getCardsUseCase,
       _fileSystemService = fileSystemService,
       _shareService = shareService,
       super(const ExportState());

  /// 設定匯出格式
  void setExportFormat(ExportFormat format) {
    state = state.copyWith(selectedFormat: format, errorMessage: null);
  }

  /// 選擇要匯出的名片
  void selectCards(List<String> cardIds) {
    // 去除重複的 ID
    final uniqueIds = cardIds.toSet().toList();

    state = state.copyWith(selectedCardIds: uniqueIds, errorMessage: null);
  }

  /// 匯出全部名片
  Future<void> exportAllCards() async {
    await _performExport(() async {
      return _getCardsUseCase.execute(const GetCardsParams());
    });
  }

  /// 匯出選定的名片
  Future<void> exportSelectedCards() async {
    if (state.selectedCardIds.isEmpty) {
      state = state.copyWith(errorMessage: '請先選擇要匯出的名片');
      return;
    }

    await _performExport(() async {
      final allCards = await _getCardsUseCase.execute(const GetCardsParams());
      final selectedCards = allCards
          .where((card) => state.selectedCardIds.contains(card.id))
          .toList();

      if (selectedCards.isEmpty) {
        throw Exception('找不到指定的名片');
      }

      return selectedCards;
    });
  }

  /// 取消匯出
  void cancelExport() {
    _isCancelled = true;
    if (state.isExporting) {
      state = state.copyWith(isExporting: false, errorMessage: '匯出已取消');
    }
  }

  /// 分享匯出的檔案
  Future<void> shareExportedFile() async {
    try {
      final filePath = state.exportedFilePath;
      if (filePath == null) {
        state = state.copyWith(errorMessage: '請先匯出檔案');
        return;
      }

      final fileExists = await _fileSystemService.fileExists(filePath);
      if (!fileExists) {
        state = state.copyWith(errorMessage: '檔案不存在或已被刪除');
        return;
      }

      await _shareService.shareFile(filePath, '名片匯出檔案');
    } on Exception catch (e) {
      state = state.copyWith(errorMessage: '分享檔案失敗：$e');
    }
  }

  /// 清除錯誤狀態
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 執行匯出操作的核心邏輯
  Future<void> _performExport(
    Future<List<BusinessCard>> Function() getCards,
  ) async {
    if (state.isExporting) {
      return;
    }

    _isCancelled = false;
    _exportCompleter = Completer<void>();

    try {
      // 重置狀態
      state = state.copyWith(
        isExporting: true,
        progress: 0,
        errorMessage: null,
        exportedFilePath: null,
      );

      // 取得名片資料
      final cards = await getCards();

      if (_isCancelled) {
        _exportCompleter!.complete();
        return;
      }

      if (cards.isEmpty) {
        state = state.copyWith(isExporting: false, errorMessage: '沒有名片資料可匯出');
        _exportCompleter!.complete();
        return;
      }

      // 更新進度：資料載入完成
      state = state.copyWith(progress: 0.2);

      // 產生檔案內容
      final content = await _generateFileContent(cards);

      if (_isCancelled) {
        _exportCompleter!.complete();
        return;
      }

      // 更新進度：內容產生完成
      state = state.copyWith(progress: 0.7);

      // 儲存檔案
      final filePath = await _saveToFile(content);

      if (_isCancelled) {
        _exportCompleter!.complete();
        return;
      }

      // 完成匯出
      state = state.copyWith(
        isExporting: false,
        progress: 1,
        exportedFilePath: filePath,
      );

      _exportCompleter!.complete();
    } on Exception catch (e) {
      state = state.copyWith(
        isExporting: false,
        progress: 0,
        errorMessage: '匯出失敗：$e',
      );
      _exportCompleter!.complete();
    }
  }

  /// 根據選定格式產生檔案內容
  Future<String> _generateFileContent(List<BusinessCard> cards) async {
    switch (state.selectedFormat) {
      case ExportFormat.csv:
        return _generateCsvContent(cards);
      case ExportFormat.vcf:
        return _generateVcfContent(cards);
      case ExportFormat.json:
        return _generateJsonContent(cards);
    }
  }

  /// 產生 CSV 格式內容
  String _generateCsvContent(List<BusinessCard> cards) {
    final rows = <List<String>>[];

    // 標題列
    rows.add(['姓名', '職稱', '公司', '電子郵件', '電話', '地址', '網站', '備註', '建立日期']);

    // 資料列
    for (int i = 0; i < cards.length; i++) {
      if (_isCancelled) {
        break;
      }

      final card = cards[i];
      rows.add([
        card.name,
        card.jobTitle ?? '',
        card.company ?? '',
        card.email ?? '',
        card.phone ?? '',
        card.address ?? '',
        card.website ?? '',
        card.notes ?? '',
        card.createdAt.toIso8601String().split('T')[0],
      ]);

      // 更新進度（在內容產生範圍內）
      if (i % 10 == 0) {
        final progressInGeneration = (i / cards.length) * 0.5; // 內容產生佔總進度的50%
        state = state.copyWith(progress: 0.2 + progressInGeneration);
      }
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// 產生 VCF 格式內容
  String _generateVcfContent(List<BusinessCard> cards) {
    final buffer = StringBuffer();

    for (int i = 0; i < cards.length; i++) {
      if (_isCancelled) {
        break;
      }

      final card = cards[i];

      buffer.writeln('BEGIN:VCARD');
      buffer.writeln('VERSION:3.0');
      buffer.writeln('FN:${card.name}');

      if (card.jobTitle != null && card.jobTitle!.isNotEmpty) {
        buffer.writeln('TITLE:${card.jobTitle}');
      }

      if (card.company != null && card.company!.isNotEmpty) {
        buffer.writeln('ORG:${card.company}');
      }

      if (card.email != null && card.email!.isNotEmpty) {
        buffer.writeln('EMAIL:${card.email}');
      }

      if (card.phone != null && card.phone!.isNotEmpty) {
        buffer.writeln('TEL:${card.phone}');
      }

      if (card.address != null && card.address!.isNotEmpty) {
        buffer.writeln('ADR:;;${card.address};;;;');
      }

      if (card.website != null && card.website!.isNotEmpty) {
        buffer.writeln('URL:${card.website}');
      }

      if (card.notes != null && card.notes!.isNotEmpty) {
        buffer.writeln('NOTE:${card.notes}');
      }

      buffer.writeln('END:VCARD');

      if (i < cards.length - 1) {
        buffer.writeln();
      }

      // 更新進度
      if (i % 10 == 0) {
        final progressInGeneration = (i / cards.length) * 0.5;
        state = state.copyWith(progress: 0.2 + progressInGeneration);
      }
    }

    return buffer.toString();
  }

  /// 產生 JSON 格式內容
  String _generateJsonContent(List<BusinessCard> cards) {
    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'totalCards': cards.length,
      'format': 'JSON',
      'cards': cards
          .map(
            (card) => {
              'id': card.id,
              'name': card.name,
              'jobTitle': card.jobTitle,
              'company': card.company,
              'email': card.email,
              'phone': card.phone,
              'address': card.address,
              'website': card.website,
              'notes': card.notes,
              'createdAt': card.createdAt.toIso8601String(),
              'updatedAt': card.updatedAt?.toIso8601String(),
            },
          )
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// 儲存內容到檔案
  Future<String> _saveToFile(String content) async {
    final directory = await _fileSystemService
        .getApplicationDocumentsDirectory();
    final timestamp = DateTime.now();
    final dateStr =
        '${timestamp.year.toString().padLeft(4, '0')}'
        '${timestamp.month.toString().padLeft(2, '0')}'
        '${timestamp.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}'
        '${timestamp.minute.toString().padLeft(2, '0')}'
        '${timestamp.second.toString().padLeft(2, '0')}';

    final extension = _getFileExtension();
    final fileName = 'business_cards_${dateStr}_$timeStr.$extension';
    final filePath = '${directory.path}/$fileName';

    await _fileSystemService.writeFile(filePath, content);

    return filePath;
  }

  /// 取得檔案副檔名
  String _getFileExtension() {
    switch (state.selectedFormat) {
      case ExportFormat.csv:
        return 'csv';
      case ExportFormat.vcf:
        return 'vcf';
      case ExportFormat.json:
        return 'json';
    }
  }
}

/// ExportViewModel Provider
final exportViewModelProvider =
    StateNotifierProvider<ExportViewModel, ExportState>(
      (ref) => throw UnimplementedError(
        'ExportViewModel provider must be overridden',
      ),
    );
