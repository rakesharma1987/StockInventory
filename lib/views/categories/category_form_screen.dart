import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../repositories/category_repository.dart';

/// Talks to [CategoryRepository] directly rather than going through
/// CategoryController.
///
/// This screen is opened via Navigator.push from CategoryListScreen. The
/// caller already reloads its list after this screen pops, so this screen
/// doesn't need to touch that controller at all - it just needs to save and
/// get out of the way.
class CategoryFormScreen extends StatefulWidget {
  const CategoryFormScreen({super.key, this.existing});

  final Category? existing;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _repository = CategoryRepository();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    String? error;
    try {
      final trimmedName = _nameCtrl.text.trim();
      final trimmedDescription = _descCtrl.text.trim();
      if (widget.existing != null) {
        await _repository.update(Category(
          id: widget.existing!.id,
          name: trimmedName,
          description: trimmedDescription.isEmpty ? null : trimmedDescription,
          createdAt: widget.existing!.createdAt,
        ));
      } else {
        await _repository.insert(Category(
          name: trimmedName,
          description: trimmedDescription.isEmpty ? null : trimmedDescription,
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      error = 'Could not save category (maybe the name already exists): $e';
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing != null ? 'Edit Category' : 'New Category')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
