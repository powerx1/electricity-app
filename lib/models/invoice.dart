/// نموذج الفاتورة - Invoice Model
class Invoice {
  final int? id;
  final String invoiceNumber; // رقم الفاتورة: 001, 002, etc.
  final int customerId;
  final String customerName;
  final String customerPhone;
  final String? customerAddress;
  final double oldReading; // القراءة القديمة
  final double newReading; // القراءة الجديدة
  final double consumption; // الاستهلاك = القراءة الجديدة - القديمة
  final double kwhPrice; // سعر الكيلوواط بالدولار
  final double totalAmount; // المبلغ الإجمالي بالدولار
  final DateTime invoiceDate; // تاريخ الفاتورة
  final String? hijriDate; // التاريخ الهجري (اختياري)
  final String? notes;
  final String stampText; // نص الختم/التوقيع
  final bool isPaid; // هل تم الدفع
  final DateTime createdAt;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerAddress,
    required this.oldReading,
    required this.newReading,
    required this.consumption,
    required this.kwhPrice,
    required this.totalAmount,
    required this.invoiceDate,
    this.hijriDate,
    this.notes,
    required this.stampText,
    this.isPaid = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// تحويل الفاتورة إلى Map لحفظها في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'oldReading': oldReading,
      'newReading': newReading,
      'consumption': consumption,
      'kwhPrice': kwhPrice,
      'totalAmount': totalAmount,
      'invoiceDate': invoiceDate.toIso8601String(),
      'hijriDate': hijriDate,
      'notes': notes,
      'stampText': stampText,
      'isPaid': isPaid ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// إنشاء فاتورة من Map (من قاعدة البيانات)
  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as int?,
      invoiceNumber: map['invoiceNumber'] as String,
      customerId: map['customerId'] as int,
      customerName: map['customerName'] as String,
      customerPhone: map['customerPhone'] as String,
      customerAddress: map['customerAddress'] as String?,
      oldReading: (map['oldReading'] as num).toDouble(),
      newReading: (map['newReading'] as num).toDouble(),
      consumption: (map['consumption'] as num).toDouble(),
      kwhPrice: (map['kwhPrice'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      invoiceDate: DateTime.parse(map['invoiceDate'] as String),
      hijriDate: map['hijriDate'] as String?,
      notes: map['notes'] as String?,
      stampText: map['stampText'] as String,
      isPaid: (map['isPaid'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// نسخ الفاتورة مع تعديلات
  Invoice copyWith({
    int? id,
    String? invoiceNumber,
    int? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    double? oldReading,
    double? newReading,
    double? consumption,
    double? kwhPrice,
    double? totalAmount,
    DateTime? invoiceDate,
    String? hijriDate,
    String? notes,
    String? stampText,
    bool? isPaid,
    DateTime? createdAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      oldReading: oldReading ?? this.oldReading,
      newReading: newReading ?? this.newReading,
      consumption: consumption ?? this.consumption,
      kwhPrice: kwhPrice ?? this.kwhPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      hijriDate: hijriDate ?? this.hijriDate,
      notes: notes ?? this.notes,
      stampText: stampText ?? this.stampText,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// حساب الاستهلاك تلقائياً
  static double calculateConsumption(double oldReading, double newReading) {
    return newReading - oldReading;
  }

  /// حساب المبلغ الإجمالي
  static double calculateTotal(double consumption, double kwhPrice) {
    return consumption * kwhPrice;
  }

  /// التحقق من صحة القراءات
  static bool isValidReadings(double oldReading, double newReading) {
    return newReading >= oldReading && oldReading >= 0;
  }

  /// إنشاء رقم فاتورة جديد
  static String generateInvoiceNumber(int lastNumber) {
    return (lastNumber + 1).toString().padLeft(3, '0');
  }

  /// تنسيق المبلغ بالدولار
  String get formattedTotal => '\$${totalAmount.toStringAsFixed(2)}';

  /// تنسيق سعر الكيلوواط
  String get formattedKwhPrice => '\$${kwhPrice.toStringAsFixed(4)}';

  @override
  String toString() {
    return 'Invoice(id: $id, invoiceNumber: $invoiceNumber, customerName: $customerName, total: $formattedTotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Invoice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
