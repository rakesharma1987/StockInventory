import 'package:sqflite/sqflite.dart';

import '../core/db/database_helper.dart';
import '../models/category.dart';

/// Data-access layer for [Category]. ViewModels never touch sqflite
/// directly - they always go through a repository like this one.
class CategoryRepository {
  CategoryRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<List<Category>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableCategories,
      orderBy: 'name ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<Category?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableCategories,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Category.fromMap(rows.first);
  }

  Future<int> insert(Category category) async {
    final db = await _dbHelper.database;
    return db.insert(
      DatabaseHelper.tableCategories,
      category.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> update(Category category) async {
    final db = await _dbHelper.database;
    return db.update(
      DatabaseHelper.tableCategories,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Deletes a category. Items referencing it will have their
  /// category_id set to NULL (see ON DELETE SET NULL in the schema).
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      DatabaseHelper.tableCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> countItemsInCategory(int categoryId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM ${DatabaseHelper.tableItems} WHERE category_id = ?',
      [categoryId],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }
}
