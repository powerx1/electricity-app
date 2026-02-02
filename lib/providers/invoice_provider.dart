import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hijri/hijri_calendar.dart';
import '../models/models.dart';
import '../services/services.dart';

/// مزود بيانات الفواتير - Invoice Provider
class InvoiceProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final PdfService _pdfService = PdfService();

  List<Invoice> _invoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic> _stats = {};

  // Getters
  List<Invoice> get invoices =>
      _filteredInvoices.isEmpty &&
          _searchQuery.isEmpty &&
          _startDate == null &&
          _endDate == null
      ? _invoices
      : _filteredInvoices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get invoiceCount => _invoices.length;
  Map<String, dynamic> get stats => _stats;

  /// تحميل جميع الفواتير
  Future<void> loadInvoices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _invoices = await _dbService.getAllInvoices();
      _filteredInvoices = [];
      _searchQuery = '';
      _startDate = null;
      _endDate = null;
      await _loadStats();
    } catch (e) {
      _error = 'فشل في تحميل الفواتير: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تحميل الإحصائيات
  Future<void> _loadStats() async {
    try {
      _stats = await _dbService.getInvoiceStats();
    } catch (e) {
      _stats = {};
    }
  }

  /// البحث عن فواتير
  Future<void> searchInvoices(String query) async {
    _searchQuery = query;

    if (query.isEmpty && _startDate == null) {
      _filteredInvoices = [];
      notifyListeners();
      return;
    }

    try {
      if (query.isNotEmpty) {
        _filteredInvoices = await _dbService.searchInvoices(query);
      }
      notifyListeners();
    } catch (e) {
      _error = 'فشل في البحث: $e';
      notifyListeners();
    }
  }

  /// تصفية الفواتير حسب التاريخ
  Future<void> filterByDateRange(DateTime start, DateTime end) async {
    _startDate = start;
    _endDate = end;

    try {
      _filteredInvoices = await _dbService.getInvoicesByDateRange(start, end);
      notifyListeners();
    } catch (e) {
      _error = 'فشل في التصفية: $e';
      notifyListeners();
    }
  }

  /// مسح التصفية
  void clearFilter() {
    _filteredInvoices = [];
    _searchQuery = '';
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  /// الحصول على رقم الفاتورة التالي
  Future<String> getNextInvoiceNumber() async {
    final lastNumber = await _dbService.getLastInvoiceNumber();
    return Invoice.generateInvoiceNumber(lastNumber);
  }

  /// الحصول على التاريخ الهجري
  String? getHijriDate(DateTime date, bool showHijri) {
    if (!showHijri) return null;

    final hijri = HijriCalendar.fromDate(date);
    return '${hijri.hDay}/${hijri.hMonth}/${hijri.hYear}';
  }

  /// إنشاء فاتورة جديدة
  Future<Invoice?> createInvoice({
    required Customer customer,
    required double oldReading,
    required double newReading,
    required double kwhPrice,
    required String stampText,
    required bool showHijriDate,
    String? notes,
  }) async {
    try {
      // التحقق من صحة القراءات
      if (!Invoice.isValidReadings(oldReading, newReading)) {
        _error = 'القراءة الجديدة يجب أن تكون أكبر من أو تساوي القراءة القديمة';
        notifyListeners();
        return null;
      }

      // حساب الاستهلاك والإجمالي
      final consumption = Invoice.calculateConsumption(oldReading, newReading);
      final totalAmount = Invoice.calculateTotal(consumption, kwhPrice);

      // إنشاء رقم الفاتورة
      final invoiceNumber = await getNextInvoiceNumber();
      final invoiceDate = DateTime.now();
      final hijriDate = getHijriDate(invoiceDate, showHijriDate);

      // إنشاء الفاتورة
      final invoice = Invoice(
        invoiceNumber: invoiceNumber,
        customerId: customer.id!,
        customerName: customer.fullName,
        customerPhone: customer.phoneNumber,
        customerAddress: customer.address,
        oldReading: oldReading,
        newReading: newReading,
        consumption: consumption,
        kwhPrice: kwhPrice,
        totalAmount: totalAmount,
        invoiceDate: invoiceDate,
        hijriDate: hijriDate,
        notes: notes,
        stampText: stampText,
      );

      // حفظ الفاتورة
      final id = await _dbService.insertInvoice(invoice);
      final savedInvoice = invoice.copyWith(id: id);

      // تحديث آخر رقم فاتورة
      await _dbService.updateLastInvoiceNumber(int.parse(invoiceNumber));

      // إضافة للقائمة
      _invoices.insert(0, savedInvoice);
      await _loadStats();
      notifyListeners();

      return savedInvoice;
    } catch (e) {
      _error = 'فشل في إنشاء الفاتورة: $e';
      notifyListeners();
      return null;
    }
  }

  /// تحديث حالة الدفع
  Future<bool> updatePaymentStatus(int invoiceId, bool isPaid) async {
    try {
      final invoice = _invoices.firstWhere((i) => i.id == invoiceId);
      final updatedInvoice = invoice.copyWith(isPaid: isPaid);
      await _dbService.updateInvoice(updatedInvoice);

      final index = _invoices.indexWhere((i) => i.id == invoiceId);
      if (index != -1) {
        _invoices[index] = updatedInvoice;
      }

      await _loadStats();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل في تحديث حالة الدفع: $e';
      notifyListeners();
      return false;
    }
  }

  /// حذف فاتورة
  Future<bool> deleteInvoice(int id) async {
    try {
      await _dbService.deleteInvoice(id);
      _invoices.removeWhere((i) => i.id == id);
      _filteredInvoices.removeWhere((i) => i.id == id);
      await _loadStats();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل في حذف الفاتورة: $e';
      notifyListeners();
      return false;
    }
  }

  /// الحصول على فاتورة بالمعرف
  Invoice? getInvoiceById(int id) {
    try {
      return _invoices.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }

  /// الحصول على فواتير عميل معين
  Future<List<Invoice>> getInvoicesByCustomer(int customerId) async {
    return await _dbService.getInvoicesByCustomer(customerId);
  }

  /// إنشاء PDF للفاتورة
  Future<File?> generateInvoicePdf(
    Invoice invoice, {
    AppSettings? settings,
  }) async {
    try {
      final pdfBytes = await _pdfService.generateInvoicePdf(
        invoice,
        settings: settings,
      );
      final file = await _pdfService.savePdfToFile(
        pdfBytes,
        invoice.invoiceNumber,
      );
      return file;
    } catch (e) {
      _error = 'فشل في إنشاء PDF: $e';
      notifyListeners();
      return null;
    }
  }

  /// مسح الخطأ
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
