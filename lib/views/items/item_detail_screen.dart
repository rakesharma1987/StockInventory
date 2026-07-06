import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/item.dart';
import '../../repositories/item_repository.dart';
import '../transactions/stock_transaction_screen.dart';
import 'item_form_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final int itemId;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _repository = ItemRepository();
  Item? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final item = await _repository.getById(widget.itemId);
    setState(() {
      _item = item;
      _loading = false;
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('This will permanently delete "${_item!.name}" and its transaction history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repository.delete(widget.itemId);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final item = _item;
    if (item == null) {
      return const Scaffold(body: Center(child: Text('Item not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ItemFormScreen(existingItem: item)),
              );
              _load();
            },
          ),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.quantity.toStringAsFixed(
                          item.quantity.truncateToDouble() == item.quantity ? 0 : 2,
                        ),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: item.isLowStock ? AppTheme.danger : AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (item.isLowStock)
                        const Chip(
                          label: Text('Low stock', style: TextStyle(color: Colors.white)),
                          backgroundColor: AppTheme.danger,
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  _InfoRow(label: 'Category', value: item.categoryName ?? '—'),
                  _InfoRow(label: 'Barcode', value: item.barcode ?? '—'),
                  _InfoRow(label: 'Unit price', value: formatCurrency(item.unitPrice)),
                  _InfoRow(label: 'Total value', value: formatCurrency(item.totalValue)),
                  _InfoRow(label: 'Low stock alert at', value: item.lowStockThreshold.toString()),
                  if (item.notes != null && item.notes!.isNotEmpty)
                    _InfoRow(label: 'Notes', value: item.notes!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Stock In'),
                  onPressed: () => _openTransactions(context, item),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.remove),
                  label: const Text('Stock Out'),
                  onPressed: () => _openTransactions(context, item),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.history),
            label: const Text('View history & adjust'),
            onPressed: () => _openTransactions(context, item),
          ),
        ],
      ),
    );
  }

  Future<void> _openTransactions(BuildContext context, Item item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StockTransactionScreen(item: item)),
    );
    _load();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
