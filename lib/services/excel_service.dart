import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';

/// خدمة استيراد Excel - Excel Import Service
class ExcelService {
  static final ExcelService _instance = ExcelService._internal();
  factory ExcelService() => _instance;
  ExcelService._internal();

  /// اختيار ملف Excel
  Future<File?> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path != null) {
        return File(path);
      }
    }
    return null;
  }

  /// استيراد العملاء من ملف Excel
  /// يتوقع الملف أن يحتوي على الأعمدة التالية:
  /// A: الاسم الكامل (مطلوب)
  /// B: رقم الهاتف (مطلوب)
  /// C: العنوان (اختياري)
  /// D: رقم العداد (اختياري)
  /// E: ملاحظات (اختياري)
  Future<ImportResult<Customer>> importCustomersFromExcel(File file) async {
    final List<Customer> customers = [];
    final List<ImportError> errors = [];

    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // الحصول على الورقة الأولى
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null) {
        return ImportResult(
          success: false,
          data: [],
          errors: [ImportError(row: 0, message: 'الملف فارغ أو غير صالح')],
        );
      }

      // تخطي الصف الأول (العناوين)
      for (var i = 1; i < sheet.maxRows; i++) {
        try {
          final row = sheet.row(i);

          // التحقق من وجود البيانات المطلوبة
          final fullName = _getCellValue(row, 0);
          final phoneNumber = _getCellValue(row, 1);

          if (fullName.isEmpty) {
            if (phoneNumber.isNotEmpty) {
              errors.add(
                ImportError(row: i + 1, message: 'الاسم الكامل مطلوب'),
              );
            }
            continue; // تخطي الصفوف الفارغة
          }

          if (phoneNumber.isEmpty) {
            errors.add(
              ImportError(
                row: i + 1,
                message: 'رقم الهاتف مطلوب للعميل: $fullName',
              ),
            );
            continue;
          }

          // التحقق من صحة رقم الهاتف
          if (!Customer.isValidPhoneNumber(phoneNumber)) {
            errors.add(
              ImportError(
                row: i + 1,
                message: 'رقم الهاتف غير صالح للعميل: $fullName',
              ),
            );
            continue;
          }

          final customer = Customer(
            fullName: fullName,
            phoneNumber: phoneNumber,
            address: _getCellValueOrNull(row, 2),
            notes: _getCellValueOrNull(row, 3),
          );

          customers.add(customer);
        } catch (e) {
          errors.add(ImportError(row: i + 1, message: 'خطأ في قراءة الصف: $e'));
        }
      }

      return ImportResult(
        success: errors.isEmpty,
        data: customers,
        errors: errors,
        totalRows: sheet.maxRows - 1,
        successfulRows: customers.length,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        data: [],
        errors: [ImportError(row: 0, message: 'خطأ في قراءة الملف: $e')],
      );
    }
  }

  /// استيراد سجلات الفوترة من ملف Excel
  /// يتوقع الملف أن يحتوي على الأعمدة التالية:
  /// A: اسم العميل (مطلوب)
  /// B: رقم الهاتف (مطلوب)
  /// C: القراءة القديمة (مطلوب)
  /// D: القراءة الجديدة (مطلوب)
  /// E: رقم العداد (اختياري)
  /// F: ملاحظات (اختياري)
  Future<ImportResult<BillingRecord>> importBillingRecordsFromExcel(
    File file,
  ) async {
    final List<BillingRecord> records = [];
    final List<ImportError> errors = [];

    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null) {
        return ImportResult(
          success: false,
          data: [],
          errors: [ImportError(row: 0, message: 'الملف فارغ أو غير صالح')],
        );
      }

      for (var i = 1; i < sheet.maxRows; i++) {
        try {
          final row = sheet.row(i);

          final customerName = _getCellValue(row, 0);
          final phoneNumber = _getCellValue(row, 1);
          final oldReadingStr = _getCellValue(row, 2);
          final newReadingStr = _getCellValue(row, 3);

          if (customerName.isEmpty) continue;

          if (phoneNumber.isEmpty) {
            errors.add(
              ImportError(
                row: i + 1,
                message: 'رقم الهاتف مطلوب للعميل: $customerName',
              ),
            );
            continue;
          }

          final oldReading = double.tryParse(oldReadingStr);
          final newReading = double.tryParse(newReadingStr);

          if (oldReading == null) {
            errors.add(
              ImportError(
                row: i + 1,
                message: 'القراءة القديمة غير صالحة للعميل: $customerName',
              ),
            );
            continue;
          }

          if (newReading == null) {
            errors.add(
              ImportError(
                row: i + 1,
                message: 'القراءة الجديدة غير صالحة للعميل: $customerName',
              ),
            );
            continue;
          }

          if (newReading < oldReading) {
            errors.add(
              ImportError(
                row: i + 1,
                message:
                    'القراءة الجديدة يجب أن تكون أكبر من أو تساوي القديمة للعميل: $customerName',
              ),
            );
            continue;
          }

          records.add(
            BillingRecord(
              customerName: customerName,
              phoneNumber: phoneNumber,
              oldReading: oldReading,
              newReading: newReading,
              notes: _getCellValueOrNull(row, 4),
            ),
          );
        } catch (e) {
          errors.add(ImportError(row: i + 1, message: 'خطأ في قراءة الصف: $e'));
        }
      }

      return ImportResult(
        success: errors.isEmpty,
        data: records,
        errors: errors,
        totalRows: sheet.maxRows - 1,
        successfulRows: records.length,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        data: [],
        errors: [ImportError(row: 0, message: 'خطأ في قراءة الملف: $e')],
      );
    }
  }

  /// الحصول على قيمة الخلية كنص
  String _getCellValue(List<Data?> row, int index) {
    if (index >= row.length || row[index] == null) return '';
    final value = row[index]!.value;
    if (value == null) return '';
    return value.toString().trim();
  }

  /// الحصول على قيمة الخلية أو null
  String? _getCellValueOrNull(List<Data?> row, int index) {
    final value = _getCellValue(row, index);
    return value.isEmpty ? null : value;
  }

  /// إنشاء قالب Excel للعملاء
  Future<File> createCustomerTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['العملاء'];

    // إضافة العناوين
    sheet.appendRow([
      TextCellValue('الاسم الكامل'),
      TextCellValue('رقم الهاتف'),
      TextCellValue('العنوان'),
      TextCellValue('رقم العداد'),
      TextCellValue('ملاحظات'),
    ]);

    // إضافة مثال
    sheet.appendRow([
      TextCellValue('أحمد محمد'),
      TextCellValue('+966501234567'),
      TextCellValue('الرياض - حي النخيل'),
      TextCellValue('12345'),
      TextCellValue('عميل VIP'),
    ]);

    // حفظ الملف
    final bytes = excel.save();
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/customer_template.xlsx');
    await file.writeAsBytes(bytes!);
    return file;
  }

  /// إنشاء قالب Excel للفوترة
  Future<File> createBillingTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['الفوترة'];

    sheet.appendRow([
      TextCellValue('اسم العميل'),
      TextCellValue('رقم الهاتف'),
      TextCellValue('القراءة القديمة'),
      TextCellValue('القراءة الجديدة'),
      TextCellValue('رقم العداد'),
      TextCellValue('ملاحظات'),
    ]);

    sheet.appendRow([
      TextCellValue('أحمد محمد'),
      TextCellValue('+966501234567'),
      IntCellValue(1000),
      IntCellValue(1250),
      TextCellValue('12345'),
      TextCellValue(''),
    ]);

    final bytes = excel.save();
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/billing_template.xlsx');
    await file.writeAsBytes(bytes!);
    return file;
  }
}

/// نتيجة الاستيراد
class ImportResult<T> {
  final bool success;
  final List<T> data;
  final List<ImportError> errors;
  final int totalRows;
  final int successfulRows;

  ImportResult({
    required this.success,
    required this.data,
    required this.errors,
    this.totalRows = 0,
    this.successfulRows = 0,
  });
}

/// خطأ في الاستيراد
class ImportError {
  final int row;
  final String message;

  ImportError({required this.row, required this.message});
}

/// سجل فوترة مستورد
class BillingRecord {
  final String customerName;
  final String phoneNumber;
  final double oldReading;
  final double newReading;
  final String? notes;

  BillingRecord({
    required this.customerName,
    required this.phoneNumber,
    required this.oldReading,
    required this.newReading,
    this.notes,
  });

  double get consumption => newReading - oldReading;
}
