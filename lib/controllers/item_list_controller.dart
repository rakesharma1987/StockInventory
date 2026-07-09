import 'package:get/get.dart' hide Category;

import '../models/category.dart';
import '../models/item.dart';
import '../repositories/category_repository.dart';
import '../repositories/item_repository.dart';
import 'view_state.dart';

/// Backs the item list / search / filter screen.
class ItemListController extends GetxController {
  ItemListController({
    ItemRepository? itemRepository,
    CategoryRepository? categoryRepository,
  })  : _itemRepository = itemRepository ?? ItemRepository(),
        _categoryRepository = categoryRepository ?? CategoryRepository();

  final ItemRepository _itemRepository;
  final CategoryRepository _categoryRepository;

  ViewState state = ViewState.idle;
  String? errorMessage;

  List<Item> items = [];
  List<Category> categories = [];

  String searchQuery = '';
  int? selectedCategoryId;
  bool lowStockOnly = false;

  Future<void> init() async {
    await Future.wait([loadCategories(), loadItems()]);
  }

  Future<void> loadCategories() async {
    categories = await _categoryRepository.getAll();
    update();
  }

  Future<void> loadItems() async {
    state = ViewState.loading;
    update();
    try {
      items = await _itemRepository.search(
        query: searchQuery,
        categoryId: selectedCategoryId,
        lowStockOnly: lowStockOnly,
      );
      state = ViewState.idle;
    } catch (e) {
      state = ViewState.error;
      errorMessage = e.toString();
    }
    update();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    loadItems();
  }

  void setCategoryFilter(int? categoryId) {
    selectedCategoryId = categoryId;
    loadItems();
  }

  void toggleLowStockOnly(bool value) {
    lowStockOnly = value;
    loadItems();
  }

  Future<void> deleteItem(int id) async {
    await _itemRepository.delete(id);
    await loadItems();
  }
}
