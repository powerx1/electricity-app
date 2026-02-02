/// ثوابت التطبيق
class AppConstants {
  // أسماء الشاشات
  static const String appName = 'فواتير الكهرباء';
  static const String appNameEn = 'Electricity Billing';

  // مسارات التنقل
  static const String dashboardRoute = '/';
  static const String customersRoute = '/customers';
  static const String addCustomerRoute = '/customers/add';
  static const String editCustomerRoute = '/customers/edit';
  static const String createInvoiceRoute = '/invoice/create';
  static const String invoiceHistoryRoute = '/invoices';
  static const String invoiceDetailsRoute = '/invoices/details';
  static const String settingsRoute = '/settings';

  // القيم الافتراضية
  static const double defaultKwhPrice = 0.10;
  static const String defaultStampText = 'alsalem – Billing Services';
  static const String defaultCurrency = 'USD';
  static const String defaultLanguage = 'ar';

  // التحقق
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;
  static const int invoiceNumberPadding = 3;

  // رسائل الأخطاء
  static const String errorRequired = 'هذا الحقل مطلوب';
  static const String errorInvalidPhone = 'رقم الهاتف غير صالح';
  static const String errorInvalidReading = 'القراءة غير صالحة';
  static const String errorReadingMismatch =
      'القراءة الجديدة يجب أن تكون أكبر من أو تساوي القراءة القديمة';
  static const String errorInvalidPrice = 'السعر غير صالح';

  // رسائل النجاح
  static const String successCustomerAdded = 'تم إضافة العميل بنجاح';
  static const String successCustomerUpdated = 'تم تحديث العميل بنجاح';
  static const String successCustomerDeleted = 'تم حذف العميل بنجاح';
  static const String successInvoiceCreated = 'تم إنشاء الفاتورة بنجاح';
  static const String successSettingsUpdated = 'تم حفظ الإعدادات بنجاح';
  static const String successImport = 'تم الاستيراد بنجاح';

  // تسميات الشاشات
  static const String labelDashboard = 'الرئيسية';
  static const String labelCustomers = 'العملاء';
  static const String labelCreateInvoice = 'إنشاء فاتورة';
  static const String labelInvoiceHistory = 'سجل الفواتير';
  static const String labelSettings = 'الإعدادات';

  // تسميات الحقول
  static const String labelFullName = 'الاسم الكامل';
  static const String labelPhoneNumber = 'رقم الهاتف';
  static const String labelAddress = 'العنوان';
  static const String labelNotes = 'ملاحظات';
  static const String labelOldReading = 'القراءة السابقة';
  static const String labelNewReading = 'القراءة الحالية';
  static const String labelConsumption = 'الاستهلاك';
  static const String labelKwhPrice = 'سعر الكيلوواط';
  static const String labelTotal = 'المبلغ الإجمالي';
  static const String labelInvoiceNumber = 'رقم الفاتورة';
  static const String labelInvoiceDate = 'تاريخ الفاتورة';
  static const String labelStampText = 'نص الختم';
  static const String labelShowHijri = 'إظهار التاريخ الهجري';
  static const String labelCompanyName = 'اسم الشركة';

  // أزرار
  static const String btnSave = 'حفظ';
  static const String btnCancel = 'إلغاء';
  static const String btnDelete = 'حذف';
  static const String btnEdit = 'تعديل';
  static const String btnAdd = 'إضافة';
  static const String btnSearch = 'بحث';
  static const String btnFilter = 'تصفية';
  static const String btnPrint = 'طباعة';
  static const String btnShare = 'مشاركة';
  static const String btnWhatsApp = 'إرسال عبر WhatsApp';
  static const String btnExportPdf = 'تصدير PDF';
  static const String btnImportExcel = 'استيراد من Excel';
  static const String btnCreateInvoice = 'إنشاء الفاتورة';
}
