import 'package:get/get.dart' hide Category;

import '../models/category.dart';
import '../repositories/category_repository.dart';

/// Backs the category list + add/edit category screens.
class CategoryController extends GetxController {
  CategoryController({CategoryRepository? repository})
      : _repository = repository ?? CategoryRepository();

  final CategoryRepository _repository;

  List<Category> categories = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    update();
    categories = await _repository.getAll();
    isLoading = false;
    update();
  }

  Future<String?> addCategory(String name, {String? description}) async {
    if (name.trim().isEmpty) return 'Category name is required.';
    try {
      await _repository.insert(Category(
        name: name.trim(),
        description: description?.trim().isEmpty ?? true ? null : description!.trim(),
        createdAt: DateTime.now(),
      ));
      await load();
      return null;
    } catch (e) {
      return 'Could not add category (maybe it already exists): $e';
    }
  }

  Future<String?> updateCategory(Category category) async {
    try {
      await _repository.update(category);
      await load();
      return null;
    } catch (e) {
      return 'Could not update category: $e';
    }
  }

  /// Returns null on success, or a warning message if the category still
  /// has items attached (deletion still proceeds - those items just lose
  /// their category, per the DB's ON DELETE SET NULL rule).
  Future<String?> deleteCategory(int id) async {
    final itemCount = await _repository.countItemsInCategory(id);
    await _repository.delete(id);
    await load();
    if (itemCount > 0) {
      return '$itemCount item(s) were uncategorized.';
    }
    return null;
  }
}
