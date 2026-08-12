
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/roles_table.dart';
import 'tables/permissions_table.dart';
import 'tables/role_permissions_table.dart';
import 'tables/users_table.dart';

import 'daos/permissions_dao.dart';
import 'daos/roles_dao.dart';
import 'daos/users_dao.dart';
import 'daos/role_permissions_dao.dart';

import 'tables/categories_table.dart';
import 'daos/categories_dao.dart';

import 'tables/products_table.dart';
import 'daos/products_dao.dart';

import 'tables/sales_table.dart';
import 'tables/sale_items_table.dart';
import 'daos/sales_dao.dart';
import 'daos/sale_items_dao.dart';

import 'tables/invoice_settings_table.dart';

import 'tables/customers_table.dart';
import 'tables/customer_transactions_table.dart';
import 'daos/customers_dao.dart';
import 'daos/customer_transactions_dao.dart';

import 'tables/stock_movements_table.dart';
import 'daos/stock_movements_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    // ============================================================
    // المستخدمون والصلاحيات
    // ============================================================

    Roles,
    Permissions,
    RolePermissions,
    Users,

    // ============================================================
    // المخزون والمنتجات
    // ============================================================

    Categories,
    Products,
    StockMovements,

    // ============================================================
    // المبيعات
    // ============================================================

    Sales,
    SaleItems,

    // ============================================================
    // إعدادات الفاتورة
    // ============================================================

    InvoiceSettings,

    // ============================================================
    // العملاء
    // ============================================================

    Customers,
    CustomerTransactions,
  ],
  daos: [
    // ============================================================
    // المستخدمون والصلاحيات
    // ============================================================

    RolesDao,
    PermissionsDao,
    UsersDao,
    RolePermissionsDao,

    // ============================================================
    // المنتجات والمخزون
    // ============================================================

    CategoriesDao,
    ProductsDao,
    StockMovementsDao,

    // ============================================================
    // العملاء
    // ============================================================

    CustomersDao,
    CustomerTransactionsDao,

    // ============================================================
    // المبيعات
    // ============================================================

    SalesDao,
    SaleItemsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // ============================================================
  // إصدار قاعدة البيانات
  // ============================================================

  @override
  int get schemaVersion => 3;

  // ============================================================
  // Migration
  // ============================================================

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      // ==========================================================
      // إنشاء قاعدة البيانات لأول مرة
      // ==========================================================

      onCreate: (Migrator m) async {
        await m.createAll();
      },

      // ==========================================================
      // ترقية قاعدة البيانات
      // ==========================================================

      onUpgrade: (Migrator m, int from, int to) async {
        // ========================================================
        // الإصدار 1 -> الإصدار 2
        // ========================================================

        if (from < 2) {
          // ------------------------------------------------------
          // إنشاء جدول العملاء
          // ------------------------------------------------------

          await m.createTable(customers);

          // ------------------------------------------------------
          // إنشاء جدول حركات العملاء
          // ------------------------------------------------------

          await m.createTable(customerTransactions);

          // ------------------------------------------------------
          // إضافة customerId إلى جدول المبيعات
          // ------------------------------------------------------

          await m.addColumn(
            sales,
            sales.customerId,
          );
        }

        // ========================================================
        // الإصدار 2 -> الإصدار 3
        // إضافة تاريخ انتهاء الصلاحية للمنتجات
        // ========================================================

        if (from < 3) {
          await m.addColumn(
            products,
            products.expiryDate,
          );
        }
      },
    );
  }
}

// ==================================================================
// فتح قاعدة البيانات
// ==================================================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // --------------------------------------------------------------
    // الحصول على مجلد بيانات التطبيق
    // --------------------------------------------------------------

    final directory =
        await getApplicationSupportDirectory();

    // --------------------------------------------------------------
    // التأكد من وجود المجلد
    // --------------------------------------------------------------

    final dbDirectory =
        Directory(directory.path);

    if (!await dbDirectory.exists()) {
      await dbDirectory.create(
        recursive: true,
      );
    }

    // --------------------------------------------------------------
    // مسار قاعدة البيانات
    // --------------------------------------------------------------

    final file = File(
      p.join(
        directory.path,
        'supermarket.db',
      ),
    );

    // --------------------------------------------------------------
    // SQLite
    // --------------------------------------------------------------

    return NativeDatabase.createInBackground(
      file,
    );
  });
}
