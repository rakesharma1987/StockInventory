import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/category_viewmodel.dart';
import '../../widgets/empty_state.dart';
import 'category_form_screen.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoryViewModel()..load(),
      child: const _CategoryListBody(),
    );
  }
}

class _CategoryListBody extends StatelessWidget {
  const _CategoryListBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.categories.isEmpty
              ? const EmptyState(icon: Icons.category_outlined, message: 'No categories yet.')
              : ListView.builder(
                  itemCount: vm.categories.length,
                  itemBuilder: (context, index) {
                    final category = vm.categories[index];
                    return ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: Text(category.name),
                      subtitle: category.description != null ? Text(category.description!) : null,
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'edit') {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => CategoryFormScreen(existing: category)),
                            );
                            vm.load();
                          } else if (action == 'delete') {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete category?'),
                                content: Text('Delete "${category.name}"? Items in it become uncategorized.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              final warning = await vm.deleteCategory(category.id!);
                              if (warning != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(warning)));
                              }
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CategoryFormScreen()),
          );
          vm.load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
