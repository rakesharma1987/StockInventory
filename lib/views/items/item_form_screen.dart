import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/item_form_controller.dart';
import '../../models/item.dart';
import '../scanner/barcode_scanner_screen.dart';

/// Add or edit an [Item]. Pass [existingItem] to edit; omit to create new.
/// [prefilledBarcode] is used when arriving here from the scanner after a
/// scanned code didn't match any existing item.
class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, this.existingItem, this.prefilledBarcode});

  final Item? existingItem;
  final String? prefilledBarcode;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  @override
  void initState() {
    super.initState();
    final vm = Get.put(ItemFormController(existingItem: widget.existingItem));
    if (widget.prefilledBarcode != null) vm.barcode = widget.prefilledBarcode!;
    vm.loadCategories();
  }

  @override
  void dispose() {
    Get.delete<ItemFormController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ItemFormController>(
      builder: (vm) => _ItemFormBody(vm: vm),
    );
  }
}

class _ItemFormBody extends StatefulWidget {
  const _ItemFormBody({required this.vm});

  final ItemFormController vm;

  @override
  State<_ItemFormBody> createState() => _ItemFormBodyState();
}

class _ItemFormBodyState extends State<_ItemFormBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _thresholdCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    final vm = widget.vm;
    _nameCtrl = TextEditingController(text: vm.name);
    _barcodeCtrl = TextEditingController(text: vm.barcode);
    _quantityCtrl = TextEditingController(text: vm.quantity == 0 ? '' : vm.quantity.toString());
    _priceCtrl = TextEditingController(text: vm.unitPrice == 0 ? '' : vm.unitPrice.toString());
    _thresholdCtrl = TextEditingController(text: vm.lowStockThreshold == 0 ? '' : vm.lowStockThreshold.toString());
    _unitCtrl = TextEditingController(text: vm.unit);
    _notesCtrl = TextEditingController(text: vm.notes);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _thresholdCtrl.dispose();
    _unitCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen(pickModeOnly: true)),
    );
    if (code != null) {
      _barcodeCtrl.text = code;
      widget.vm.setBarcode(code);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = widget.vm;
    vm.name = _nameCtrl.text;
    vm.barcode = _barcodeCtrl.text;
    vm.quantity = double.tryParse(_quantityCtrl.text) ?? 0;
    vm.unitPrice = double.tryParse(_priceCtrl.text) ?? 0;
    vm.lowStockThreshold = double.tryParse(_thresholdCtrl.text) ?? 0;
    vm.unit = _unitCtrl.text;
    vm.notes = _notesCtrl.text;

    final error = await vm.save();
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;

    return Scaffold(
      appBar: AppBar(title: Text(vm.isEditing ? 'Edit Item' : 'New Item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Item name *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _barcodeCtrl,
              decoration: InputDecoration(
                labelText: 'Barcode / SKU',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanBarcode,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!vm.categoriesLoaded)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<int?>(
                // Guarded on categoriesLoaded above: rendering this before
                // categories arrive could pass a value that doesn't match
                // any item yet, which DropdownButtonFormField disallows.
                value: vm.categories.any((c) => c.id == vm.categoryId) ? vm.categoryId : null,
                decoration: const InputDecoration(labelText: 'Category'),
                items: vm.categories
                    .map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: vm.setCategoryId,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityCtrl,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unitCtrl,
                    decoration: const InputDecoration(labelText: 'Unit (pcs, kg...)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(labelText: 'Unit price (₹)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _thresholdCtrl,
                    decoration: const InputDecoration(labelText: 'Low stock alert at'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: vm.isSaving ? null : _submit,
              child: vm.isSaving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(vm.isEditing ? 'Save changes' : 'Add item'),
            ),
          ],
        ),
      ),
    );
  }
}
