import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة التحكم'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: const [
              DashboardCard(
                title: 'مبيعات اليوم',
                value: '0.00',
                icon: Icons.point_of_sale,
              ),
              DashboardCard(
                title: 'المشتريات',
                value: '0.00',
                icon: Icons.shopping_cart,
              ),
              DashboardCard(
                title: 'الأرباح',
                value: '0.00',
                icon: Icons.trending_up,
              ),
              DashboardCard(
                title: 'عدد المنتجات',
                value: '0',
                icon: Icons.inventory_2,
              ),
              DashboardCard(
                title: 'العملاء',
                value: '0',
                icon: Icons.people,
              ),
              DashboardCard(
                title: 'الموردون',
                value: '0',
                icon: Icons.local_shipping,
              ),
              DashboardCard(
                title: 'المصروفات',
                value: '0.00',
                icon: Icons.money_off,
              ),
              DashboardCard(
                title: 'رصيد الصندوق',
                value: '0.00',
                icon: Icons.account_balance_wallet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}