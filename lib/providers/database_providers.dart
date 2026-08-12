
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/daos/customers_dao.dart';
import '../database/daos/customer_transactions_dao.dart';
import '../database/daos/stock_movements_dao.dart';

import '../services/sale_service.dart';
import '../database/daos/categories_dao.dart';
import '../database/daos/products_dao.dart';
import '../database/daos/roles_dao.dart';
import '../database/daos/permissions_dao.dart';
import '../database/daos/role_permissions_dao.dart';
import '../database/daos/users_dao.dart';
import '../database/daos/sales_dao.dart';
import '../database/daos/sale_items_dao.dart';
import '../database/daos/invoice_settings_dao.dart';
import '../repositories/invoice_settings_repository.dart';
import '../repositories/categories_repository.dart';
import '../repositories/products_repository.dart';
import '../repositories/sales_repository.dart';
import '../repositories/sale_items_repository.dart';


// ============================================================
// DATABASE
// ============================================================

/// قاعدة البيانات الرئيسية للتطبيق.
///
/// يتم إنشاء Instance واحدة من AppDatabase
/// لكل ProviderContainer.
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();

  ref.onDispose(() {
    database.close();
  });

  return database;
});


// ============================================================
// DAOs
// ============================================================
// ============================================================
// CUSTOMERS DAO
// ============================================================

final customersDaoProvider = Provider<CustomersDao>((ref) {
  final database = ref.watch(databaseProvider);

  return CustomersDao(database);
});


// ============================================================
// CUSTOMER TRANSACTIONS DAO
// ============================================================

final customerTransactionsDaoProvider =
    Provider<CustomerTransactionsDao>((ref) {
  final database = ref.watch(databaseProvider);

  return CustomerTransactionsDao(database);
});


// ============================================================
// STOCK MOVEMENTS DAO
// ============================================================

final stockMovementsDaoProvider =
    Provider<StockMovementsDao>((ref) {
  final database = ref.watch(databaseProvider);

  return StockMovementsDao(database);
});
final categoriesDaoProvider = Provider<CategoriesDao>((ref) {
  final database = ref.watch(databaseProvider);

  return CategoriesDao(database);
});


final productsDaoProvider = Provider<ProductsDao>((ref) {
  final database = ref.watch(databaseProvider);

  return ProductsDao(database);
});


final rolesDaoProvider = Provider<RolesDao>((ref) {
  final database = ref.watch(databaseProvider);

  return RolesDao(database);
});

final invoiceSettingsDaoProvider =
    Provider<InvoiceSettingsDao>((ref) {
  return InvoiceSettingsDao(
    ref.watch(databaseProvider),
  );
});

final invoiceSettingsRepositoryProvider =
    Provider<InvoiceSettingsRepository>((ref) {
  return InvoiceSettingsRepository(
    ref.watch(invoiceSettingsDaoProvider),
  );
});
final permissionsDaoProvider = Provider<PermissionsDao>((ref) {
  final database = ref.watch(databaseProvider);

  return PermissionsDao(database);
});


final rolePermissionsDaoProvider =
    Provider<RolePermissionsDao>((ref) {
  final database = ref.watch(databaseProvider);

  return RolePermissionsDao(database);
});


final usersDaoProvider = Provider<UsersDao>((ref) {
  final database = ref.watch(databaseProvider);

  return UsersDao(database);
});


final salesDaoProvider = Provider<SalesDao>((ref) {
  final database = ref.watch(databaseProvider);

  return SalesDao(database);
});


final saleItemsDaoProvider = Provider<SaleItemsDao>((ref) {
  final database = ref.watch(databaseProvider);

  return SaleItemsDao(database);
});


// ============================================================
// REPOSITORIES
// ============================================================

// ============================================================
// REPOSITORIES
// ============================================================

final categoriesRepositoryProvider =
    Provider<CategoriesRepository>((ref) {
  final dao = ref.watch(categoriesDaoProvider);

  return CategoriesRepository(dao);
});


final productsRepositoryProvider =
    Provider<ProductsRepository>((ref) {
  final dao = ref.watch(productsDaoProvider);

  return ProductsRepository(dao);
});


// ============================================================
// SALES REPOSITORY
// ============================================================

final salesRepositoryProvider =
    Provider<SalesRepository>((ref) {
  final database = ref.watch(databaseProvider);
  final salesDao = ref.watch(salesDaoProvider);
  final saleItemsDao = ref.watch(saleItemsDaoProvider);
  final productsDao = ref.watch(productsDaoProvider);

  return SalesRepository(
    database,
    salesDao,
    saleItemsDao,
    productsDao,
  );
});


final saleItemsRepositoryProvider =
    Provider<SaleItemsRepository>((ref) {
  final dao = ref.watch(saleItemsDaoProvider);

  return SaleItemsRepository(dao);
});


// ============================================================
// SALE SERVICE
// ============================================================

final saleServiceProvider =
    Provider<SaleService>((ref) {
  final database = ref.watch(databaseProvider);

  return SaleService(database);
});
