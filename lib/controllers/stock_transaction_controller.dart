import 'package:get/get.dart';

import '../models/item.dart';
import '../models/stock_transaction.dart';
import '../repositories/item_repository.dart';
import '../repositories/transaction_repository.dart';

/// Backs the "stock in / stock out / adjust" screen for a single item,
/// and its transaction history list.
class StockTransactionController extends GetxController {
  StockTransactionController({
    required this.item,
    ItemRepository? itemRepository,
    TransactionRepository? transactionRepository,
  })  : _itemRepository = itemRepository ?? ItemRepository(),
        _transactionRepository = transactionRepository ?? TransactionRepository();

  Item item;
  final ItemRepository _itemRepository;
  final TransactionRepository _transactionRepository;

  List<StockTransaction> history = [];
  bool isLoading = false;
  bool isSubmitting = false;

  Future<void> loadHistory() async {
    isLoading = true;
    update();
    history = await _transactionRepository.getForItem(item.id!);
    isLoading = false;
    update();
  }

  /// Applies a movement and refreshes the local [item] + [history].
  /// Returns null on success, or an error message.
  Future<String?> submit({
    required TransactionType type,
    required double quantity,
    String? note,
  }) async {
    if (quantity <= 0 && type != TransactionType.adjustment) {
      return 'Quantity must be greater than zero.';
    }
    if (quantity == 0 && type == TransactionType.adjustment) {
      return 'Adjustment amount cannot be zero.';
    }

    isSubmitting = true;
    update();
    try {
      await _transactionRepository.recordTransaction(
        itemId: item.id!,
        type: type,
        quantity: quantity,
        note: note,
      );
      final refreshed = await _itemRepository.getById(item.id!);
      if (refreshed != null) item = refreshed;
      await loadHistory();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      isSubmitting = false;
      update();
    }
  }
}
