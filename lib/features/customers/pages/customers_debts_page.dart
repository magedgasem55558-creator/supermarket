import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../database/app_database.dart';
import '../../../database/daos/customer_transactions_dao.dart';
import '../../../database/daos/customers_dao.dart';
import '../../../providers/database_providers.dart';

class CustomersDebtsPage extends ConsumerStatefulWidget {
  const CustomersDebtsPage({
    super.key,
  });

  @override
  ConsumerState<CustomersDebtsPage> createState() =>
      _CustomersDebtsPageState();
}

class _CustomersDebtsPageState
    extends ConsumerState<CustomersDebtsPage> {
  String _search = '';

  Future<void> _refresh() async {
    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // إضافة عميل
  // ============================================================

  Future<void> _showAddCustomerDialog(
    CustomersDao customersDao,
  ) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveCustomer() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              try {
                await customersDao.insertCustomer(
                  CustomersCompanion.insert(
                    name: nameController.text.trim(),
                    phone: Value(
                      phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                    ),
                    address: Value(
                      addressController.text.trim().isEmpty
                          ? null
                          : addressController.text.trim(),
                    ),
                  ),
                );

                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext).pop(true);
              } catch (e) {
                setDialogState(() {
                  isSaving = false;
                });

                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'حدث خطأ أثناء إضافة العميل: $e',
                    ),
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.person_add),
                  SizedBox(width: 10),
                  Text('إضافة عميل جديد'),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'اسم العميل',
                            hintText: 'أدخل اسم العميل',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'يرجى إدخال اسم العميل';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم الهاتف',
                            hintText: 'اختياري',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'العنوان',
                            hintText: 'اختياري',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(false);
                        },
                  child: const Text('إلغاء'),
                ),
                FilledButton.icon(
                  onPressed: isSaving ? null : saveCustomer,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    isSaving ? 'جاري الحفظ...' : 'حفظ العميل',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();

    if (result == true && mounted) {
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت إضافة العميل بنجاح'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersDao = ref.watch(
      customersDaoProvider,
    );

    final transactionsDao = ref.watch(
      customerTransactionsDaoProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة العملاء والمدينين',
        ),
        actions: [
          // زر إضافة عميل
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: FilledButton.icon(
              onPressed: () =>
                  _showAddCustomerDialog(customersDao),
              icon: const Icon(Icons.person_add),
              label: const Text('إضافة عميل'),
            ),
          ),

          IconButton(
            tooltip: 'تحديث',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: FutureBuilder<List<Customer>>(
        future: customersDao.getAll(),
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

          final customers = snapshot.data ?? [];

          return _buildPage(
            customers,
            transactionsDao,
          );
        },
      ),
    );
  }

  Widget _buildPage(
    List<Customer> customers,
    CustomerTransactionsDao transactionsDao,
  ) {
    final filtered = customers.where((customer) {
      final query = _search.trim().toLowerCase();

      if (query.isEmpty) {
        return true;
      }

      return customer.name
              .toLowerCase()
              .contains(query) ||
          (customer.phone ?? '')
              .toLowerCase()
              .contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _search = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'ابحث باسم العميل أو الهاتف...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      tooltip: 'مسح البحث',
                      onPressed: () {
                        setState(() {
                          _search = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: FutureBuilder<Map<int, double>>(
              future:
                  transactionsDao.getAllCustomerDebts(),
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

                final debts = snapshot.data ?? {};

                return _buildTable(
                  filtered,
                  debts,
                  transactionsDao,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
    List<Customer> customers,
    Map<int, double> debts,
    CustomerTransactionsDao dao,
  ) {
    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline,
              size: 70,
            ),
            const SizedBox(height: 12),
            const Text(
              'لا يوجد عملاء',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                final customersDao = ref.read(
                  customersDaoProvider,
                );

                _showAddCustomerDialog(
                  customersDao,
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('إضافة أول عميل'),
            ),
          ],
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 35,
            headingRowHeight: 55,
            dataRowMinHeight: 60,
            dataRowMaxHeight: 70,
            columns: const [
              DataColumn(
                label: Text('الرقم'),
              ),
              DataColumn(
                label: Text('العميل'),
              ),
              DataColumn(
                label: Text('الهاتف'),
              ),
              DataColumn(
                label: Text('العنوان'),
              ),
              DataColumn(
                label: Text('الدين'),
              ),
              DataColumn(
                label: Text('الإجراءات'),
              ),
            ],
            rows: customers.map((customer) {
              final debt = debts[customer.id] ?? 0;

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      customer.id.toString(),
                    ),
                  ),

                  DataCell(
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  DataCell(
                    Text(
                      customer.phone ?? '—',
                    ),
                  ),

                  DataCell(
                    Text(
                      customer.address ?? '—',
                    ),
                  ),

                  DataCell(
                    Text(
                      debt > 0
                          ? _formatMoney(debt)
                          : 'لا يوجد دين',
                      style: TextStyle(
                        color: debt > 0
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'سجل الحركات',
                          onPressed: () =>
                              _showTransactions(
                            customer,
                            dao,
                          ),
                          icon: const Icon(
                            Icons.history,
                          ),
                        ),

                        if (debt > 0)
                          FilledButton.icon(
                            onPressed: () =>
                                _showPaymentDialog(
                              customer,
                              debt,
                              dao,
                            ),
                            icon: const Icon(
                              Icons.payments,
                            ),
                            label: const Text(
                              'سداد',
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

  // ============================================================
  // سداد الدين
  // ============================================================

  Future<void> _showPaymentDialog(
    Customer customer,
    double debt,
    CustomerTransactionsDao dao,
  ) async {
    final controller = TextEditingController();

    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'سداد دين ${customer.name}',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              labelText: 'المبلغ',
              hintText:
                  'الدين الحالي: ${_formatMoney(debt)}',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(
                  controller.text.trim(),
                );

                if (amount == null || amount <= 0) {
                  return;
                }

                if (amount > debt) {
                  return;
                }

                Navigator.pop(
                  context,
                  amount,
                );
              },
              child: const Text('سداد'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null) {
      return;
    }

    try {
      await dao.insertTransaction(
        CustomerTransactionsCompanion.insert(
          customerId: customer.id,
          type: 'payment',
          amount: Value(result),
        ),
      );

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم تسجيل السداد بنجاح',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // سجل حركات العميل
  // ============================================================

  Future<void> _showTransactions(
    Customer customer,
    CustomerTransactionsDao dao,
  ) async {
    final transactions =
        await dao.getByCustomerId(
      customer.id,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'سجل ${customer.name}',
          ),
          content: SizedBox(
            width: 600,
            height: 450,
            child: transactions.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد حركات',
                    ),
                  )
                : ListView.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(),
                    itemBuilder: (context, index) {
                      final item =
                          transactions[index];

                      final isSale =
                          item.type == 'credit_sale';

                      final isPayment =
                          item.type == 'payment';

                      String title;

                      if (isSale) {
                        title = 'بيع آجل';
                      } else if (isPayment) {
                        title = 'سداد';
                      } else {
                        title = 'مرتجع بيع';
                      }

                      return ListTile(
                        leading: Icon(
                          isPayment
                              ? Icons.payments
                              : Icons.receipt_long,
                          color: isPayment
                              ? Colors.green
                              : Colors.red,
                        ),
                        title: Text(title),
                        subtitle: Text(
                          _formatDate(
                            item.createdAt,
                          ),
                        ),
                        trailing: Text(
                          _formatMoney(
                            item.amount,
                          ),
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // تنسيق المبلغ
  // ============================================================

  String _formatMoney(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()}';
    }

    return value.toStringAsFixed(2);
  }

  // ============================================================
  // تنسيق التاريخ
  // ============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
