import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/scanner_viewmodel.dart';
import '../items/item_detail_screen.dart';
import '../items/item_form_screen.dart';

/// Camera-based barcode scanner (uses the phone's camera via mobile_scanner
/// - no dedicated Bluetooth/Zebra scanner hardware required).
///
/// Two modes:
/// - Normal (bottom-nav tab): scans, looks the code up against the local
///   DB, and offers to open the matching item or create a new one.
/// - [pickModeOnly]: just pops the scanned string back to the caller (used
///   by the item form's "scan barcode" field button).
class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key, this.pickModeOnly = false});

  final bool pickModeOnly;

  @override
  Widget build(BuildContext context) {
    if (pickModeOnly) {
      return _ScannerView(
        onDetect: (code) => Navigator.of(context).pop(code),
      );
    }
    return ChangeNotifierProvider(
      create: (_) => ScannerViewModel(),
      child: const _LookupScannerBody(),
    );
  }
}

class _LookupScannerBody extends StatelessWidget {
  const _LookupScannerBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScannerViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Column(
        children: [
          Expanded(
            child: _ScannerView(
              onDetect: (code) => context.read<ScannerViewModel>().onCodeScanned(code),
            ),
          ),
          if (vm.result != ScanLookupResult.idle)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: vm.result == ScanLookupResult.found
                  ? _FoundBanner(vm: vm)
                  : _NotFoundBanner(vm: vm),
            ),
        ],
      ),
    );
  }
}

class _FoundBanner extends StatelessWidget {
  const _FoundBanner({required this.vm});
  final ScannerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final item = vm.foundItem!;
    return Row(
      children: [
        Expanded(
          child: Text('Found: ${item.name}\nQty: ${item.quantity} ${item.unit ?? ''}'.trim()),
        ),
        FilledButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id!)),
            );
            vm.reset();
          },
          child: const Text('Open'),
        ),
      ],
    );
  }
}

class _NotFoundBanner extends StatelessWidget {
  const _NotFoundBanner({required this.vm});
  final ScannerViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('No item with barcode "${vm.lastScannedCode}"')),
        FilledButton(
          onPressed: () async {
            final code = vm.lastScannedCode;
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ItemFormScreen(prefilledBarcode: code)),
            );
            vm.reset();
          },
          child: const Text('Add new'),
        ),
      ],
    );
  }
}

class _ScannerView extends StatefulWidget {
  const _ScannerView({required this.onDetect});
  final void Function(String code) onDetect;

  @override
  State<_ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<_ScannerView> {
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isEmpty) return;
            final value = barcodes.first.rawValue;
            if (value != null && value.isNotEmpty) {
              widget.onDetect(value);
            }
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: null,
            mini: true,
            onPressed: () => _controller.toggleTorch(),
            child: const Icon(Icons.flash_on),
          ),
        ),
      ],
    );
  }
}
