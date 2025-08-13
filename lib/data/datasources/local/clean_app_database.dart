import 'dart:io';

import 'package:busines_card_scanner_flutter/domain/entities/business_card.dart' as domain;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'clean_app_database.g.dart';

/// 名片資料表定義
/// 
/// 對應 Domain 層的 BusinessCard 實體
/// 使用 Drift 的聲明式語法定義資料表結構
@DataClassName('BusinessCardData')
class BusinessCards extends Table {
  /// 主鍵 - 自動生成的唯一識別碼
  IntColumn get id => integer().autoIncrement()();
  
  /// 姓名（必填）
  TextColumn get name => text().withLength(min: 1, max: 100)();
  
  /// 職稱（可選）
  TextColumn get jobTitle => text().withLength(max: 100).nullable()();
  
  /// 公司名稱（可選）
  TextColumn get company => text().withLength(max: 100).nullable()();
  
  /// 電子郵件（可選）
  TextColumn get email => text().withLength(max: 200).nullable()();
  
  /// 電話號碼（可選）
  TextColumn get phone => text().withLength(max: 50).nullable()();
  
  /// 地址（可選）
  TextColumn get address => text().withLength(max: 500).nullable()();
  
  /// 網站（可選）
  TextColumn get website => text().withLength(max: 200).nullable()();
  
  /// 備註（可選）
  TextColumn get notes => text().withLength(max: 1000).nullable()();
  
  /// 建立時間（自動設定）
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// 最後更新時間（自動更新）
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 名片資料存取物件
/// 
/// 提供所有與名片資料表相關的資料庫操作
/// 包含基本 CRUD、搜尋、過濾、排序等功能
@DriftAccessor(tables: [BusinessCards])
class CardDao extends DatabaseAccessor<CleanAppDatabase> with _$CardDaoMixin {
  CardDao(super.db);

  /// 建立新名片
  Future<int> insertBusinessCard(BusinessCardsCompanion card) async {
    return into(businessCards).insert(card);
  }

  /// 根據 ID 取得名片
  Future<domain.BusinessCard?> getBusinessCardById(int id) async {
    final query = select(businessCards)..where((tbl) => tbl.id.equals(id));
    final result = await query.getSingleOrNull();
    if (result == null) {
      return null;
    }
    return _mapToDomainBusinessCard(result);
  }

  /// 取得所有名片（分頁）
  Future<List<domain.BusinessCard>> getAllBusinessCards({
    int limit = 50,
    int offset = 0,
  }) async {
    final query = select(businessCards)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
      ..limit(limit, offset: offset);
    final results = await query.get();
    return results.map(_mapToDomainBusinessCard).toList();
  }

  /// 搜尋名片
  Future<List<domain.BusinessCard>> searchBusinessCards(String keyword) async {
    final normalizedKeyword = '%${keyword.toLowerCase()}%';
    final query = select(businessCards)
      ..where((tbl) =>
          tbl.name.lower().like(normalizedKeyword) |
          tbl.company.lower().like(normalizedKeyword) |
          tbl.jobTitle.lower().like(normalizedKeyword) |
          tbl.email.lower().like(normalizedKeyword) |
          tbl.phone.like(normalizedKeyword))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    final results = await query.get();
    return results.map(_mapToDomainBusinessCard).toList();
  }

  /// 更新名片
  Future<bool> updateBusinessCard(domain.BusinessCard card) async {
    final cardIdInt = int.tryParse(card.id);
    if (cardIdInt == null) {
      throw ArgumentError('Invalid card ID format: ${card.id}');
    }
    final result = await (update(businessCards)
          ..where((tbl) => tbl.id.equals(cardIdInt)))
        .write(BusinessCardsCompanion(
      name: Value(card.name),
      jobTitle: Value(card.jobTitle),
      company: Value(card.company),
      email: Value(card.email),
      phone: Value(card.phone),
      address: Value(card.address),
      website: Value(card.website),
      notes: Value(card.notes),
      updatedAt: Value(DateTime.now()),
    ));
    return result > 0;
  }

  /// 刪除名片
  Future<bool> deleteBusinessCard(int id) async {
    final result = await (delete(businessCards)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
    return result > 0;
  }

  /// 取得名片總數
  Future<int> getBusinessCardCount() async {
    final countExp = businessCards.id.count();
    final query = selectOnly(businessCards)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp)!;
  }

  /// 轉換 Drift BusinessCardData 到 Domain BusinessCard
  domain.BusinessCard _mapToDomainBusinessCard(BusinessCardData dbCard) {
    return domain.BusinessCard(
      id: dbCard.id.toString(),
      name: dbCard.name,
      jobTitle: dbCard.jobTitle,
      company: dbCard.company,
      email: dbCard.email,
      phone: dbCard.phone,
      address: dbCard.address,
      website: dbCard.website,
      notes: dbCard.notes,
      createdAt: dbCard.createdAt,
      updatedAt: dbCard.updatedAt,
    );
  }
}

/// 應用程式資料庫
/// 
/// 使用 Drift 建構的 SQLite 資料庫
/// 提供名片資料的持久化儲存
@DriftDatabase(tables: [BusinessCards], daos: [CardDao])
class CleanAppDatabase extends _$CleanAppDatabase {
  CleanAppDatabase(super.e);

  /// 建立預設的資料庫實例（用於正常使用）
  factory CleanAppDatabase.defaultInstance() {
    return CleanAppDatabase(_createNativeExecutor('business_cards.sqlite'));
  }

  /// 建立測試用的記憶體資料庫實例
  factory CleanAppDatabase.memory() {
    return CleanAppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 1;

  /// 建立原生 SQLite 執行器
  static LazyDatabase _createNativeExecutor(String fileName) {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, fileName));
      return NativeDatabase(file);
    });
  }
}