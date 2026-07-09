import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/category_controller.dart';
import '../../widgets/empty_state.dart';
import 'category_form_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(CategoryController())..load();
  }

  @override
  void dispose() {
    Get.delete<CategoryController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(
      builder: (vm) => _CategoryListBody(vm: vm),
    );
  }
}

class _CategoryListBody extends StatelessWidget {
  const _CategoryListBody({required this.vm});

  final CategoryController vm;

  @override
  Widget build(BuildContext context) {
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
