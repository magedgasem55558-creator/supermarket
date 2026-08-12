import 'package:flutter/material.dart';

import '../../categories/presentation/categories_page.dart';
import '../../products/presentation/products_page.dart';
import '../../sales/pages/sales_page.dart';
import '../../customers/pages/customers_debts_page.dart';
import '../../inventory/pages/inventory_management_page.dart';

import 'dashboard_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // ============================================================
  // صفحات التطبيق
  // ============================================================

  final List<Widget> _pages = const [
    // 0
    DashboardPage(),

    // 1
    SalesPage(),

    // 2
    ProductsPage(),

    // 3
    InventoryManagementPage(),

    // 4
    PlaceholderPage(
      title: 'المبيعات',
    ),

    // 5
    PlaceholderPage(
      title: 'المشتريات',
    ),

    // 6
    CustomersDebtsPage(),

    // 7
    PlaceholderPage(
      title: 'الموردون',
    ),

    // 8
    PlaceholderPage(
      title: 'المصروفات',
    ),

    // 9
    PlaceholderPage(
      title: 'الصندوق',
    ),

    // 10
    PlaceholderPage(
      title: 'التقارير',
    ),

    // 11
    PlaceholderPage(
      title: 'المستخدمون',
    ),

    // 12
    PlaceholderPage(
      title: 'الإعدادات',
    ),
  ];

  // ============================================================
  // القائمة الجانبية
  // ============================================================

  final List<NavigationRailDestination> _destinations = const [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('الرئيسية'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.point_of_sale_outlined),
      selectedIcon: Icon(Icons.point_of_sale),
      label: Text('نقطة البيع'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: Text('المنتجات'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.warehouse_outlined),
      selectedIcon: Icon(Icons.warehouse),
      label: Text('المخزون'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: Text('المبيعات'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.shopping_cart_outlined),
      selectedIcon: Icon(Icons.shopping_cart),
      label: Text('المشتريات'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: Text('العملاء'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.local_shipping_outlined),
      selectedIcon: Icon(Icons.local_shipping),
      label: Text('الموردون'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.money_off_outlined),
      selectedIcon: Icon(Icons.money_off),
      label: Text('المصروفات'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: Text('الصندوق'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart),
      label: Text('التقارير'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.manage_accounts_outlined),
      selectedIcon: Icon(Icons.manage_accounts),
      label: Text('المستخدمون'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('الإعدادات'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,

              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },

              labelType: NavigationRailLabelType.all,

              destinations: _destinations,
            ),

            const VerticalDivider(
              width: 1,
            ),

            Expanded(
              child: _pages[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// صفحة مؤقتة للأقسام التي لم يتم إنشاؤها بعد
// ============================================================

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
