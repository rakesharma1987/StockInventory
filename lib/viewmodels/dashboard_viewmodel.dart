import 'package:flutter/foundation.dart';

import '../models/stock_transaction.dart';
import '../repositories/item_repository.dart';
import '../repositories/transaction_repository.dart';

enum ViewState { idle, loading, error }

/// Powers the dashboard/home screen: quick counters + recent activity.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    ItemRepository? itemRepository,
    TransactionRepository? transactionRepository,
  })  : _itemRepository = itemRepository ?? ItemRepository(),
        _transactionRepository = transactionRepository ?? TransactionRepository();

  final ItemRepository _itemRepository;
  final TransactionRepository _transactionRepository;

  ViewState state = ViewState.idle;
  String? errorMessage;

  int totalItems = 0;
  int lowStockCount = 0;
  double totalInventoryValue = 0;
  List<StockTransaction> recentTransactions = [];

  Future<void> load() async {
    state = ViewState.loading;
    notifyListeners();
    try {
      totalItems = await _itemRepository.countAll();
      lowStockCount = await _itemRepository.countLowStock();
      totalInventoryValue = await _itemRepository.totalInventoryValue();
      recentTransactions = await _transactionRepository.getRecent(limit: 10);
      state = ViewState.idle;
    } catch (e) {
      state = ViewState.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }
}
