import '../core/db/database_helper.dart';
import '../models/stock_transaction.dart';

/// Thrown when a stock movement would leave an item with negative quantity.
class InsufficientStockException implements Exception {
  InsufficientStockException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Data-access layer for [StockTransaction]. This is the only place that
/// mutates [Item.quantity] - it always does so inside a DB transaction
/// alongside the audit-trail row, so the two can never drift apart.
class TransactionRepository {
  TransactionRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  /// Records a stock movement and atomically applies it to the item's
  /// quantity.
  ///
  /// - [TransactionType.stockIn]: [quantity] (must be > 0) is added.
  /// - [TransactionType.stockOut]: [quantity] (must be > 0) is subtracted;
  ///   throws [InsufficientStockException] if that would go negative.
  /// - [TransactionType.adjustment]: [quantity] is a signed delta applied
  ///   directly (can be positive or negative), for correcting counts.
  Future<StockTransaction> recordTransaction({
    required int itemId,
    required TransactionType type,
    required double quantity,
    String? note,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    return db.transaction<StockTransaction>((txn) async {
      final itemRows = await txn.query(
        DatabaseHelper.tableItems,
        columns: ['quantity'],
        where: 'id = ?',
        whereArgs: [itemId],
        limit: 1,
      );
      if (itemRows.isEmpty) {
        throw StateError('Item $itemId not found');
      }
      final currentQty = (itemRows.first['quantity'] as num).toDouble();

      double delta;
      switch (type) {
        case TransactionType.stockIn:
          delta = quantity.abs();
          break;
        case TransactionType.stockOut:
          delta = -quantity.abs();
          break;
        case TransactionType.adjustment:
          delta = quantity;
          break;
      }

      final newQty = currentQty + delta;
      if (newQty < 0) {
        throw InsufficientStockException(
          'Not enough stock: have $currentQty, tried to remove ${delta.abs()}',
        );
      }

      await txn.update(
        DatabaseHelper.tableItems,
        {'quantity': newQty, 'updated_at': now.toIso8601String()},
        where: 'id = ?',
        whereArgs: [itemId],
      );

      final txModel = StockTransaction(
        itemId: itemId,
        type: type,
        quantity: quantity,
        note: note,
        createdAt: now,
      );

      final id = await txn.insert(
        DatabaseHelper.tableTransactions,
        txModel.toMap()..remove('id'),
      );

      return StockTransaction(
        id: id,
        itemId: itemId,
        type: type,
        quantity: quantity,
        note: note,
        createdAt: now,
      );
    });
  }

  Future<List<StockTransaction>> getForItem(int itemId, {int limit = 100}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableTransactions,
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(StockTransaction.fromMap).toList();
  }

  Future<List<StockTransaction>> getRecent({int limit = 20}) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT t.*, i.name AS item_name
      FROM ${DatabaseHelper.tableTransactions} t
      JOIN ${DatabaseHelper.tableItems} i ON i.id = t.item_id
      ORDER BY t.created_at DESC
      LIMIT ?
    ''', [limit]);
    return rows.map(StockTransaction.fromMap).toList();
  }
}
