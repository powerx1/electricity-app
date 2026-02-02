import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// مزود بيانات العملاء - Customer Provider
class CustomerProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Getters
  List<Customer> get customers =>
      _filteredCustomers.isEmpty && _searchQuery.isEmpty
      ? _customers
      : _filteredCustomers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get customerCount => _customers.length;

  /// تحميل جميع العملاء
  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _customers = await _dbService.getAllCustomers();
      _filteredCustomers = [];
      _searchQuery = '';
    } catch (e) {
      _error = 'فشل في تحميل العملاء: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// البحث عن عملاء
  Future<void> searchCustomers(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredCustomers = [];
      notifyListeners();
      return;
    }

    try {
      _filteredCustomers = await _dbService.searchCustomers(query);
      notifyListeners();
    } catch (e) {
      _error = 'فشل في البحث: $e';
      notifyListeners();
    }
  }

  /// إضافة عميل جديد
  Future<Customer?> addCustomer(Customer customer) async {
    try {
      final id = await _dbService.insertCustomer(customer);
      final newCustomer = customer.copyWith(id: id);
      _customers.add(newCustomer);
      _customers.sort((a, b) => a.fullName.compareTo(b.fullName));
      notifyListeners();
      return newCustomer;
    } catch (e) {
      _error = 'فشل في إضافة العميل: $e';
      notifyListeners();
      return null;
    }
  }

  /// تحديث عميل
  Future<bool> updateCustomer(Customer customer) async {
    try {
      await _dbService.updateCustomer(customer);
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
        _customers.sort((a, b) => a.fullName.compareTo(b.fullName));
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل في تحديث العميل: $e';
      notifyListeners();
      return false;
    }
  }

  /// حذف عميل
  Future<bool> deleteCustomer(int id) async {
    try {
      await _dbService.deleteCustomer(id);
      _customers.removeWhere((c) => c.id == id);
      _filteredCustomers.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل في حذف العميل: $e';
      notifyListeners();
      return false;
    }
  }

  /// الحصول على عميل بالمعرف
  Customer? getCustomerById(int id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// استيراد عملاء من Excel
  Future<ImportResult<Customer>> importFromExcel() async {
    final excelService = ExcelService();

    try {
      final file = await excelService.pickExcelFile();
      if (file == null) {
        return ImportResult(
          success: false,
          data: [],
          errors: [ImportError(row: 0, message: 'لم يتم اختيار ملف')],
        );
      }

      final result = await excelService.importCustomersFromExcel(file);

      if (result.data.isNotEmpty) {
        await _dbService.insertCustomers(result.data);
        await loadCustomers(); // إعادة تحميل القائمة
      }

      return result;
    } catch (e) {
      return ImportResult(
        success: false,
        data: [],
        errors: [ImportError(row: 0, message: 'فشل في الاستيراد: $e')],
      );
    }
  }

  /// مسح الخطأ
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
