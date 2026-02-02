import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/models.dart';

/// خدمة الطباعة - Printing Service
/// تدعم الطباعة على طابعات Xprinter الحرارية عبر Bluetooth
class PrintingService {
  static final PrintingService _instance = PrintingService._internal();
  factory PrintingService() => _instance;
  PrintingService._internal();

  BluetoothInfo? _connectedDevice;
  bool _isConnected = false;

  /// التحقق من حالة الاتصال
  bool get isConnected => _isConnected;
  BluetoothInfo? get connectedDevice => _connectedDevice;

  /// طلب أذونات Bluetooth
  Future<bool> requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final bluetoothScan = await Permission.bluetoothScan.request();
      final bluetoothConnect = await Permission.bluetoothConnect.request();
      final location = await Permission.location.request();

      return bluetoothScan.isGranted &&
          bluetoothConnect.isGranted &&
          location.isGranted;
    }
    return true;
  }

  /// الحصول على قائمة الطابعات المتاحة
  Future<List<BluetoothInfo>> getAvailablePrinters() async {
    final hasPermission = await requestBluetoothPermissions();
    if (!hasPermission) {
      throw Exception('لم يتم منح أذونات Bluetooth');
    }

    final isBluetoothEnabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!isBluetoothEnabled) {
      throw Exception('يرجى تفعيل Bluetooth');
    }

    // الحصول على الأجهزة المقترنة
    final devices = await PrintBluetoothThermal.pairedBluetooths;
    return devices;
  }

  /// الاتصال بالطابعة
  Future<bool> connectToPrinter(BluetoothInfo printer) async {
    try {
      final result = await PrintBluetoothThermal.connect(
        macPrinterAddress: printer.macAdress,
      );

      _isConnected = result;
      if (result) {
        _connectedDevice = printer;
      }
      return result;
    } catch (e) {
      _isConnected = false;
      _connectedDevice = null;
      rethrow;
    }
  }

  /// قطع الاتصال
  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
    _isConnected = false;
    _connectedDevice = null;
  }

  /// طباعة فاتورة على الطابعة الحرارية باستخدام print_bluetooth_thermal
  Future<bool> printInvoiceThermal(
    Invoice invoice, {
    AppSettings? settings,
  }) async {
    if (!_isConnected) {
      throw Exception('الطابعة غير متصلة');
    }

    try {
      // استخدام الطباعة النصية البسيطة
      List<int> bytes = [];

      // ESC/POS commands for Arabic text alignment (right to left)
      // Initialize printer
      bytes += [0x1B, 0x40]; // ESC @

      // Set Arabic code page (may vary by printer model)
      bytes += [0x1B, 0x74, 0x35]; // ESC t 53 (Arabic)

      // Center alignment
      bytes += [0x1B, 0x61, 0x01]; // ESC a 1

      // Bold on, double height
      bytes += [0x1B, 0x45, 0x01]; // Bold ON
      bytes += [0x1D, 0x21, 0x11]; // Double height and width

      // Company name
      String companyName = settings?.companyName ?? 'خدمات فوترة الكهرباء';
      bytes += _encodeArabicText(companyName);
      bytes += [0x0A]; // Line feed

      // Reset size
      bytes += [0x1D, 0x21, 0x00]; // Normal size
      bytes += [0x1B, 0x45, 0x00]; // Bold OFF
      bytes += [0x0A]; // Line feed

      // Invoice number and date
      bytes += _encodeArabicText('فاتورة رقم: ${invoice.invoiceNumber}');
      bytes += [0x0A];
      bytes += _encodeArabicText(
        'التاريخ: ${_formatDate(invoice.invoiceDate)}',
      );
      bytes += [0x0A];

      if (invoice.hijriDate != null) {
        bytes += _encodeArabicText('التاريخ الهجري: ${invoice.hijriDate}');
        bytes += [0x0A];
      }

      // Divider
      bytes += _printDivider();

      // Customer info - left align
      bytes += [0x1B, 0x61, 0x02]; // Right alignment for Arabic
      bytes += [0x1B, 0x45, 0x01]; // Bold ON
      bytes += _encodeArabicText('معلومات العميل:');
      bytes += [0x0A];
      bytes += [0x1B, 0x45, 0x00]; // Bold OFF

      bytes += _encodeArabicText('الاسم: ${invoice.customerName}');
      bytes += [0x0A];
      bytes += _encodeArabicText('الهاتف: ${invoice.customerPhone}');
      bytes += [0x0A];

      if (invoice.customerAddress != null &&
          invoice.customerAddress!.isNotEmpty) {
        bytes += _encodeArabicText('العنوان: ${invoice.customerAddress}');
        bytes += [0x0A];
      }

      // Divider
      bytes += _printDivider();

      // Reading details
      bytes += [0x1B, 0x45, 0x01]; // Bold ON
      bytes += _encodeArabicText('تفاصيل القراءات:');
      bytes += [0x0A];
      bytes += [0x1B, 0x45, 0x00]; // Bold OFF

      bytes += _encodeArabicText(
        'القراءة السابقة: ${invoice.oldReading.toStringAsFixed(0)} kWh',
      );
      bytes += [0x0A];
      bytes += _encodeArabicText(
        'القراءة الحالية: ${invoice.newReading.toStringAsFixed(0)} kWh',
      );
      bytes += [0x0A];
      bytes += [0x1B, 0x45, 0x01]; // Bold ON
      bytes += _encodeArabicText(
        'الاستهلاك: ${invoice.consumption.toStringAsFixed(0)} kWh',
      );
      bytes += [0x0A];
      bytes += [0x1B, 0x45, 0x00]; // Bold OFF

      // Divider
      bytes += _printDivider();

      // Price per kWh
      bytes += _encodeArabicText(
        'سعر الكيلوواط: \$${invoice.kwhPrice.toStringAsFixed(4)}',
      );
      bytes += [0x0A];

      // Double divider
      bytes += _printDivider(char: '=');

      // Total amount - center, bold, large
      bytes += [0x1B, 0x61, 0x01]; // Center
      bytes += [0x1B, 0x45, 0x01]; // Bold ON
      bytes += _encodeArabicText('المبلغ الإجمالي');
      bytes += [0x0A];
      bytes += [0x1D, 0x21, 0x11]; // Double height and width
      bytes += _encodeArabicText(
        '\$${invoice.totalAmount.toStringAsFixed(2)} USD',
      );
      bytes += [0x0A];
      bytes += [0x1D, 0x21, 0x00]; // Normal size
      bytes += [0x1B, 0x45, 0x00]; // Bold OFF

      // Double divider
      bytes += _printDivider(char: '=');

      // Notes
      if (invoice.notes != null && invoice.notes!.isNotEmpty) {
        bytes += [0x1B, 0x61, 0x02]; // Right alignment
        bytes += _encodeArabicText('ملاحظات: ${invoice.notes}');
        bytes += [0x0A];
      }

      // Stamp
      bytes += [0x1B, 0x61, 0x01]; // Center
      bytes += [0x1B, 0x45, 0x01]; // Bold ON
      bytes += _encodeArabicText(invoice.stampText);
      bytes += [0x0A, 0x0A, 0x0A]; // Feed 3 lines

      // Cut paper
      bytes += [0x1D, 0x56, 0x00]; // Full cut

      // إرسال البيانات للطابعة
      final result = await PrintBluetoothThermal.writeBytes(
        Uint8List.fromList(bytes),
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// تحويل النص العربي إلى bytes
  List<int> _encodeArabicText(String text) {
    // Most thermal printers support UTF-8 for Arabic
    return text.codeUnits;
  }

  /// طباعة خط فاصل
  List<int> _printDivider({String char = '-'}) {
    String divider = char * 32; // 32 characters for 58mm paper
    return [...divider.codeUnits, 0x0A];
  }

  /// طباعة PDF عبر نظام الطباعة العادي
  Future<void> printPdf(Uint8List pdfBytes, {String? jobName}) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: jobName ?? 'فاتورة كهرباء',
    );
  }

  /// معاينة الطباعة
  Future<void> showPrintPreview(
    BuildContext context,
    Uint8List pdfBytes,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('معاينة الطباعة'),
            actions: [
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () => printPdf(pdfBytes),
              ),
            ],
          ),
          body: PdfPreview(
            build: (format) => pdfBytes,
            allowPrinting: true,
            allowSharing: true,
            canChangePageFormat: false,
          ),
        ),
      ),
    );
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// حوار اختيار الطابعة
class PrinterSelectionDialog extends StatefulWidget {
  const PrinterSelectionDialog({super.key});

  @override
  State<PrinterSelectionDialog> createState() => _PrinterSelectionDialogState();
}

class _PrinterSelectionDialogState extends State<PrinterSelectionDialog> {
  final PrintingService _printingService = PrintingService();
  List<BluetoothInfo> _printers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final printers = await _printingService.getAvailablePrinters();
      setState(() {
        _printers = printers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('اختر الطابعة'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error, color: Colors.red[400], size: 48),
                  const SizedBox(height: 16),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPrinters,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              )
            : _printers.isEmpty
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print_disabled, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لم يتم العثور على طابعات\nتأكد من تشغيل الطابعة واقترانها بالجهاز',
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _printers.length,
                itemBuilder: (context, index) {
                  final printer = _printers[index];
                  return ListTile(
                    leading: const Icon(Icons.print),
                    title: Text(printer.name),
                    subtitle: Text(printer.macAdress),
                    onTap: () => Navigator.of(context).pop(printer),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }
}
