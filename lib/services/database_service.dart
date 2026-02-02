import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/models.dart';
import 'web_storage_service.dart'
    if (dart.library.html) 'web_storage_service.dart';

/// خدمة قاعدة البيانات - Database Service
/// استخدمت SQLite لأنها:
/// 1. موثوقة ومستقرة للبيانات المهيكلة
/// 2. تدعم الاستعلامات المعقدة (البحث، التصفية)
/// 3. تضمن سلامة البيانات مع المعاملات
/// 4. أداء ممتاز للتطبيقات المحلية
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static bool _webDataLoaded = false;

  // تخزين مؤقت للويب (في الذاكرة)
  static List<Customer> _webCustomers = [];
  static List<Invoice> _webInvoices = [];
  static AppSettings _webSettings = AppSettings();
  static int _webCustomerId = 1;
  static int _webInvoiceId = 1;

  /// تهيئة التخزين للويب
  Future<void> _initWebStorage() async {
    if (!kIsWeb) return;

    try {
      if (_webDataLoaded) return;

      // طباعة جميع المفاتيح المحفوظة
      final keys = WebStorageService.getKeys();
      debugPrint('المفاتيح المحفوظة في localStorage: $keys');

      // تحميل العملاء
      final customersJson = WebStorageService.getString(
        'electricity_customers',
      );
      debugPrint('محتوى العملاء الخام: $customersJson');

      if (customersJson != null &&
          customersJson.isNotEmpty &&
          customersJson != 'null') {
        try {
          final List<dynamic> customersList = jsonDecode(customersJson);
          debugPrint('قائمة العملاء المُستخرجة: ${customersList.length} عناصر');

          _webCustomers = customersList
              .map((e) => Customer.fromMap(Map<String, dynamic>.from(e)))
              .toList();

          if (_webCustomers.isNotEmpty) {
            _webCustomerId =
                _webCustomers
                    .map((c) => c.id ?? 0)
                    .reduce((a, b) => a > b ? a : b) +
                1;
          }
          debugPrint('✅ تم تحميل ${_webCustomers.length} عملاء بنجاح');
        } catch (e) {
          debugPrint('❌ خطأ في تحليل بيانات العملاء: $e');
          _webCustomers = [];
        }
      } else {
        debugPrint('⚠️ لا توجد بيانات عملاء محفوظة');
        _webCustomers = [];
      }

      // تحميل الفواتير
      final invoicesJson = WebStorageService.getString('electricity_invoices');
      if (invoicesJson != null &&
          invoicesJson.isNotEmpty &&
          invoicesJson != 'null') {
        try {
          final List<dynamic> invoicesList = jsonDecode(invoicesJson);
          _webInvoices = invoicesList
              .map((e) => Invoice.fromMap(Map<String, dynamic>.from(e)))
              .toList();
          if (_webInvoices.isNotEmpty) {
            _webInvoiceId =
                _webInvoices
                    .map((i) => i.id ?? 0)
                    .reduce((a, b) => a > b ? a : b) +
                1;
          }
        } catch (e) {
          debugPrint('❌ خطأ في تحليل بيانات الفواتير: $e');
          _webInvoices = [];
        }
      } else {
        _webInvoices = [];
      }

      // تحميل الإعدادات
      final settingsJson = WebStorageService.getString('electricity_settings');
      if (settingsJson != null &&
          settingsJson.isNotEmpty &&
          settingsJson != 'null') {
        try {
          _webSettings = AppSettings.fromMap(
            Map<String, dynamic>.from(jsonDecode(settingsJson)),
          );
        } catch (e) {
          debugPrint('❌ خطأ في تحليل الإعدادات: $e');
          _webSettings = AppSettings();
        }
      } else {
        _webSettings = AppSettings();
      }

      _webDataLoaded = true;
      debugPrint(
        '=== ✅ تم تحميل البيانات: ${_webCustomers.length} عملاء, ${_webInvoices.length} فواتير ===',
      );
    } catch (e) {
      debugPrint('❌ خطأ عام في تهيئة التخزين: $e');
      _webCustomers = [];
      _webInvoices = [];
      _webSettings = AppSettings();
      _webDataLoaded = true;
    }
  }

  /// حفظ العملاء للويب
  Future<void> _saveWebCustomers() async {
    if (!kIsWeb) return;
    try {
      final json = jsonEncode(_webCustomers.map((c) => c.toMap()).toList());
      debugPrint('💾 حفظ العملاء - JSON: $json');

      WebStorageService.setString('electricity_customers', json);

      // التحقق من الحفظ
      final saved = WebStorageService.getString('electricity_customers');
      debugPrint(
        '✅ تم حفظ ${_webCustomers.length} عملاء - طول البيانات: ${saved?.length ?? 0} حرف',
      );
    } catch (e) {
      debugPrint('❌ خطأ في حفظ العملاء: $e');
    }
  }

  /// حفظ الفواتير للويب
  Future<void> _saveWebInvoices() async {
    if (!kIsWeb) return;
    try {
      final json = jsonEncode(_webInvoices.map((i) => i.toMap()).toList());
      WebStorageService.setString('electricity_invoices', json);
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الفواتير: $e');
    }
  }

  /// حفظ الإعدادات للويب
  Future<void> _saveWebSettings() async {
    if (!kIsWeb) return;
    try {
      final json = jsonEncode(_webSettings.toMap());
      WebStorageService.setString('electricity_settings', json);
    } catch (e) {
      debugPrint('❌ خطأ في حفظ الإعدادات: $e');
    }
  }

  /// الحصول على قاعدة البيانات
  Future<Database> get database async {
    if (kIsWeb) {
      throw Exception('استخدم الطرق المباشرة للويب');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// تهيئة قاعدة البيانات
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'electricity_billing.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  /// إنشاء الجداول
  Future<void> _createDatabase(Database db, int version) async {
    // جدول العملاء
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        address TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // جدول الفواتير
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceNumber TEXT NOT NULL UNIQUE,
        customerId INTEGER NOT NULL,
        customerName TEXT NOT NULL,
        customerPhone TEXT NOT NULL,
        customerAddress TEXT,
        oldReading REAL NOT NULL,
        newReading REAL NOT NULL,
        consumption REAL NOT NULL,
        kwhPrice REAL NOT NULL,
        totalAmount REAL NOT NULL,
        invoiceDate TEXT NOT NULL,
        hijriDate TEXT,
        notes TEXT,
        stampText TEXT NOT NULL,
        isPaid INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    // جدول الإعدادات
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        defaultKwhPrice REAL NOT NULL DEFAULT 0.10,
        stampText TEXT NOT NULL DEFAULT 'alsalem – Billing Services',
        showHijriDate INTEGER NOT NULL DEFAULT 0,
        companyName TEXT NOT NULL DEFAULT 'خدمات فوترة الكهرباء',
        companyPhone TEXT,
        companyAddress TEXT,
        lastInvoiceNumber INTEGER NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'USD',
        language TEXT NOT NULL DEFAULT 'ar'
      )
    ''');

    // إدراج الإعدادات الافتراضية
    await db.insert('settings', AppSettings().toMap()..remove('id'));

    // إنشاء الفهارس للبحث السريع
    await db.execute('CREATE INDEX idx_customers_name ON customers(fullName)');
    await db.execute(
      'CREATE INDEX idx_customers_phone ON customers(phoneNumber)',
    );
    await db.execute(
      'CREATE INDEX idx_invoices_number ON invoices(invoiceNumber)',
    );
    await db.execute(
      'CREATE INDEX idx_invoices_customer ON invoices(customerId)',
    );
    await db.execute('CREATE INDEX idx_invoices_date ON invoices(invoiceDate)');
  }

  /// ترقية قاعدة البيانات
  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // يمكن إضافة ترقيات مستقبلية هنا
  }

  // ==================== عمليات العملاء ====================

  /// إضافة عميل جديد
  Future<int> insertCustomer(Customer customer) async {
    if (kIsWeb) {
      await _initWebStorage();
      final id = _webCustomerId++;
      final newCustomer = customer.copyWith(id: id);
      _webCustomers.add(newCustomer);
      await _saveWebCustomers();
      debugPrint('تم إضافة العميل: ${newCustomer.fullName} بمعرف $id');
      return id;
    }
    final db = await database;
    final map = customer.toMap()..remove('id');
    return await db.insert('customers', map);
  }

  /// تحديث بيانات عميل
  Future<int> updateCustomer(Customer customer) async {
    if (kIsWeb) {
      await _initWebStorage();
      final index = _webCustomers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _webCustomers[index] = customer;
        await _saveWebCustomers();
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  /// حذف عميل
  Future<int> deleteCustomer(int id) async {
    if (kIsWeb) {
      await _initWebStorage();
      final initialLength = _webCustomers.length;
      _webCustomers.removeWhere((c) => c.id == id);
      await _saveWebCustomers();
      return initialLength - _webCustomers.length;
    }
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  /// الحصول على عميل بالمعرف
  Future<Customer?> getCustomerById(int id) async {
    if (kIsWeb) {
      await _initWebStorage();
      try {
        return _webCustomers.firstWhere((c) => c.id == id);
      } catch (e) {
        return null;
      }
    }
    final db = await database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  /// الحصول على جميع العملاء
  Future<List<Customer>> getAllCustomers() async {
    if (kIsWeb) {
      await _initWebStorage();
      final sorted = List<Customer>.from(_webCustomers);
      sorted.sort((a, b) => a.fullName.compareTo(b.fullName));
      return sorted;
    }
    final db = await database;
    final maps = await db.query('customers', orderBy: 'fullName ASC');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// البحث عن عملاء
  Future<List<Customer>> searchCustomers(String query) async {
    if (kIsWeb) {
      await _initWebStorage();
      final lowerQuery = query.toLowerCase();
      return _webCustomers
          .where(
            (c) =>
                c.fullName.toLowerCase().contains(lowerQuery) ||
                c.phoneNumber.contains(query),
          )
          .toList();
    }
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'fullName LIKE ? OR phoneNumber LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'fullName ASC',
    );
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// إدراج عملاء متعددين (للاستيراد من Excel)
  Future<void> insertCustomers(List<Customer> customers) async {
    if (kIsWeb) {
      for (final customer in customers) {
        await insertCustomer(customer);
      }
      return;
    }
    final db = await database;
    final batch = db.batch();
    for (final customer in customers) {
      final map = customer.toMap()..remove('id');
      batch.insert('customers', map);
    }
    await batch.commit(noResult: true);
  }

  // ==================== عمليات الفواتير ====================

  /// إضافة فاتورة جديدة
  Future<int> insertInvoice(Invoice invoice) async {
    if (kIsWeb) {
      await _initWebStorage();
      final id = _webInvoiceId++;
      final newInvoice = invoice.copyWith(id: id);
      _webInvoices.add(newInvoice);
      _webSettings = _webSettings.copyWith(
        lastInvoiceNumber: _webSettings.lastInvoiceNumber + 1,
      );
      await _saveWebInvoices();
      await _saveWebSettings();
      return id;
    }
    final db = await database;
    final map = invoice.toMap()..remove('id');
    return await db.insert('invoices', map);
  }

  /// تحديث فاتورة
  Future<int> updateInvoice(Invoice invoice) async {
    if (kIsWeb) {
      await _initWebStorage();
      final index = _webInvoices.indexWhere((i) => i.id == invoice.id);
      if (index != -1) {
        _webInvoices[index] = invoice;
        await _saveWebInvoices();
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

  /// حذف فاتورة
  Future<int> deleteInvoice(int id) async {
    if (kIsWeb) {
      await _initWebStorage();
      final initialLength = _webInvoices.length;
      _webInvoices.removeWhere((i) => i.id == id);
      await _saveWebInvoices();
      return initialLength - _webInvoices.length;
    }
    final db = await database;
    return await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  /// الحصول على فاتورة بالمعرف
  Future<Invoice?> getInvoiceById(int id) async {
    if (kIsWeb) {
      await _initWebStorage();
      try {
        return _webInvoices.firstWhere((i) => i.id == id);
      } catch (e) {
        return null;
      }
    }
    final db = await database;
    final maps = await db.query('invoices', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Invoice.fromMap(maps.first);
  }

  /// الحصول على جميع الفواتير
  Future<List<Invoice>> getAllInvoices() async {
    if (kIsWeb) {
      await _initWebStorage();
      final sorted = List<Invoice>.from(_webInvoices);
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted;
    }
    final db = await database;
    final maps = await db.query('invoices', orderBy: 'createdAt DESC');
    return maps.map((map) => Invoice.fromMap(map)).toList();
  }

  /// البحث عن فواتير
  Future<List<Invoice>> searchInvoices(String query) async {
    if (kIsWeb) {
      await _initWebStorage();
      final lowerQuery = query.toLowerCase();
      return _webInvoices
          .where(
            (i) =>
                i.customerName.toLowerCase().contains(lowerQuery) ||
                i.invoiceNumber.contains(query),
          )
          .toList();
    }
    final db = await database;
    final maps = await db.query(
      'invoices',
      where: 'customerName LIKE ? OR invoiceNumber LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Invoice.fromMap(map)).toList();
  }

  /// تصفية الفواتير حسب التاريخ
  Future<List<Invoice>> getInvoicesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (kIsWeb) {
      await _initWebStorage();
      return _webInvoices
          .where(
            (i) =>
                i.invoiceDate.isAfter(
                  startDate.subtract(const Duration(days: 1)),
                ) &&
                i.invoiceDate.isBefore(endDate.add(const Duration(days: 1))),
          )
          .toList();
    }
    final db = await database;
    final maps = await db.query(
      'invoices',
      where: 'invoiceDate >= ? AND invoiceDate <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Invoice.fromMap(map)).toList();
  }

  /// الحصول على فواتير عميل معين
  Future<List<Invoice>> getInvoicesByCustomer(int customerId) async {
    if (kIsWeb) {
      await _initWebStorage();
      return _webInvoices.where((i) => i.customerId == customerId).toList();
    }
    final db = await database;
    final maps = await db.query(
      'invoices',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Invoice.fromMap(map)).toList();
  }

  /// الحصول على آخر رقم فاتورة
  Future<int> getLastInvoiceNumber() async {
    if (kIsWeb) {
      await _initWebStorage();
      return _webSettings.lastInvoiceNumber;
    }
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(CAST(invoiceNumber AS INTEGER)) as lastNumber FROM invoices',
    );
    if (result.isEmpty || result.first['lastNumber'] == null) {
      return 0;
    }
    return result.first['lastNumber'] as int;
  }

  /// الحصول على إحصائيات الفواتير
  Future<Map<String, dynamic>> getInvoiceStats() async {
    if (kIsWeb) {
      await _initWebStorage();
      final total = _webInvoices.fold<double>(
        0,
        (sum, i) => sum + i.totalAmount,
      );
      final paid = _webInvoices.where((i) => i.isPaid).toList();
      final paidTotal = paid.fold<double>(0, (sum, i) => sum + i.totalAmount);
      final unpaid = _webInvoices.where((i) => !i.isPaid).toList();
      final unpaidTotal = unpaid.fold<double>(
        0,
        (sum, i) => sum + i.totalAmount,
      );

      return {
        'totalInvoices': _webInvoices.length,
        'totalAmount': total,
        'paidInvoices': paid.length,
        'paidAmount': paidTotal,
        'unpaidInvoices': unpaid.length,
        'unpaidAmount': unpaidTotal,
      };
    }
    final db = await database;

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(totalAmount) as total FROM invoices',
    );

    final paidResult = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(totalAmount) as total FROM invoices WHERE isPaid = 1',
    );

    final unpaidResult = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(totalAmount) as total FROM invoices WHERE isPaid = 0',
    );

    return {
      'totalInvoices': totalResult.first['count'] ?? 0,
      'totalAmount': totalResult.first['total'] ?? 0.0,
      'paidInvoices': paidResult.first['count'] ?? 0,
      'paidAmount': paidResult.first['total'] ?? 0.0,
      'unpaidInvoices': unpaidResult.first['count'] ?? 0,
      'unpaidAmount': unpaidResult.first['total'] ?? 0.0,
    };
  }

  // ==================== عمليات الإعدادات ====================

  /// الحصول على الإعدادات
  Future<AppSettings> getSettings() async {
    if (kIsWeb) {
      await _initWebStorage();
      return _webSettings;
    }
    final db = await database;
    final maps = await db.query('settings', limit: 1);
    if (maps.isEmpty) {
      // إنشاء إعدادات افتراضية إذا لم تكن موجودة
      final settings = AppSettings();
      await db.insert('settings', settings.toMap()..remove('id'));
      return settings;
    }
    return AppSettings.fromMap(maps.first);
  }

  /// تحديث الإعدادات
  Future<int> updateSettings(AppSettings settings) async {
    if (kIsWeb) {
      await _initWebStorage();
      _webSettings = settings;
      await _saveWebSettings();
      return 1;
    }
    final db = await database;
    return await db.update(
      'settings',
      settings.toMap(),
      where: 'id = ?',
      whereArgs: [settings.id ?? 1],
    );
  }

  /// تحديث آخر رقم فاتورة
  Future<void> updateLastInvoiceNumber(int number) async {
    if (kIsWeb) {
      await _initWebStorage();
      _webSettings = _webSettings.copyWith(lastInvoiceNumber: number);
      await _saveWebSettings();
      return;
    }
    final db = await database;
    await db.update(
      'settings',
      {'lastInvoiceNumber': number},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  /// إغلاق قاعدة البيانات
  Future<void> close() async {
    if (kIsWeb) return;
    final db = await database;
    await db.close();
    _database = null;
  }

  /// حذف قاعدة البيانات (للاختبار)
  Future<void> deleteDatabase() async {
    if (kIsWeb) {
      _webCustomers.clear();
      _webInvoices.clear();
      _webSettings = AppSettings();
      _webCustomerId = 1;
      _webInvoiceId = 1;
      _webDataLoaded = false;
      WebStorageService.remove('electricity_customers');
      WebStorageService.remove('electricity_invoices');
      WebStorageService.remove('electricity_settings');
      debugPrint('تم حذف جميع البيانات من localStorage');
      return;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'electricity_billing.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
