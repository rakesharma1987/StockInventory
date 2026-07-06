import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/formatters.dart';
import '../../models/stock_transaction.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_tile.dart';
import '../items/item_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  /// [viewModel]: pass in an already-created, longer-lived
  /// DashboardViewModel (e.g. one owned by AppShell) so it can be refreshed
  /// from outside - such as whenever the Dashboard tab is re-selected. If
  /// omitted, this screen creates and owns its own (handy for previews or
  /// standalone use).
  const DashboardScreen({super.key, this.viewModel});

  final DashboardViewModel? viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel != null) {
      return ChangeNotifierProvider.value(
        value: viewModel!,
        child: const _DashboardBody(),
      );
    }
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel()..load(),
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Inventory')),
      body: RefreshIndicator(
        onRefresh: () => vm.load(),
        child: vm.state == ViewState.loading && vm.recentTransactions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // Fixed tile height (mainAxisExtent) instead of an
                    // aspect ratio: aspect ratio derives height from width,
                    // which overflows once the icon + two lines of text no
                    // longer fit (e.g. larger system font scale). A fixed
                    // extent plus the FittedBox/ellipsis in StatTile keeps
                    // this safe regardless of text scale.
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: 100,
                    ),
                    children: [
                      StatTile(
                        label: 'Total items',
                        value: '${vm.totalItems}',
                        icon: Icons.inventory_2_outlined,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ItemListScreen()),
                          );
                          if (context.mounted) vm.load();
                        },
                      ),
                      StatTile(
                        label: 'Low stock',
                        value: '${vm.lowStockCount}',
                        icon: Icons.warning_amber_rounded,
                        color: vm.lowStockCount > 0 ? Colors.red : null,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ItemListScreen(initialLowStockOnly: true),
                            ),
                          );
                          if (context.mounted) vm.load();
                        },
                      ),
                      StatTile(
                        label: 'Inventory value',
                        value: formatCurrency(vm.totalInventoryValue),
                        icon: Icons.payments_outlined,
                      ),
                      StatTile(
                        label: 'Recent activity',
                        value: '${vm.recentTransactions.length}',
                        icon: Icons.history,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Recent activity', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (vm.recentTransactions.isEmpty)
                    const EmptyState(
                      icon: Icons.history,
                      message: 'No stock movements yet.\nUse Stock In / Out from an item to get started.',
                    )
                  else
                    ...vm.recentTransactions.map((t) => _TransactionTile(t: t)),
                ],
              ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.t});
  final StockTransaction t;

  @override
  Widget build(BuildContext context) {
    final isIn = t.type == TransactionType.stockIn;
    final isOut = t.type == TransactionType.stockOut;
    final color = isIn ? Colors.green : (isOut ? Colors.red : Colors.orange);
    final icon = isIn ? Icons.add_circle_outline : (isOut ? Icons.remove_circle_outline : Icons.tune);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(t.itemName ?? 'Item #${t.itemId}'),
        subtitle: Text('${t.type.label}${t.note != null ? ' • ${t.note}' : ''}'),
        trailing: Text(
          '${t.quantity > 0 ? '+' : ''}${t.quantity.toStringAsFixed(t.quantity.truncateToDouble() == t.quantity ? 0 : 2)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
