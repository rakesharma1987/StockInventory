import 'package:flutter/foundation.dart';

import '../models/item.dart';
import '../repositories/item_repository.dart';

enum ScanLookupResult { found, notFound, idle }

/// Backs the barcode scanner screen. Given a scanned code, looks the item
/// up so the View can decide whether to open the item's detail page or
/// offer to create a new item pre-filled with that barcode.
class ScannerViewModel extends ChangeNotifier {
  ScannerViewModel({ItemRepository? itemRepository})
      : _itemRepository = itemRepository ?? ItemRepository();

  final ItemRepository _itemRepository;

  ScanLookupResult result = ScanLookupResult.idle;
  Item? foundItem;
  String? lastScannedCode;
  bool _isLookingUp = false;

  Future<void> onCodeScanned(String code) async {
    // Debounce: mobile_scanner fires repeatedly while a code is in frame.
    if (_isLookingUp || code == lastScannedCode) return;
    _isLookingUp = true;
    lastScannedCode = code;

    final item = await _itemRepository.getByBarcode(code);
    foundItem = item;
    result = item != null ? ScanLookupResult.found : ScanLookupResult.notFound;
    _isLookingUp = false;
    notifyListeners();
  }

  void reset() {
    result = ScanLookupResult.idle;
    foundItem = null;
    lastScannedCode = null;
    notifyListeners();
  }
}
