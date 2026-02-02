/// نموذج إعدادات التطبيق - App Settings Model
class AppSettings {
  final int? id;
  final double defaultKwhPrice; // سعر الكيلوواط الافتراضي
  final String stampText; // نص الختم/التوقيع
  final bool showHijriDate; // إظهار التاريخ الهجري
  final String companyName; // اسم الشركة
  final String? companyPhone; // رقم هاتف الشركة
  final String? companyAddress; // عنوان الشركة
  final int lastInvoiceNumber; // آخر رقم فاتورة
  final String currency; // العملة (USD)
  final String language; // اللغة (ar)

  AppSettings({
    this.id,
    this.defaultKwhPrice = 0.10,
    this.stampText = 'alsalem – Billing Services',
    this.showHijriDate = false,
    this.companyName = 'خدمات فوترة الكهرباء',
    this.companyPhone,
    this.companyAddress,
    this.lastInvoiceNumber = 0,
    this.currency = 'USD',
    this.language = 'ar',
  });

  /// تحويل الإعدادات إلى Map لحفظها في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'defaultKwhPrice': defaultKwhPrice,
      'stampText': stampText,
      'showHijriDate': showHijriDate ? 1 : 0,
      'companyName': companyName,
      'companyPhone': companyPhone,
      'companyAddress': companyAddress,
      'lastInvoiceNumber': lastInvoiceNumber,
      'currency': currency,
      'language': language,
    };
  }

  /// إنشاء إعدادات من Map (من قاعدة البيانات)
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'] as int?,
      defaultKwhPrice: (map['defaultKwhPrice'] as num?)?.toDouble() ?? 0.10,
      stampText: map['stampText'] as String? ?? 'alsalem – Billing Services',
      showHijriDate: (map['showHijriDate'] as int?) == 1,
      companyName: map['companyName'] as String? ?? 'خدمات فوترة الكهرباء',
      companyPhone: map['companyPhone'] as String?,
      companyAddress: map['companyAddress'] as String?,
      lastInvoiceNumber: map['lastInvoiceNumber'] as int? ?? 0,
      currency: map['currency'] as String? ?? 'USD',
      language: map['language'] as String? ?? 'ar',
    );
  }

  /// نسخ الإعدادات مع تعديلات
  AppSettings copyWith({
    int? id,
    double? defaultKwhPrice,
    String? stampText,
    bool? showHijriDate,
    String? companyName,
    String? companyPhone,
    String? companyAddress,
    int? lastInvoiceNumber,
    String? currency,
    String? language,
  }) {
    return AppSettings(
      id: id ?? this.id,
      defaultKwhPrice: defaultKwhPrice ?? this.defaultKwhPrice,
      stampText: stampText ?? this.stampText,
      showHijriDate: showHijriDate ?? this.showHijriDate,
      companyName: companyName ?? this.companyName,
      companyPhone: companyPhone ?? this.companyPhone,
      companyAddress: companyAddress ?? this.companyAddress,
      lastInvoiceNumber: lastInvoiceNumber ?? this.lastInvoiceNumber,
      currency: currency ?? this.currency,
      language: language ?? this.language,
    );
  }

  /// الحصول على رقم الفاتورة التالي
  String get nextInvoiceNumber {
    return (lastInvoiceNumber + 1).toString().padLeft(3, '0');
  }

  @override
  String toString() {
    return 'AppSettings(defaultKwhPrice: $defaultKwhPrice, stampText: $stampText, showHijriDate: $showHijriDate)';
  }
}
