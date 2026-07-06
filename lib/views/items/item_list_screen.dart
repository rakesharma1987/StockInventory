import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../viewmodels/item_list_viewmodel.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_card.dart';
import 'item_detail_screen.dart';
import 'item_form_screen.dart';

class ItemListScreen extends StatelessWidget {
  const ItemListScreen({super.key, this.initialLowStockOnly = false});

  final bool initialLowStockOnly;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = ItemListViewModel();
        vm.lowStockOnly = initialLowStockOnly;
        vm.init();
        return vm;
      },
      child: const _ItemListBody(),
    );
  }
}

class _ItemListBody extends StatefulWidget {
  const _ItemListBody();

  @override
  State<_ItemListBody> createState() => _ItemListBodyState();
}

class _ItemListBodyState extends State<_ItemListBody> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemListViewModel>();

    return Scaffold(
      appBar: AppBar(
        // Reflects why the user is looking at this list - e.g. arriving
        // here from the dashboard's "Low stock" tile should say so, rather
        // than just a generic "Items" that doesn't explain the filter.
        title: Text(vm.lowStockOnly ? 'Low Stock Items' : 'Items'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: vm.setSearchQuery,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or barcode...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _FilterBar(vm: vm),
          Expanded(
            child: vm.items.isEmpty
                ? EmptyState(
                    icon: Icons.inventory_2_outlined,
                    message: vm.lowStockOnly
                        ? 'No low-stock items. Nice!'
                        : 'No items yet. Tap + to add your first item.',
                  )
                : ListView.builder(
                    itemCount: vm.items.length,
                    itemBuilder: (context, index) {
                      final item = vm.items[index];
                      return ItemCard(
                        item: item,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id!)),
                          );
                          vm.loadItems();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ItemFormScreen()),
          );
          vm.loadItems();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.vm});
  final ItemListViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int?>(
              value: vm.selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Category', isDense: true),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('All categories')),
                ...vm.categories.map(
                  (Category c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                ),
              ],
              onChanged: vm.setCategoryFilter,
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: 'Only show items at or below their low-stock alert level',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Low stock only',
                  style: TextStyle(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                Switch(
                  value: vm.lowStockOnly,
                  onChanged: vm.toggleLowStockOnly,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
