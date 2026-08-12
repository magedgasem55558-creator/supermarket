
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';


class SalesPage extends ConsumerStatefulWidget {
  const SalesPage({super.key});

  @override
  ConsumerState<SalesPage> createState() => _SalesPageState();
}

class _CartItem {
  final Product product;
  double quantity;
  double discount;

  _CartItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0,
  });

  double get total {
    final value = (product.sellingPrice * quantity) - discount;
    return value < 0 ? 0 : value;
  }
}

class _SalesPageState extends ConsumerState<SalesPage> {
  final _barcodeController = TextEditingController();
  final _searchController = TextEditingController();
  final _customerSearchController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _paidController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  final _barcodeFocusNode = FocusNode();

  final List<_CartItem> _cart = [];

  bool _saving = false;

  String _paymentMethod = 'cash';

  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();

    _barcodeFocusNode.requestFocus();

    _paidController.addListener(_refresh);
    _discountController.addListener(_refresh);
    _customerSearchController.addListener(_refresh);
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _searchController.dispose();
    _customerSearchController.dispose();
    _discountController.dispose();
    _paidController.dispose();
    _notesController.dispose();
    _barcodeFocusNode.dispose();

    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  double get subtotal {
    return _cart.fold<double>(
      0,
      (sum, item) => sum + item.total,
    );
  }

  double get discount {
    final value = _parseDouble(_discountController.text);

    if (value < 0) {
      return 0;
    }

    return value;
  }

  double get total {
    final value = subtotal - discount;

    return value < 0 ? 0 : value;
  }

  double get paid {
    final value = _parseDouble(_paidController.text);

    if (value < 0) {
      return 0;
    }

    return value;
  }

  double get remaining {
    final value = total - paid;

    return value < 0 ? 0 : value;
  }

  double get change {
    final value = paid - total;

    return value < 0 ? 0 : value;
  }

  Future<List<Product>> _searchProducts(String query) {
    final repository = ref.read(productsRepositoryProvider);

    return repository.search(query);
  }

  Future<List<Customer>> _searchCustomers(String query) {
    final database = ref.read(databaseProvider);

    return database.customersDao.search(query.trim());
  }

  Future<void> _addByBarcode() async {
    final barcode = _barcodeController.text.trim();

    if (barcode.isEmpty) {
      return;
    }

    try {
      final repository = ref.read(productsRepositoryProvider);

      final product = await repository.getByBarcode(barcode);

      if (!mounted) return;

      if (product == null) {
        _showMessage('المنتج غير موجود');
        return;
      }

      if (!product.isActive) {
        _showMessage('هذا المنتج غير نشط');
        return;
      }

      _addProduct(product);

      _barcodeController.clear();
      _barcodeFocusNode.requestFocus();
    } catch (e) {
      if (!mounted) return;

      _showMessage('حدث خطأ: $e');
    }
  }

  void _addProduct(Product product) {
    final existingIndex = _cart.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      final item = _cart[existingIndex];

      if (item.quantity + 1 > product.stockQuantity) {
        _showMessage('الكمية المطلوبة أكبر من المخزون');
        return;
      }

      setState(() {
        item.quantity++;
      });

      return;
    }

    if (product.stockQuantity <= 0) {
      _showMessage('المنتج غير متوفر في المخزون');
      return;
    }

    setState(() {
      _cart.add(
        _CartItem(
          product: product,
        ),
      );
    });
  }

  void _increaseQuantity(int index) {
    final item = _cart[index];

    if (item.quantity + 1 > item.product.stockQuantity) {
      _showMessage('لا توجد كمية كافية في المخزون');
      return;
    }

    setState(() {
      item.quantity++;
    });
  }

  void _decreaseQuantity(int index) {
    final item = _cart[index];

    if (item.quantity <= 1) {
      setState(() {
        _cart.removeAt(index);
      });

      return;
    }

    setState(() {
      item.quantity--;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  void _selectCustomer(Customer customer) {
    if (!customer.isActive) {
      _showMessage('العميل غير نشط');

      setState(() {
        _selectedCustomer = null;
      });

      return;
    }

    setState(() {
      _selectedCustomer = customer;
      _customerSearchController.text = customer.name;
    });
  }

  void _clearCustomer() {
    setState(() {
      _selectedCustomer = null;
      _customerSearchController.clear();
    });
  }

  Future<void> _saveSale() async {
    if (_cart.isEmpty) {
      _showMessage('أضف منتجات إلى الفاتورة أولاً');
      return;
    }

    if (discount > subtotal) {
      _showMessage('الخصم أكبر من إجمالي الفاتورة');
      return;
    }

    if (paid > total) {
      _showMessage('المبلغ المدفوع أكبر من إجمالي الفاتورة');
      return;
    }

    // ==========================================================
    // التحقق من العميل عند البيع الآجل
    // ==========================================================

    if (_paymentMethod == 'credit') {
      if (_selectedCustomer == null) {
        _showMessage('يجب اختيار العميل عند البيع الآجل');
        return;
      }

      if (!_selectedCustomer!.isActive) {
        _showMessage('العميل غير نشط');
        return;
      }
    }

    setState(() {
      _saving = true;
    });

    try {
      final repository = ref.read(salesRepositoryProvider);

      final invoiceNumber = _generateInvoiceNumber();

      final items = _cart.map((item) {
        final itemTotal = item.total;

        return SaleItemsCompanion(
          saleId: const Value.absent(),
          productId: Value(item.product.id),
          productName: Value(item.product.name),
          barcode: Value(item.product.barcode),
          quantity: Value(item.quantity),
          unitPrice: Value(item.product.sellingPrice),
          discount: Value(item.discount),
          total: Value(itemTotal),
        );
      }).toList();

      final saleId = await repository.create(
        invoiceNumber: invoiceNumber,
        items: items,
        discount: discount,
        paid: paid,
        paymentMethod: _paymentMethod,

        // العميل يُرسل فقط عند البيع الآجل.
        customerId:
            _paymentMethod == 'credit'
                ? _selectedCustomer!.id
                : null,

        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      await _showSuccessDialog(
        invoiceNumber: invoiceNumber,
        saleId: saleId,
      );

      if (!mounted) return;

      _clearSale();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'تعذر حفظ الفاتورة:\n$e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();

    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    return 'INV-$year$month$day-$hour$minute$second';
  }

  void _clearSale() {
    setState(() {
      _cart.clear();

      _discountController.text = '0';
      _paidController.text = '0';
      _notesController.clear();

      _paymentMethod = 'cash';

      _selectedCustomer = null;
      _customerSearchController.clear();
    });

    _barcodeController.clear();
    _barcodeFocusNode.requestFocus();
  }

  Future<void> _showSuccessDialog({
    required String invoiceNumber,
    required int saleId,
  }) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(width: 10),
              Text('تم حفظ الفاتورة'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('رقم الفاتورة: $invoiceNumber'),
              const SizedBox(height: 8),
              Text('رقم العملية: $saleId'),
              const SizedBox(height: 8),
              Text(
                'الإجمالي: ${total.toStringAsFixed(2)}',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('موافق'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Widget _buildProductSearch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _barcodeController,
              focusNode: _barcodeFocusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addByBarcode(),
              decoration: InputDecoration(
                labelText: 'الباركود',
                hintText: 'امسح الباركود أو اكتبه',
                prefixIcon: const Icon(
                  Icons.qr_code_scanner,
                ),
                suffixIcon: IconButton(
                  onPressed: _addByBarcode,
                  icon: const Icon(Icons.add),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'بحث عن منتج',
                hintText: 'اكتب اسم المنتج أو الباركود',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProducts() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 60,
            ),
            SizedBox(height: 12),
            Text(
              'ابحث عن منتج لإضافته إلى الفاتورة',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<Product>>(
      future: _searchProducts(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'حدث خطأ: ${snapshot.error}',
            ),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(
            child: Text(
              'لم يتم العثور على المنتج',
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: products.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final product = products[index];

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    product.name.isNotEmpty
                        ? product.name[0]
                        : '?',
                  ),
                ),
                title: Text(product.name),
                subtitle: Text(
                  'الباركود: ${product.barcode}\n'
                  'المخزون: ${product.stockQuantity}',
                ),
                trailing: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.sellingPrice
                          .toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.add_shopping_cart,
                    ),
                  ],
                ),
                onTap: () {
                  _addProduct(product);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomerSelector() {
    if (_paymentMethod != 'credit') {
      return const SizedBox.shrink();
    }

    final query =
        _customerSearchController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _customerSearchController,
          decoration: InputDecoration(
            labelText: 'العميل',
            hintText: 'ابحث باسم العميل أو رقم الهاتف',
            prefixIcon: const Icon(Icons.person_search),
            suffixIcon: _selectedCustomer != null
                ? IconButton(
                    onPressed: _clearCustomer,
                    icon: const Icon(Icons.clear),
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) {
            setState(() {});
          },
        ),

        if (_selectedCustomer != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'العميل المحدد: ${_selectedCustomer!.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (query.isNotEmpty && _selectedCustomer == null)
          const SizedBox(height: 8),

        if (query.isNotEmpty && _selectedCustomer == null)
          FutureBuilder<List<Customer>>(
            future: _searchCustomers(query),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'حدث خطأ أثناء البحث عن العميل: '
                    '${snapshot.error}',
                  ),
                );
              }

              final customers =
                  snapshot.data ?? [];

              if (customers.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'لم يتم العثور على العميل',
                  ),
                );
              }

              return Card(
                margin: EdgeInsets.zero,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 220,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: customers.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final customer =
                          customers[index];

                      return ListTile(
                        leading: Icon(
                          customer.isActive
                              ? Icons.person
                              : Icons.person_off,
                          color: customer.isActive
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(customer.name),
                        subtitle: Text(
                          customer.phone ??
                              'بدون رقم هاتف',
                        ),
                        trailing: customer.isActive
                            ? const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              )
                            : const Text(
                                'غير نشط',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                        onTap: () {
                          _selectCustomer(customer);
                        },
                      );
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCart() {
    if (_cart.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 70,
            ),
            SizedBox(height: 12),
            Text(
              'السلة فارغة',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _cart.length,
      separatorBuilder: (_, __) =>
          const Divider(),
      itemBuilder: (context, index) {
        final item = _cart[index];

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            item.product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${item.product.sellingPrice.toStringAsFixed(2)} × '
            '${item.quantity.toStringAsFixed(0)}',
          ),
          leading: IconButton(
            tooltip: 'حذف',
            onPressed: () => _removeItem(index),
            icon: const Icon(Icons.delete_outline),
          ),
          trailing: SizedBox(
            width: 150,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () =>
                      _decreaseQuantity(index),
                  icon: const Icon(
                    Icons.remove_circle_outline,
                  ),
                ),
                Text(
                  item.quantity.toStringAsFixed(0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _increaseQuantity(index),
                  icon: const Icon(
                    Icons.add_circle_outline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryRow(
              'المجموع الفرعي',
              subtotal,
            ),
            const SizedBox(height: 8),
            _summaryRow(
              'الخصم',
              discount,
            ),
            const Divider(height: 24),
            _summaryRow(
              'الإجمالي',
              total,
              bold: true,
              large: true,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _discountController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9.]'),
                ),
              ],
              decoration: const InputDecoration(
                labelText: 'الخصم',
                prefixIcon: Icon(Icons.discount),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _paidController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9.]'),
                ),
              ],
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع',
                prefixIcon: Icon(Icons.payments),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'طريقة الدفع',
                prefixIcon: Icon(Icons.payment),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'cash',
                  child: Text('نقداً'),
                ),
                DropdownMenuItem(
                  value: 'credit',
                  child: Text('آجل'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _paymentMethod = value;

                  if (value == 'cash') {
                    _selectedCustomer = null;
                    _customerSearchController.clear();
                  }
                });
              },
            ),

            if (_paymentMethod == 'credit') ...[
              const SizedBox(height: 12),
              _buildCustomerSelector(),
            ],

            const SizedBox(height: 12),

            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            if (remaining > 0)
              _summaryRow(
                'المتبقي',
                remaining,
              ),

            if (change > 0)
              _summaryRow(
                'الباقي للعميل',
                change,
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed:
                    _saving ? null : _saveSale,
                icon: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.point_of_sale,
                      ),
                label: Text(
                  _saving
                      ? 'جاري حفظ الفاتورة...'
                      : 'إتمام البيع',
                ),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    _saving ? null : _clearSale,
                icon: const Icon(Icons.clear),
                label: const Text('إلغاء الفاتورة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String title,
    double value, {
    bool bold = false,
    bool large = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: large ? 19 : 15,
            fontWeight:
                bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontSize: large ? 22 : 15,
            fontWeight:
                bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع'),
        actions: [
          IconButton(
            tooltip: 'فاتورة جديدة',
            onPressed: _saving ? null : _clearSale,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _buildProductSearch(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Card(
                      clipBehavior:
                          Clip.antiAlias,
                      child: _buildProducts(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              flex: 6,
              child: Column(
                children: [
                  Expanded(
                    child: Card(
                      clipBehavior:
                          Clip.antiAlias,
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.all(16),
                            child: const Text(
                              'تفاصيل الفاتورة',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: _buildCart(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildSummary(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
