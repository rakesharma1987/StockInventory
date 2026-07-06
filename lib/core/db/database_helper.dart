import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Single source of truth for the on-device SQLite database.
///
/// This app is fully offline: all reads/writes go through this helper and
/// nothing is synced to a remote server. It is a plain singleton (not a
/// ViewModel) because it belongs to the "Model" layer in MVVM - repositories
/// depend on it, ViewModels depend on repositories.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String dbName = 'stock_inventory.db';
  static const int dbVersion = 1;

  static const String tableCategories = 'categories';
  static const String tableItems = 'items';
  static const String tableTransactions = 'stock_transactions';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final Directory docsDir = await getApplicationDocumentsDirectory();
    final String dbPath = p.join(docsDir.path, dbName);

    return openDatabase(
      dbPath,
      version: dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableCategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT UNIQUE,
        category_id INTEGER,
        quantity REAL NOT NULL DEFAULT 0,
        unit_price REAL NOT NULL DEFAULT 0,
        low_stock_threshold REAL NOT NULL DEFAULT 0,
        unit TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES $tableCategories (id)
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES $tableItems (id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_items_category ON $tableItems (category_id)',
    );
    await db.execute(
      'CREATE INDEX idx_items_barcode ON $tableItems (barcode)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_item ON $tableTransactions (item_id)',
    );

    await _seedDefaultCategories(db);
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    const defaults = ['General', 'Electronics', 'Groceries', 'Stationery'];
    for (final name in defaults) {
      await db.insert(tableCategories, {
        'name': name,
        'description': null,
        'created_at': now,
      });
    }
  }

  /// Wipes and recreates the database. Intended for debug/testing use only.
  Future<void> resetDatabase() async {
    final db = await database;
    await db.close();
    _db = null;
    final Directory docsDir = await getApplicationDocumentsDirectory();
    final String dbPath = p.join(docsDir.path, dbName);
    await deleteDatabase(dbPath);
    _db = await _initDatabase();
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
