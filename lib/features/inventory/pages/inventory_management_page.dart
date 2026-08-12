import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../products/products_provider.dart';

class InventoryManagementPage
    extends ConsumerStatefulWidget {
  const InventoryManagementPage({
    super.key,
  });

  @override
  ConsumerState<InventoryManagementPage>
      createState() =>
          _InventoryManagementPageState();
}

class _InventoryManagementPageState
    extends ConsumerState<
        InventoryManagementPage> {
  int _filter = 0;

  Future<void> _refresh() async {
    if (!mounted) return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final repository =
        ref.watch(productsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المخزون'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: repository.getAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ: ${snapshot.error}',
              ),
            );
          }

          final products =
              snapshot.data ?? [];

          return _buildContent(products);
        },
      ),
    );
  }

  Widget _buildContent(
    List<Product> products,
  ) {
    final lowStock = products
        .where(
          (p) =>
              p.stockQuantity <=
              p.minimumStock,
        )
        .toList();

    final expired = products
        .where(
          (p) => _isExpired(p.expiryDate),
        )
        .toList();

    final expiringSoon = products
        .where(
          (p) => _isExpiringSoon(
            p.expiryDate,
          ),
        )
        .toList();

    final visible = switch (_filter) {
      1 => lowStock,
      2 => expiringSoon,
      3 => expired,
      _ => products,
    };

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSummary(
            products.length,
            lowStock.length,
            expiringSoon.length,
            expired.length,
          ),

          const SizedBox(height: 20),

          _buildFilters(),

          const SizedBox(height: 16),

          Expanded(
            child: visible.isEmpty
                ? _buildEmpty()
                : _buildTable(visible),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(
    int total,
    int lowStock,
    int expiring,
    int expired,
  ) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      physics:
          const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          title: 'إجمالي المنتجات',
          value: '$total',
          icon: Icons.inventory_2,
        ),
        _SummaryCard(
          title: 'مخزون منخفض',
          value: '$lowStock',
          icon: Icons.warning_amber,
          color: Colors.orange,
        ),
        _SummaryCard(
          title: 'قرب الانتهاء',
          value: '$expiring',
          icon: Icons.event,
          color: Colors.amber,
        ),
        _SummaryCard(
          title: 'منتهي الصلاحية',
          value: '$expired',
          icon: Icons.dangerous,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('الكل'),
            selected: _filter == 0,
            onSelected: (_) {
              setState(() {
                _filter = 0;
              });
            },
          ),
          ChoiceChip(
            label:
                const Text('مخزون منخفض'),
            selected: _filter == 1,
            onSelected: (_) {
              setState(() {
                _filter = 1;
              });
            },
          ),
          ChoiceChip(
            label:
                const Text('قرب الانتهاء'),
            selected: _filter == 2,
            onSelected: (_) {
              setState(() {
                _filter = 2;
              });
            },
          ),
          ChoiceChip(
            label: const Text('منتهي'),
            selected: _filter == 3,
            onSelected: (_) {
              setState(() {
                _filter = 3;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
    List<Product> products,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(
                label: Text('المنتج'),
              ),
              DataColumn(
                label: Text('الباركود'),
              ),
              DataColumn(
                label: Text('المخزون'),
              ),
              DataColumn(
                label: Text('الحد الأدنى'),
              ),
              DataColumn(
                label: Text('الصلاحية'),
              ),
              DataColumn(
                label: Text('الحالة'),
              ),
            ],
            rows: products.map((product) {
              final lowStock =
                  product.stockQuantity <=
                      product.minimumStock;

              final expired =
                  _isExpired(
                product.expiryDate,
              );

              final expiring =
                  _isExpiringSoon(
                product.expiryDate,
              );

              return DataRow(
                cells: [
                  DataCell(
                    Text(product.name),
                  ),
                  DataCell(
                    Text(product.barcode),
                  ),
                  DataCell(
                    Text(
                      '${_format(product.stockQuantity)} ${product.unit}',
                    ),
                  ),
                  DataCell(
                    Text(
                      _format(
                        product.minimumStock,
                      ),
                    ),
                  ),
                  DataCell(
                    _expiryWidget(
                      product.expiryDate,
                    ),
                  ),
                  DataCell(
                    Wrap(
                      spacing: 5,
                      children: [
                        if (lowStock)
                          const Chip(
                            label:
                                Text('مخزون منخفض'),
                            avatar: Icon(
                              Icons.warning,
                              size: 16,
                            ),
                          ),
                        if (expired)
                          const Chip(
                            label:
                                Text('منتهي'),
                            avatar: Icon(
                              Icons.dangerous,
                              size: 16,
                            ),
                          )
                        else if (expiring)
                          const Chip(
                            label:
                                Text('قرب الانتهاء'),
                            avatar: Icon(
                              Icons.event,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _expiryWidget(DateTime? date) {
    if (date == null) {
      return const Text('بدون تاريخ');
    }

    final expired = _isExpired(date);
    final soon = _isExpiringSoon(date);

    final text =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    if (expired) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (soon) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Text(text);
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'لا توجد منتجات في هذا القسم',
        style: TextStyle(
          fontSize: 18,
        ),
      ),
    );
  }

  bool _isExpired(DateTime? date) {
    if (date == null) return false;

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    return date.isBefore(today);
  }

  bool _isExpiringSoon(DateTime? date) {
    if (date == null) return false;

    final today = DateTime.now();

    final end = today.add(
      const Duration(days: 30),
    );

    return !date.isBefore(today) &&
        !date.isAfter(end);
  }

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ??
        Theme.of(context)
            .colorScheme
            .primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  effectiveColor.withValues(
                alpha: 0.12,
              ),
              child: Icon(
                icon,
                color: effectiveColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}