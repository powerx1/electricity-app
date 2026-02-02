/// نموذج العميل - Customer Model
class Customer {
  final int? id;
  final String fullName;
  final String phoneNumber;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    this.address,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// تحويل العميل إلى Map لحفظه في قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// إنشاء عميل من Map (من قاعدة البيانات)
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      fullName: map['fullName'] as String,
      phoneNumber: map['phoneNumber'] as String,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// نسخ العميل مع تعديلات
  Customer copyWith({
    int? id,
    String? fullName,
    String? phoneNumber,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// التحقق من صحة رقم الهاتف
  static bool isValidPhoneNumber(String phone) {
    // يقبل أرقام الهاتف بصيغ مختلفة
    final phoneRegex = RegExp(
      r'^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$',
    );
    return phoneRegex.hasMatch(phone.replaceAll(' ', ''));
  }

  /// تنسيق رقم الهاتف للواتساب
  String get whatsAppNumber {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+')) {
      // افتراض أنه رقم محلي - يمكن تعديل كود الدولة حسب الحاجة
      cleaned = '+$cleaned';
    }
    return cleaned;
  }

  @override
  String toString() {
    return 'Customer(id: $id, fullName: $fullName, phoneNumber: $phoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
