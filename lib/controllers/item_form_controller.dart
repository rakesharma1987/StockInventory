import 'package:get/get.dart' hide Category;

import '../models/category.dart';
import '../models/item.dart';
import '../repositories/category_repository.dart';
import '../repositories/item_repository.dart';

/// Backs the "add / edit item" form. Holds a working copy of the item's
/// fields as plain properties (simpler for TextEditingControllers to bind
/// to than re-building an immutable [Item] on every keystroke).
class ItemFormController extends GetxController {
  ItemFormController({
    Item? existingItem,
    ItemRepository? itemRepository,
    CategoryRepository? categoryRepository,
  })  : editingItem = existingItem,
        _itemRepository = itemRepository ?? ItemRepository(),
        _categoryRepository = categoryRepository ?? CategoryRepository() {
    if (existingItem != null) {
      name = existingItem.name;
      barcode = existingItem.barcode ?? '';
      categoryId = existingItem.categoryId;
      quantity = existingItem.quantity;
      unitPrice = existingItem.unitPrice;
      lowStockThreshold = existingItem.lowStockThreshold;
      unit = existingItem.unit ?? '';
      notes = existingItem.notes ?? '';
    }
  }

  final Item? editingItem;
  final ItemRepository _itemRepository;
  final CategoryRepository _categoryRepository;

  bool get isEditing => editingItem != null;

  String name = '';
  String barcode = '';
  int? categoryId;
  double quantity = 0;
  double unitPrice = 0;
  double lowStockThreshold = 0;
  String unit = '';
  String notes = '';

  List<Category> categories = [];
  bool categoriesLoaded = false;
  bool isSaving = false;
  String? errorMessage;

  Future<void> loadCategories() async {
    categories = await _categoryRepository.getAll();
    if (categoryId == null && categories.isNotEmpty) {
      categoryId = categories.first.id;
    }
    categoriesLoaded = true;
    update();
  }

  void setBarcode(String value) {
    barcode = value;
    update();
  }

  void setCategoryId(int? value) {
    categoryId = value;
    update();
  }

  /// Validates + persists the item. Returns null on success, or an error
  /// message to show the user.
  Future<String?> save() async {
    if (name.trim().isEmpty) {
      return 'Item name is required.';
    }
    isSaving = true;
    update();

    try {
      final trimmedBarcode = barcode.trim();
      if (trimmedBarcode.isNotEmpty) {
        final taken = await _itemRepository.isBarcodeTaken(
          trimmedBarcode,
          excludeId: editingItem?.id,
        );
        if (taken) {
          return 'Another item already uses this barcode.';
        }
      }

      final now = DateTime.now();
      final item = Item(
        id: editingItem?.id,
        name: name.trim(),
        barcode: trimmedBarcode.isEmpty ? null : trimmedBarcode,
        categoryId: categoryId,
        quantity: quantity,
        unitPrice: unitPrice,
        lowStockThreshold: lowStockThreshold,
        unit: unit.trim().isEmpty ? null : unit.trim(),
        notes: notes.trim().isEmpty ? null : notes.trim(),
        createdAt: editingItem?.createdAt ?? now,
        updatedAt: now,
      );

      if (isEditing) {
        await _itemRepository.update(item);
      } else {
        await _itemRepository.insert(item);
      }
      return null;
    } catch (e) {
      return 'Failed to save item: $e';
    } finally {
      isSaving = false;
      update();
    }
  }
}
