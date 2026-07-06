import 'package:flutter/material.dart';

import '../../viewmodels/dashboard_viewmodel.dart';
import '../categories/category_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../items/item_list_screen.dart';
import '../scanner/barcode_scanner_screen.dart';

/// Root navigation shell: bottom tab bar switching between the four main
/// sections of the app.
///
/// IndexedStack keeps all four tabs mounted (so e.g. Items' search text
/// survives switching tabs), which also means DashboardScreen's own
/// `initState`/ViewModel-create only runs once, ever - it would otherwise
/// never pick up items/categories/stock changes made from other tabs. To
/// fix that, the Dashboard's ViewModel is created and owned here instead of
/// inside DashboardScreen, and gets refreshed every time the Dashboard tab
/// is (re)selected.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final DashboardViewModel _dashboardViewModel;

  @override
  void initState() {
    super.initState();
    _dashboardViewModel = DashboardViewModel()..load();
  }

  @override
  void dispose() {
    _dashboardViewModel.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (index == 0) {
      // Refresh dashboard stats/activity every time it becomes the active
      // tab, since data may have changed while the user was on another tab.
      _dashboardViewModel.load();
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(viewModel: _dashboardViewModel),
      const ItemListScreen(),
      const BarcodeScannerScreen(),
      const CategoryListScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Items'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: 'Categories'),
        ],
      ),
    );
  }
}
