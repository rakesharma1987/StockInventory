import 'package:sqflite/sqflite.dart';

import '../core/db/database_helper.dart';
import '../models/item.dart';

/// Data-access layer for [Item]. Handles search/filter queries with a
/// LEFT JOIN against categories so callers get a ready-to-display
/// [Item.categoryName] without a second query.
class ItemRepository {
  ItemRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  static const String _joinedSelect = '''
    SELECT i.*, c.name AS category_name
    FROM ${DatabaseHelper.tableItems} i
    LEFT JOIN ${DatabaseHelper.tableCategories} c ON c.id = i.category_id
  ''';

  /// Returns items, optionally filtered by a search term (matches name or
  /// barcode), a category, and/or restricted to items at/under their
  /// low-stock threshold.
  Future<List<Item>> search({
    String? query,
    int? categoryId,
    bool lowStockOnly = false,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <Object?>[];

    if (query != null && query.trim().isNotEmpty) {
      where.add('(i.name LIKE ? OR i.barcode LIKE ?)');
      final like = '%${query.trim()}%';
      args.addAll([like, like]);
    }
    if (categoryId != null) {
      where.add('i.category_id = ?');
      args.add(categoryId);
    }
    if (lowStockOnly) {
      where.add('i.quantity <= i.low_stock_threshold');
    }

    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery(
      '$_joinedSelect $whereClause ORDER BY i.name ASC',
      args,
    );
    return rows.map(Item.fromMap).toList();
  }

  Future<List<Item>> getAll() => search();

  Future<Item?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('$_joinedSelect WHERE i.id = ? LIMIT 1', [id]);
    if (rows.isEmpty) return null;
    return Item.fromMap(rows.first);
  }

  Future<Item?> getByBarcode(String barcode) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '$_joinedSelect WHERE i.barcode = ? LIMIT 1',
      [barcode],
    );
    if (rows.isEmpty) return null;
    return Item.fromMap(rows.first);
  }

  Future<int> countAll() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM ${DatabaseHelper.tableItems}',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<int> countLowStock() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM ${DatabaseHelper.tableItems} WHERE quantity <= low_stock_threshold',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<double> totalInventoryValue() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(quantity * unit_price), 0) AS total FROM ${DatabaseHelper.tableItems}',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> insert(Item item) async {
    final db = await _dbHelper.database;
    final map = item.toMap()..remove('id');
    return db.insert(
      DatabaseHelper.tableItems,
      map,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> update(Item item) async {
    final db = await _dbHelper.database;
    final map = item.toMap();
    return db.update(
      DatabaseHelper.tableItems,
      map,
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseHelper.tableItems,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// True if [barcode] is already used by another item (excluding [excludeId]).
  Future<bool> isBarcodeTaken(String barcode, {int? excludeId}) async {
    final db = await _dbHelper.database;
    final where = excludeId == null ? 'barcode = ?' : 'barcode = ? AND id != ?';
    final args = excludeId == null ? [barcode] : [barcode, excludeId];
    final rows = await db.query(
      DatabaseHelper.tableItems,
      where: where,
      whereArgs: args,
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
