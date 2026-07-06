import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../models/stock_transaction.dart';
import '../../viewmodels/stock_transaction_viewmodel.dart';

/// Lets the user record a Stock In / Stock Out / Adjustment against a
/// single item, and shows that item's movement history below the form.
class StockTransactionScreen extends StatelessWidget {
  const StockTransactionScreen({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StockTransactionViewModel(item: item)..loadHistory(),
      child: const _StockTransactionBody(),
    );
  }
}

class _StockTransactionBody extends StatefulWidget {
  const _StockTransactionBody();

  @override
  State<_StockTransactionBody> createState() => _StockTransactionBodyState();
}

class _StockTransactionBodyState extends State<_StockTransactionBody> {
  TransactionType _type = TransactionType.stockIn;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = context.read<StockTransactionViewModel>();
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid number.')),
      );
      return;
    }

    final error = await vm.submit(
      type: _type,
      quantity: amount,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      _amountCtrl.clear();
      _noteCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock updated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StockTransactionViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text('Stock Movements · ${vm.item.name}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(value: TransactionType.stockIn, label: Text('In'), icon: Icon(Icons.add)),
                        ButtonSegment(value: TransactionType.stockOut, label: Text('Out'), icon: Icon(Icons.remove)),
                        ButtonSegment(value: TransactionType.adjustment, label: Text('Adjust'), icon: Icon(Icons.tune)),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) => setState(() => _type = s.first),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                        labelText: _type == TransactionType.adjustment
                            ? 'Delta (+/-) e.g. -2 or 5'
                            : 'Quantity',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(labelText: 'Note (optional)'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: vm.isSubmitting ? null : _submit,
                        child: vm.isSubmitting
                            ? const SizedBox(
                                height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Current: ${vm.item.quantity} ${vm.item.unit ?? ''}'.trim()),
              ],
            ),
          ),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.history.isEmpty
                    ? const Center(child: Text('No movements recorded yet.'))
                    : ListView.builder(
                        itemCount: vm.history.length,
                        itemBuilder: (context, i) {
                          final t = vm.history[i];
                          return ListTile(
                            leading: Icon(
                              t.type == TransactionType.stockIn
                                  ? Icons.add_circle_outline
                                  : t.type == TransactionType.stockOut
                                      ? Icons.remove_circle_outline
                                      : Icons.tune,
                            ),
                            title: Text(t.type.label),
                            subtitle: t.note != null ? Text(t.note!) : null,
                            trailing: Text(
                              _signedLabel(t),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// [StockTransaction.quantity] is stored as a plain positive magnitude for
/// stockIn/stockOut (the repository derives the actual +/- effect from
/// [TransactionType]) but as an already-signed delta for adjustments. This
/// normalizes all three into one display string so stock-out rows show a
/// leading "-" instead of looking identical to stock-in rows.
String _signedLabel(StockTransaction t) {
  switch (t.type) {
    case TransactionType.stockIn:
      return '+${t.quantity}';
    case TransactionType.stockOut:
      return '-${t.quantity}';
    case TransactionType.adjustment:
      return t.quantity > 0 ? '+${t.quantity}' : '${t.quantity}';
  }
}
